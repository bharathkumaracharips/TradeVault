# Threat Model & Critical Invariants

## 1. Threat Vectors and Mitigations

| Threat Vector | Attack Scenario | Protocol Mitigation |
|---|---|---|
| **Premature Payment Release** | Seller requests payout before goods are shipped or inspected | Strict dependency ordering in `MilestoneManager.sol`. Payout is locked until verified attestations pass challenge windows. |
| **Attestation Replay** | Carrier or seller re-uses an old Bill of Lading from another shipment | EIP-712 structured data binds `tradeId`, `milestoneIndex`, and chain ID; replay across agreements or chains is rejected. |
| **Unilateral Term Manipulation** | Buyer or seller edits milestone percentages after agreement is funded | Agreement terms are immutable once mutually accepted and funded. Amendments require dual cryptographic signatures. |
| **Escrow Insolvency / Reentrancy** | Malicious ERC-20 token or reentrant call drains escrow pool | Segregated balance accounting per `tradeId`. OpenZeppelin `ReentrancyGuard` on all deposit, release, and refund functions. |
| **Inspection Collusion** | Fraudulent inspection agency approves sub-standard cargo | `AttestationIssuerRegistry.sol` whitelists accredited agencies. Challenge periods allow buyer to submit counter-evidence and lock funds in dispute. |
| **Arbitrator Corruption** | Arbitrator attempts to divert escrowed stablecoins to an external address | Arbitrator can only direct payouts to designated `buyer` (refund) or `seller` (release); funds can never be routed to arbitrator. |

---

## 2. Protocol Invariants
1. `INV-1`: The sum of all milestone percentage allocations for a trade agreement must equal exactly 100% (10,000 basis points).
2. `INV-2`: Total escrow payouts + refunds can never exceed the net funded balance of the trade agreement.
3. `INV-3`: No payment release can occur while a milestone is in active dispute or within an open challenge window.
4. `INV-4`: Attestation issuers must be active and approved in `AttestationIssuerRegistry.sol` at the time of attestation verification.
5. `INV-5`: Disputed funds are locked until an authorized arbitrator records a binding decision.
