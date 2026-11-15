# TradeEscrow: Milestone-Based Trade Finance Escrow DApp

![Solidity](https://img.shields.io/badge/Solidity-0.8.24-363636?style=for-the-badge&logo=solidity)
![Foundry](https://img.shields.io/badge/Foundry-Framework-orange?style=for-the-badge)
![Rust](https://img.shields.io/badge/Rust-Axum%20Backend-black?style=for-the-badge&logo=rust)
![EAS](https://img.shields.io/badge/Attestations-EAS%20%7C%20EIP--712-amber?style=for-the-badge)
![Next.js](https://img.shields.io/badge/Next.js-14%20App%20Router-black?style=for-the-badge&logo=next.js)

A production-grade, milestone-based trade finance escrow platform facilitating international commerce through **cryptographic attestations (EAS / EIP-712)**, **verifiable bills of lading**, **independent inspection certificates**, and **conditional stablecoin payouts**.

---

## 1. System Overview & Architecture

```
                                +-----------------------------------------------+
                                |        SMART CONTRACT ESCROW ECOSYSTEM        |
                                |  ParticipantRegistry  |  TradeAgreementMgr    |
                                |  TradeEscrowVault     |  MilestoneManager     |
                                |  TradeDocumentRegistry|  TradeDisputeManager  |
                                +-----------------------------------------------+
                                           ^                             ^
                                           | Milestone Progress          | Stablecoin Payouts
                                           | & Verified Attestations     | & Partial Refunds
                 +-------------------------+                             +-----------------------+
                 |                                                                               |
       +---------v---------+                                                           +---------v---------+
       |   RUST BACKEND    |                                                           | SELLER / EXPORTER |
       |  EAS Indexer & API|                                                           | (Receives Payouts)|
       +---------+---------+                                                           +-------------------+
                 ^                                                                               ^
                 | Signed Trade Attestations                                                     | Mutual Agreement
                 | (Bill of Lading, SGS Inspection, PoD)                                         | & Milestones
       +---------+---------+                                                           +---------+---------+
       | CARRIER & SGS     |                                                           | BUYER / IMPORTER  |
       |  (Trusted Issuer) |                                                           | (Funds Escrow)    |
       +-------------------+                                                           +-------------------+
```

---

## 2. Directory Structure

```
trade-finance-escrow/
├── contracts/                  # Foundry Solidity smart contracts
│   ├── src/
│   │   ├── interfaces/         # Standard interfaces & custom errors
│   │   ├── ParticipantRegistry.sol      # Buyer, Seller, Carrier, Inspector, Arbitrator
│   │   ├── TradeAgreementManager.sol    # Trade agreements & milestone terms
│   │   ├── TradeEscrowVault.sol         # Segregated stablecoin escrow
│   │   ├── TradeDocumentRegistry.sol    # Document commitments & IPFS CIDs
│   │   ├── AttestationIssuerRegistry.sol# Whitelist of approved attestation issuers
│   │   ├── MilestoneManager.sol         # Challenge periods & completion tracking
│   │   └── TradeDisputeManager.sol      # Commercial dispute arbitration & split payouts
│   ├── test/TradeFinanceLifecycle.t.sol # Unit & milestone lifecycle test suites
│   ├── script/Deploy.s.sol              # Automated deployment script
│   └── foundry.toml
├── backend/                    # Rust backend workspace (Axum + Tokio)
│   ├── Cargo.toml
│   └── crates/
│       ├── core-trade/         # Trade models, milestone allocations, EAS digests
│       └── server/             # REST API for agreements, escrow, attestations
├── packages/sdk-ts/            # TypeScript SDK (@tradefinance/sdk)
├── frontend/                   # Next.js 14 App Router interactive UI
└── specs/                      # Architecture, domain model, and threat models
    ├── architecture.md         # End-to-end data flow & participants
    ├── domain-model.md         # Document standards, IncoTerms, milestone payouts
    └── threat-model.md         # Security invariants, anti-replay, dispute locking
```

---

## 3. Core Milestone Payout Engine

| Milestone | Allocation % | Triggering Evidence | Required Attestation Authority |
|---|---|---|---|
| **M1: Vessel Departure** | 30% | Bill of Lading (BoL) | Approved Maritime Carrier (e.g. Maersk) |
| **M2: Quality & Customs** | 30% | Inspection Certificate (Conformity) | Accredited Inspection Agency (e.g. SGS) |
| **M3: Final Delivery** | 40% | Proof of Delivery (PoD) | Port Authority / Consignee Receipt |
| **Total** | **100%** | Full Reconciled Settlement | Completed |

---

## 4. Quickstart Guide

### 4.1 Smart Contracts (Foundry)
```bash
cd contracts
forge test
forge script script/Deploy.s.sol --broadcast
```

### 4.2 Rust Backend API
```bash
cd backend
cargo run -p server
# API running at http://localhost:8083
```

### 4.3 Next.js Frontend
```bash
cd frontend
npm install
npm run dev
# Open http://localhost:3000 to launch the TradeEscrow DApp
```

---

## 5. Critical Invariants
- `INV-1`: Milestone allocations must total exactly 10,000 basis points (100%).
- `INV-2`: Total escrow payouts + refunds can never exceed the net funded balance of the agreement.
- `INV-3`: No payment release can execute during an active challenge window or open dispute.
- `INV-4`: Only authorized attestation issuers can complete milestones.
