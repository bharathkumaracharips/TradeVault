# System Architecture: TradeVault
**Platform:** EVM Blockchain + Milestone-Based Escrow Vault + EAS / EIP-712 Attestation Engine  
**Standard Payment Asset:** ERC-20 Stablecoins (USDC / USDT)  

---

## 1. System Overview & Core Participants

```
       +-------------------------------------------------------------------------+
       |                     SMART CONTRACT ESCROW ECOSYSTEM                     |
       |  ParticipantRegistry   |  TradeAgreementManager |  TradeEscrowVault     |
       |  AttestationIssuerReg  |  TradeAttestationVerif |  MilestoneManager     |
       |  PaymentReleaseManager |  TradeDisputeManager   |  TradeRefundManager   |
       +-------------------------------------------------------------------------+
             ^                       ^                     ^                 ^
             | 1. Accepts Terms      | 2. Deposits Funds   | 4. Attestations | 5. Milestones
             |                       |                     |    & Evidence   |    & Payouts
       +-----+-------+         +-----+------+        +-----+-------+   +-----+------+
       |   SELLER    |         |   BUYER    |        | CARRIER &   |   | ARBITRATOR |
       | (Exporter)  |         | (Importer) |        | INSPECTION  |   | (Disputes) |
       +-------------+         +------------+        +-------------+   +------------+
```

---

## 2. Milestone-Based Trade Lifecycle

```
    [Agreement Created]
             │
             ▼
    [Mutual Acceptance] ──> Buyer & Seller sign terms & milestone percentages
             │
             ▼
    [Escrow Funded]     ──> Buyer deposits 100% of agreed stablecoin funds into TradeEscrowVault
             │
             ▼
    [Milestone 1: Shipping] (e.g. 30% payout)
             │   - Carrier issues signed Bill of Lading attestation (EAS / EIP-712)
             │   - Attestation validated -> Challenge window passes -> 30% released to Seller
             ▼
    [Milestone 2: Inspection] (e.g. 30% payout)
             │   - Independent Inspection Agency verifies quantity & quality certificate
             │   - Inspection attestation passes -> 30% released to Seller
             ▼
    [Milestone 3: Delivery Confirmation] (e.g. 40% payout)
             │   - Proof-of-delivery signed by Buyer / Consignee
             │   - Final 40% released to Seller -> Trade Agreement Completed
             ▼
    [Dispute / Default Branch]
                 - If goods damaged or inspection fails, affected milestone is locked.
                 - DisputeArbitrator reviews evidence & executes partial refund / penalty.
```

---

## 3. Financial & Cryptographic Trust Boundaries
- **Escrow Segregation:** Each trade agreement maintains its own isolated escrow balance in `TradeEscrowVault.sol`. Reentrancy guards and ERC-20 balance accounting protect against insolvency.
- **Attestation Authenticity:** Shipping, inspection, and delivery attestations are signed via EIP-712 typed structured data or Ethereum Attestation Service (EAS) schemas, strictly bound to the `tradeId` and `milestoneId`.
- **Challenge Windows:** Milestones have configurable challenge periods (e.g. 24–48 hours) allowing parties to dispute fraudulent attestations before automated payment execution.
