// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IParticipantRegistry {
    enum ParticipantRole {
        None,
        Buyer,
        Seller,
        Carrier,
        InspectionAgency,
        DeliveryAuthority,
        Arbitrator
    }

    struct ParticipantProfile {
        address walletAddress;
        string legalName;
        string jurisdiction;
        ParticipantRole role;
        bool approved;
        uint64 registeredAt;
    }

    event ParticipantRegistered(address indexed wallet, string legalName, ParticipantRole role);
    event ParticipantApprovalUpdated(address indexed wallet, bool approved);

    error ParticipantAlreadyRegistered(address wallet);
    error ParticipantNotFound(address wallet);
    error ParticipantNotApproved(address wallet);
    error UnauthorizedAdmin(address caller);

    function registerParticipant(string calldata legalName, string calldata jurisdiction, ParticipantRole role) external;
    function setParticipantApproval(address wallet, bool approved) external;
    function getParticipant(address wallet) external view returns (ParticipantProfile memory);
    function isApprovedRole(address wallet, ParticipantRole requiredRole) external view returns (bool);
}

interface ITradeAgreementManager {
    enum AgreementStatus {
        Created,
        AcceptedByBuyer,
        AcceptedBySeller,
        FullyAccepted,
        EscrowFunded,
        InExecution,
        Completed,
        Disputed,
        Cancelled
    }

    struct Milestone {
        string name;
        uint16 allocationBps;       // Basis points (e.g. 3000 = 30%)
        uint32 challengePeriodSec;  // Challenge window before release
        bool completed;
        bool released;
    }

    struct Agreement {
        bytes32 tradeId;
        address buyer;
        address seller;
        address paymentToken;       // ERC-20 token address (e.g. USDC)
        uint256 totalAmount;        // In token base units
        AgreementStatus status;
        uint32 milestoneCount;
        uint64 createdAt;
    }

    event AgreementCreated(bytes32 indexed tradeId, address indexed buyer, address indexed seller, uint256 totalAmount);
    event AgreementAccepted(bytes32 indexed tradeId, address indexed participant);
    event AgreementStatusChanged(bytes32 indexed tradeId, AgreementStatus oldStatus, AgreementStatus newStatus);

    error AgreementAlreadyExists(bytes32 tradeId);
    error AgreementNotFound(bytes32 tradeId);
    error InvalidMilestoneAllocations();
    error UnauthorizedAgreementParty(address caller);
    error InvalidAgreementStatus(AgreementStatus current);

    function createAgreement(
        bytes32 tradeId,
        address seller,
        address paymentToken,
        uint256 totalAmount,
        string[] calldata milestoneNames,
        uint16[] calldata allocationBps,
        uint32[] calldata challengePeriods
    ) external;

    function acceptAgreement(bytes32 tradeId) external;
    function updateStatus(bytes32 tradeId, AgreementStatus newStatus) external;
    function getAgreement(bytes32 tradeId) external view returns (Agreement memory);
    function getMilestone(bytes32 tradeId, uint256 index) external view returns (Milestone memory);
}
