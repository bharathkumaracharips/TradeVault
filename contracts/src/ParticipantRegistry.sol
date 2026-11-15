// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IParticipantRegistry} from "./interfaces/IParticipantRegistry.sol";

contract ParticipantRegistry is IParticipantRegistry {
    address public admin;

    mapping(address => ParticipantProfile) private _participants;

    modifier onlyAdmin() {
        if (msg.sender != admin) revert UnauthorizedAdmin(msg.sender);
        _;
    }

    constructor(address initialAdmin) {
        admin = initialAdmin == address(0) ? msg.sender : initialAdmin;
    }

    function registerParticipant(
        string calldata legalName,
        string calldata jurisdiction,
        ParticipantRole role
    ) external override {
        if (_participants[msg.sender].registeredAt != 0) revert ParticipantAlreadyRegistered(msg.sender);
        require(role != ParticipantRole.None, "Invalid role");

        _participants[msg.sender] = ParticipantProfile({
            walletAddress: msg.sender,
            legalName: legalName,
            jurisdiction: jurisdiction,
            role: role,
            approved: false, // Requires admin approval
            registeredAt: uint64(block.timestamp)
        });

        emit ParticipantRegistered(msg.sender, legalName, role);
    }

    function setParticipantApproval(address wallet, bool approved) external override onlyAdmin {
        if (_participants[wallet].registeredAt == 0) revert ParticipantNotFound(wallet);
        _participants[wallet].approved = approved;

        emit ParticipantApprovalUpdated(wallet, approved);
    }

    function getParticipant(address wallet) external view override returns (ParticipantProfile memory) {
        ParticipantProfile memory p = _participants[wallet];
        if (p.registeredAt == 0) revert ParticipantNotFound(wallet);
        return p;
    }

    function isApprovedRole(address wallet, ParticipantRole requiredRole) external view override returns (bool) {
        ParticipantProfile memory p = _participants[wallet];
        if (!p.approved) return false;
        return p.role == requiredRole;
    }
}
