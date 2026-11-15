// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITradeEscrowVault {
    event EscrowFunded(bytes32 indexed tradeId, address indexed token, uint256 amount);
    event MilestonePayoutReleased(bytes32 indexed tradeId, uint256 indexed milestoneIndex, address indexed recipient, uint256 amount);
    event RefundExecuted(bytes32 indexed tradeId, address indexed recipient, uint256 amount);

    error EscrowAlreadyFunded(bytes32 tradeId);
    error EscrowNotFunded(bytes32 tradeId);
    error InsufficientEscrowBalance(bytes32 tradeId, uint256 requested, uint256 available);
    error UnauthorizedEscrowCaller(address caller);

    function fundEscrowNative(bytes32 tradeId) external payable;
    function releaseMilestonePayment(bytes32 tradeId, uint256 milestoneIndex, address recipient, uint256 amount) external;
    function executeRefund(bytes32 tradeId, address recipient, uint256 amount) external;
    function getEscrowBalance(bytes32 tradeId) external view returns (uint256);
}

interface ITradeDocumentRegistry {
    enum DocumentType { CommercialInvoice, BillOfLading, InspectionCertificate, ProofOfDelivery, CustomsDeclaration }

    struct DocumentRecord {
        bytes32 docHash;           // keccak256 hash of encrypted document
        string ipfsCID;            // IPFS storage URI
        DocumentType docType;
        address uploadedBy;
        uint64 uploadedAt;
    }

    event DocumentCommitted(bytes32 indexed tradeId, bytes32 indexed docHash, DocumentType docType, string ipfsCID);

    function commitDocument(bytes32 tradeId, bytes32 docHash, DocumentType docType, string calldata ipfsCID) external;
    function getDocument(bytes32 tradeId, bytes32 docHash) external view returns (DocumentRecord memory);
}

interface IAttestationIssuerRegistry {
    enum IssuerType { Carrier, InspectionAgency, DeliveryAuthority }

    struct AttestationIssuer {
        address issuerAddress;
        string organizationName;
        IssuerType issuerType;
        bool approved;
        uint64 registeredAt;
    }

    event IssuerRegistered(address indexed issuer, string name, IssuerType issuerType);
    event IssuerApprovalChanged(address indexed issuer, bool approved);

    function registerIssuer(string calldata name, IssuerType issuerType) external;
    function setIssuerApproval(address issuer, bool approved) external;
    function isApprovedIssuer(address issuer, IssuerType issuerType) external view returns (bool);
}

interface IMilestoneManager {
    event MilestoneCompleted(bytes32 indexed tradeId, uint256 indexed milestoneIndex, uint256 releaseTime);
    event MilestoneApproved(bytes32 indexed tradeId, uint256 indexed milestoneIndex);
    event MilestoneChallenged(bytes32 indexed tradeId, uint256 indexed milestoneIndex, string reason);

    function completeMilestone(bytes32 tradeId, uint256 milestoneIndex, bytes32 attestationHash) external;
    function challengeMilestone(bytes32 tradeId, uint256 milestoneIndex, string calldata reason) external;
    function approveMilestonePayout(bytes32 tradeId, uint256 milestoneIndex) external;
    function isMilestoneReadyForRelease(bytes32 tradeId, uint256 milestoneIndex) external view returns (bool);
}

interface ITradeDisputeManager {
    enum DisputeStatus { None, Open, InReview, Resolved, Cancelled }

    struct Dispute {
        bytes32 tradeId;
        uint256 disputedMilestone;
        address initiator;
        string evidenceCID;
        DisputeStatus status;
        address assignedArbitrator;
        uint256 refundBpsToBuyer;
        uint256 releaseBpsToSeller;
    }

    event DisputeOpened(bytes32 indexed tradeId, uint256 milestoneIndex, address indexed initiator);
    event DisputeResolved(bytes32 indexed tradeId, uint256 refundBuyerBps, uint256 releaseSellerBps);

    function openDispute(bytes32 tradeId, uint256 milestoneIndex, string calldata evidenceCID) external;
    function resolveDispute(bytes32 tradeId, uint256 refundBuyerBps, uint256 releaseSellerBps) external;
    function getDispute(bytes32 tradeId) external view returns (Dispute memory);
}
