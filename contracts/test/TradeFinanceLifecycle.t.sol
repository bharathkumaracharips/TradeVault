// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ParticipantRegistry} from "../src/ParticipantRegistry.sol";
import {TradeAgreementManager} from "../src/TradeAgreementManager.sol";
import {TradeEscrowVault} from "../src/TradeEscrowVault.sol";
import {TradeDocumentRegistry} from "../src/TradeDocumentRegistry.sol";
import {AttestationIssuerRegistry} from "../src/AttestationIssuerRegistry.sol";
import {MilestoneManager} from "../src/MilestoneManager.sol";
import {TradeDisputeManager} from "../src/TradeDisputeManager.sol";
import {ITradeAgreementManager} from "../src/interfaces/IParticipantRegistry.sol";

contract Actor {
    function accept(TradeAgreementManager mgr, bytes32 tradeId) external {
        mgr.acceptAgreement(tradeId);
    }
    receive() external payable {}
}

contract TradeFinanceLifecycleTest {
    ParticipantRegistry private participantReg;
    TradeAgreementManager private agreementMgr;
    TradeEscrowVault private escrowVault;
    TradeDocumentRegistry private docReg;
    AttestationIssuerRegistry private issuerReg;
    MilestoneManager private milestoneMgr;
    TradeDisputeManager private disputeMgr;

    Actor private seller;
    bytes32 private tradeId = keccak256("TRADE_TEST_101");

    function setUp() public {
        participantReg = new ParticipantRegistry(address(this));
        agreementMgr = new TradeAgreementManager(address(this));
        escrowVault = new TradeEscrowVault(address(0), address(0));
        docReg = new TradeDocumentRegistry();
        issuerReg = new AttestationIssuerRegistry(address(this));

        milestoneMgr = new MilestoneManager(address(agreementMgr), address(escrowVault));
        disputeMgr = new TradeDisputeManager(address(agreementMgr), address(escrowVault), address(this));
        escrowVault.setManagers(address(milestoneMgr), address(disputeMgr));

        seller = new Actor();
    }

    function testCompleteMilestoneFlow() public {
        string[] memory names = new string[](3);
        names[0] = "Shipping";
        names[1] = "Inspection";
        names[2] = "Delivery";

        uint16[] memory allocs = new uint16[](3);
        allocs[0] = 3000; // 30%
        allocs[1] = 3000; // 30%
        allocs[2] = 4000; // 40%

        uint32[] memory periods = new uint32[](3);
        periods[0] = 0; // immediate in test
        periods[1] = 0;
        periods[2] = 0;

        // 1. Create Agreement (buyer = address(this))
        agreementMgr.createAgreement(
            tradeId,
            address(seller),
            address(0),
            10 ether,
            names,
            allocs,
            periods
        );

        // 2. Seller accepts
        seller.accept(agreementMgr, tradeId);
        ITradeAgreementManager.Agreement memory a = agreementMgr.getAgreement(tradeId);
        require(a.status == ITradeAgreementManager.AgreementStatus.FullyAccepted, "Must be fully accepted");

        // 3. Fund Escrow (10 ether)
        escrowVault.fundEscrowNative{value: 10 ether}(tradeId);
        require(escrowVault.getEscrowBalance(tradeId) == 10 ether, "Escrow balance must be 10 ether");

        // 4. Milestone 1: Shipping attestation completed & payout approved (30% = 3 ether)
        milestoneMgr.completeMilestone(tradeId, 0, keccak256("BillOfLading"));
        milestoneMgr.approveMilestonePayout(tradeId, 0);

        require(escrowVault.getEscrowBalance(tradeId) == 7 ether, "Remaining escrow must be 7 ether");
        require(address(seller).balance == 3 ether, "Seller must have received 3 ether");
    }

    receive() external payable {}
}
