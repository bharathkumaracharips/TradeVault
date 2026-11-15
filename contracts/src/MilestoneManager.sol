// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IMilestoneManager} from "./interfaces/ITradeEscrowVault.sol";
import {ITradeAgreementManager} from "./interfaces/IParticipantRegistry.sol";
import {ITradeEscrowVault} from "./interfaces/ITradeEscrowVault.sol";

contract MilestoneManager is IMilestoneManager {
    ITradeAgreementManager public immutable agreementManager;
    ITradeEscrowVault public immutable escrowVault;

    struct MilestoneProgress {
        bool completed;
        uint64 completionTime;
        bool challenged;
        bool approvedForRelease;
    }

    // tradeId => milestoneIndex => MilestoneProgress
    mapping(bytes32 => mapping(uint256 => MilestoneProgress)) private _progress;

    constructor(address agreementManagerAddress, address escrowVaultAddress) {
        require(agreementManagerAddress != address(0) && escrowVaultAddress != address(0), "Zero address");
        agreementManager = ITradeAgreementManager(agreementManagerAddress);
        escrowVault = ITradeEscrowVault(escrowVaultAddress);
    }

    function completeMilestone(
        bytes32 tradeId,
        uint256 milestoneIndex,
        bytes32 attestationHash
    ) external override {
        require(attestationHash != bytes32(0), "Empty attestation");

        MilestoneProgress storage p = _progress[tradeId][milestoneIndex];
        require(!p.completed, "Already completed");

        p.completed = true;
        p.completionTime = uint64(block.timestamp);

        emit MilestoneCompleted(tradeId, milestoneIndex, block.timestamp);
    }

    function challengeMilestone(
        bytes32 tradeId,
        uint256 milestoneIndex,
        string calldata reason
    ) external override {
        MilestoneProgress storage p = _progress[tradeId][milestoneIndex];
        require(p.completed, "Not completed");
        require(!p.approvedForRelease, "Already approved");

        p.challenged = true;
        emit MilestoneChallenged(tradeId, milestoneIndex, reason);
    }

    function approveMilestonePayout(
        bytes32 tradeId,
        uint256 milestoneIndex
    ) external override {
        MilestoneProgress storage p = _progress[tradeId][milestoneIndex];
        require(p.completed, "Not completed");
        require(!p.challenged, "Milestone is challenged");
        require(!p.approvedForRelease, "Already released");

        ITradeAgreementManager.Milestone memory m = agreementManager.getMilestone(tradeId, milestoneIndex);
        uint256 readyAt = p.completionTime + m.challengePeriodSec;
        require(block.timestamp >= readyAt, "Challenge period pending");

        p.approvedForRelease = true;

        ITradeAgreementManager.Agreement memory a = agreementManager.getAgreement(tradeId);
        uint256 payoutAmount = (a.totalAmount * m.allocationBps) / 10000;

        escrowVault.releaseMilestonePayment(tradeId, milestoneIndex, a.seller, payoutAmount);

        emit MilestoneApproved(tradeId, milestoneIndex);
    }

    function isMilestoneReadyForRelease(bytes32 tradeId, uint256 milestoneIndex) external view override returns (bool) {
        MilestoneProgress memory p = _progress[tradeId][milestoneIndex];
        if (!p.completed || p.challenged || p.approvedForRelease) return false;

        ITradeAgreementManager.Milestone memory m = agreementManager.getMilestone(tradeId, milestoneIndex);
        return block.timestamp >= (p.completionTime + m.challengePeriodSec);
    }
}
