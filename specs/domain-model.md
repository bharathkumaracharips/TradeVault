# Trade Finance Domain Model & Document Standards

## 1. Trade Agreement Data Structure
- `tradeId`: Unique 32-byte identifier (`keccak256(buyer, seller, nonce, timestamp)`).
- `buyer`: Address of importing enterprise.
- `seller`: Address of exporting enterprise.
- `token`: ERC-20 payment asset address (e.g. USDC).
- `totalAmount`: Total trade valuation in base units ($6$ decimals for USDC).
- `milestones`: Array of milestone conditions (e.g. Shipping 30%, Inspection 30%, Delivery 40%).
- `status`: `Created`, `Accepted`, `Funded`, `InExecution`, `Completed`, `Disputed`, `Cancelled`.

---

## 2. Trade Documents & Cryptographic Commitments
All physical and electronic trade documents are encrypted client-side using AES-256-GCM, uploaded to IPFS, and their cryptographic hash (`keccak256`) is committed on-chain in `TradeDocumentRegistry.sol`:

1. **Commercial Invoice:**
   - Invoiced amount, payment terms, Incoterms 2020 (FOB, CIF, DDP).
2. **Bill of Lading (BoL):**
   - Carrier name, vessel/flight ID, container numbers, departure port, arrival port.
3. **Certificate of Inspection:**
   - Independent inspection agency (e.g. SGS, Bureau Veritas), sample testing results, conformity rating (Pass/Fail/Conditional).
4. **Proof of Delivery (PoD):**
   - Consignee warehouse receipt, delivery timestamp, package condition notes.

---

## 3. Supported Milestones & Payment Splits

| Milestone | Default Payout % | Trigger Attestation | Required Issuer |
|---|---|---|---|
| **M1: Departure / Shipment** | 30% | EIP-712 Bill of Lading Attestation | Approved Logistics Carrier |
| **M2: Quality & Customs Inspection** | 30% | EIP-712 Inspection Certificate (Pass) | Accredited Inspection Agency |
| **M3: Final Delivery & Acceptance** | 40% | Proof of Delivery Attestation | Buyer / Port Authority |
| **Total** | **100%** | Full Reconciled Escrow | Completed |
