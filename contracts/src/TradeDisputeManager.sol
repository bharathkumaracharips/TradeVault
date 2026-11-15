// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITradeDisputeManager} from "./interfaces/ITradeEscrowVault.sol";
import {ITradeAgreementManager} from "./interfaces/IParticipantRegistry.sol";
import {ITradeEscrowVault} from "./interfaces/ITradeEscrowVault.sol";

contract TradeDisputeManager is ITradeDisputeManager {
    ITradeAgreementManager public immutable agreementManager;
    ITradeEscrowVault public immutable escrowVault;
    address public arbitrator;

    mapping(bytes32 => Dispute) private _disputes;

    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Only arbitrator");
        _;
    }

    constructor(address agreementManagerAddress, address escrowVaultAddress, address initialArbitrator) {
        agreementManager = ITradeAgreementManager(agreementManagerAddress);
        escrowVault = ITradeEscrowVault(escrowVaultAddress);
        arbitrator = initialArbitrator == address(0) ? msg.sender : initialArbitrator;
    }

    function openDispute(
        bytes32 tradeId,
        uint256 milestoneIndex,
        string calldata evidenceCID
    ) external override {
        ITradeAgreementManager.Agreement memory a = agreementManager.getAgreement(tradeId);
        require(msg.sender == a.buyer || msg.sender == a.seller, "Unauthorized party");
        require(_disputes[tradeId].status == DisputeStatus.None, "Dispute already open");

        _disputes[tradeId] = Dispute({
            tradeId: tradeId,
            disputedMilestone: milestoneIndex,
            initiator: msg.sender,
            evidenceCID: evidenceCID,
            status: DisputeStatus.Open,
            assignedArbitrator: arbitrator,
            refundBpsToBuyer: 0,
            releaseBpsToSeller: 0
        });

        agreementManager.updateStatus(tradeId, ITradeAgreementManager.AgreementStatus.Disputed);

        emit DisputeOpened(tradeId, milestoneIndex, msg.sender);
    }

    function resolveDispute(
        bytes32 tradeId,
        uint256 refundBuyerBps,
        uint256 releaseSellerBps
    ) external override onlyArbitrator {
        Dispute storage d = _disputes[tradeId];
        require(d.status == DisputeStatus.Open, "No open dispute");
        require(refundBuyerBps + releaseSellerBps == 10000, "Must total 10000 bps");

        d.status = DisputeStatus.Resolved;
        d.refundBpsToBuyer = refundBuyerBps;
        d.releaseBpsToSeller = releaseSellerBps;

        uint256 balance = escrowVault.getEscrowBalance(tradeId);
        uint256 buyerRefund = (balance * refundBuyerBps) / 10000;
        uint256 sellerRelease = balance - buyerRefund;

        ITradeAgreementManager.Agreement memory a = agreementManager.getAgreement(tradeId);

        if (buyerRefund > 0) {
            escrowVault.executeRefund(tradeId, a.buyer, buyerRefund);
        }
        if (sellerRelease > 0) {
            escrowVault.releaseMilestonePayment(tradeId, 999, a.seller, sellerRelease);
        }

        agreementManager.updateStatus(tradeId, ITradeAgreementManager.AgreementStatus.Completed);

        emit DisputeResolved(tradeId, refundBuyerBps, releaseSellerBps);
    }

    function getDispute(bytes32 tradeId) external view override returns (Dispute memory) {
        return _disputes[tradeId];
    }
}
