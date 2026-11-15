// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITradeAgreementManager} from "./interfaces/IParticipantRegistry.sol";

contract TradeAgreementManager is ITradeAgreementManager {
    address public protocolAdmin;

    mapping(bytes32 => Agreement) private _agreements;
    mapping(bytes32 => mapping(uint256 => Milestone)) private _milestones;
    mapping(bytes32 => mapping(address => bool)) private _hasAccepted;

    modifier onlyAdmin() {
        require(msg.sender == protocolAdmin, "Only admin");
        _;
    }

    constructor(address initialAdmin) {
        protocolAdmin = initialAdmin == address(0) ? msg.sender : initialAdmin;
    }

    function createAgreement(
        bytes32 tradeId,
        address seller,
        address paymentToken,
        uint256 totalAmount,
        string[] calldata milestoneNames,
        uint16[] calldata allocationBps,
        uint32[] calldata challengePeriods
    ) external override {
        if (_agreements[tradeId].createdAt != 0) revert AgreementAlreadyExists(tradeId);
        require(seller != address(0) && seller != msg.sender, "Invalid seller");
        require(totalAmount > 0, "Zero amount");
        require(milestoneNames.length == allocationBps.length && allocationBps.length == challengePeriods.length, "Length mismatch");

        // Validate allocations sum to exactly 10,000 bps (100%)
        uint256 totalBps = 0;
        for (uint256 i = 0; i < allocationBps.length; i++) {
            totalBps += allocationBps[i];
        }
        if (totalBps != 10000) revert InvalidMilestoneAllocations();

        _agreements[tradeId] = Agreement({
            tradeId: tradeId,
            buyer: msg.sender,
            seller: seller,
            paymentToken: paymentToken,
            totalAmount: totalAmount,
            status: AgreementStatus.Created,
            milestoneCount: uint32(milestoneNames.length),
            createdAt: uint64(block.timestamp)
        });

        for (uint256 i = 0; i < milestoneNames.length; i++) {
            _milestones[tradeId][i] = Milestone({
                name: milestoneNames[i],
                allocationBps: allocationBps[i],
                challengePeriodSec: challengePeriods[i],
                completed: false,
                released: false
            });
        }

        // Creator (Buyer) automatically accepts
        _hasAccepted[tradeId][msg.sender] = true;

        emit AgreementCreated(tradeId, msg.sender, seller, totalAmount);
    }

    function acceptAgreement(bytes32 tradeId) external override {
        Agreement storage a = _agreements[tradeId];
        if (a.createdAt == 0) revert AgreementNotFound(tradeId);
        if (msg.sender != a.buyer && msg.sender != a.seller) revert UnauthorizedAgreementParty(msg.sender);

        _hasAccepted[tradeId][msg.sender] = true;
        emit AgreementAccepted(tradeId, msg.sender);

        if (_hasAccepted[tradeId][a.buyer] && _hasAccepted[tradeId][a.seller]) {
            a.status = AgreementStatus.FullyAccepted;
            emit AgreementStatusChanged(tradeId, AgreementStatus.Created, AgreementStatus.FullyAccepted);
        }
    }

    function updateStatus(bytes32 tradeId, AgreementStatus newStatus) external override {
        Agreement storage a = _agreements[tradeId];
        if (a.createdAt == 0) revert AgreementNotFound(tradeId);

        AgreementStatus old = a.status;
        a.status = newStatus;
        emit AgreementStatusChanged(tradeId, old, newStatus);
    }

    function getAgreement(bytes32 tradeId) external view override returns (Agreement memory) {
        Agreement memory a = _agreements[tradeId];
        if (a.createdAt == 0) revert AgreementNotFound(tradeId);
        return a;
    }

    function getMilestone(bytes32 tradeId, uint256 index) external view override returns (Milestone memory) {
        return _milestones[tradeId][index];
    }
}
