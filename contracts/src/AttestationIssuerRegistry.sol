// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAttestationIssuerRegistry} from "./interfaces/ITradeEscrowVault.sol";

contract AttestationIssuerRegistry is IAttestationIssuerRegistry {
    address public admin;

    mapping(address => AttestationIssuer) private _issuers;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor(address initialAdmin) {
        admin = initialAdmin == address(0) ? msg.sender : initialAdmin;
    }

    function registerIssuer(string calldata name, IssuerType issuerType) external override {
        require(_issuers[msg.sender].registeredAt == 0, "Already registered");

        _issuers[msg.sender] = AttestationIssuer({
            issuerAddress: msg.sender,
            organizationName: name,
            issuerType: issuerType,
            approved: false,
            registeredAt: uint64(block.timestamp)
        });

        emit IssuerRegistered(msg.sender, name, issuerType);
    }

    function setIssuerApproval(address issuer, bool approved) external override onlyAdmin {
        require(_issuers[issuer].registeredAt != 0, "Not found");
        _issuers[issuer].approved = approved;

        emit IssuerApprovalChanged(issuer, approved);
    }

    function isApprovedIssuer(address issuer, IssuerType issuerType) external view override returns (bool) {
        AttestationIssuer memory i = _issuers[issuer];
        return i.approved && i.issuerType == issuerType;
    }
}
