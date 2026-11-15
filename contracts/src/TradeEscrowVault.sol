// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITradeEscrowVault} from "./interfaces/ITradeEscrowVault.sol";

contract TradeEscrowVault is ITradeEscrowVault {
    address public paymentReleaseManager;
    address public disputeManager;

    mapping(bytes32 => uint256) private _escrowBalances;
    mapping(bytes32 => bool) private _isFunded;

    modifier onlyAuthorizedManager() {
        if (msg.sender != paymentReleaseManager && msg.sender != disputeManager) {
            revert UnauthorizedEscrowCaller(msg.sender);
        }
        _;
    }

    constructor(address initialReleaseManager, address initialDisputeManager) {
        paymentReleaseManager = initialReleaseManager == address(0) ? msg.sender : initialReleaseManager;
        disputeManager = initialDisputeManager == address(0) ? msg.sender : initialDisputeManager;
    }

    function setManagers(address releaseMgr, address disputeMgr) external {
        require(msg.sender == paymentReleaseManager || paymentReleaseManager == address(0), "Unauthorized");
        paymentReleaseManager = releaseMgr;
        disputeManager = disputeMgr;
    }

    function fundEscrowNative(bytes32 tradeId) external payable override {
        if (_isFunded[tradeId]) revert EscrowAlreadyFunded(tradeId);
        require(msg.value > 0, "Zero funds");

        _escrowBalances[tradeId] = msg.value;
        _isFunded[tradeId] = true;

        emit EscrowFunded(tradeId, address(0), msg.value);
    }

    function releaseMilestonePayment(
        bytes32 tradeId,
        uint256 milestoneIndex,
        address recipient,
        uint256 amount
    ) external override onlyAuthorizedManager {
        if (!_isFunded[tradeId]) revert EscrowNotFunded(tradeId);
        if (_escrowBalances[tradeId] < amount) {
            revert InsufficientEscrowBalance(tradeId, amount, _escrowBalances[tradeId]);
        }

        _escrowBalances[tradeId] -= amount;

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Payout transfer failed");

        emit MilestonePayoutReleased(tradeId, milestoneIndex, recipient, amount);
    }

    function executeRefund(
        bytes32 tradeId,
        address recipient,
        uint256 amount
    ) external override onlyAuthorizedManager {
        if (!_isFunded[tradeId]) revert EscrowNotFunded(tradeId);
        if (_escrowBalances[tradeId] < amount) {
            revert InsufficientEscrowBalance(tradeId, amount, _escrowBalances[tradeId]);
        }

        _escrowBalances[tradeId] -= amount;

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Refund transfer failed");

        emit RefundExecuted(tradeId, recipient, amount);
    }

    function getEscrowBalance(bytes32 tradeId) external view override returns (uint256) {
        return _escrowBalances[tradeId];
    }
}
