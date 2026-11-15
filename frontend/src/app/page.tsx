"use client";

import React, { useState } from "react";

interface MilestoneState {
  name: string;
  percent: number;
  amount: number;
  trigger: string;
  issuer: string;
  completed: boolean;
  released: boolean;
}

export default function Home() {
  const [activeTab, setActiveTab] = useState<"agreement" | "milestones" | "attestations" | "dispute">("agreement");

  const [tradeId] = useState<string>("0x5a81e9b27c3d4019a8264e1098b7123fa98e0129");
  const [buyerAddress] = useState<string>("0x1111111111111111111111111111111111111111");
  const [sellerAddress] = useState<string>("0x2222222222222222222222222222222222222222");
  const [totalEscrowAmount] = useState<number>(250000); // 250,000 USDC

  const [milestones, setMilestones] = useState<MilestoneState[]>([
    {
      name: "Milestone 1: Shipping & Bill of Lading",
      percent: 30,
      amount: 75000,
      trigger: "EAS Attestation: Verified Bill of Lading (Vessel Departure)",
      issuer: "Maersk Line Maritime Authority",
      completed: true,
      released: true
    },
    {
      name: "Milestone 2: Independent Quality Inspection",
      percent: 30,
      amount: 75000,
      trigger: "EAS Attestation: SGS Conformity Certificate (Grade A)",
      issuer: "SGS Industrial Inspection Bureau",
      completed: true,
      released: false
    },
    {
      name: "Milestone 3: Final Delivery & Consignee Acceptance",
      percent: 40,
      amount: 100000,
      trigger: "EAS Attestation: Proof of Delivery (Consignee Signed)",
      issuer: "Port of Rotterdam Authority",
      completed: false,
      released: false
    }
  ]);

  const totalReleased = milestones.filter(m => m.released).reduce((acc, m) => acc + m.amount, 0);
  const remainingInVault = totalEscrowAmount - totalReleased;

  const handleCompleteMilestone = (index: number) => {
    const updated = [...milestones];
    updated[index].completed = true;
    setMilestones(updated);
    alert(`Milestone ${index + 1} marked completed via verified EAS attestation!`);
  };

  const handleReleasePayment = (index: number) => {
    const updated = [...milestones];
    updated[index].released = true;
    setMilestones(updated);
    alert(`Payment Released: ${updated[index].amount.toLocaleString()} USDC disbursed to Seller (${sellerAddress.slice(0, 10)}...)!`);
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      {/* Header Banner */}
      <div className="mb-8 p-6 rounded-2xl bg-gradient-to-r from-amber-950/40 via-emerald-950/20 to-slate-900 border border-amber-500/20 shadow-xl">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-3xl font-extrabold text-white tracking-tight">Trade Finance Milestone Escrow</h1>
            <p className="text-slate-400 mt-1 text-sm">
              Cross-border commercial escrow with EAS attestations (Bill of Lading, SGS Inspection, Proof of Delivery).
            </p>
          </div>
          <div className="flex items-center gap-2">
            <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              <span className="w-2 h-2 rounded-full bg-emerald-400 mr-2 animate-pulse"></span>
              Escrow Vault Active
            </span>
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="flex flex-wrap gap-2 mb-8 border-b border-slate-800 pb-4">
        {[
          { key: "agreement", label: "Commercial Agreement" },
          { key: "milestones", label: "Payment Milestones & Vault" },
          { key: "attestations", label: "EAS Attestation Registry" },
          { key: "dispute", label: "Arbitration & Dispute Desk" }
        ].map(tab => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key as any)}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
              activeTab === tab.key
                ? "bg-amber-600 text-white shadow-lg shadow-amber-500/20"
                : "bg-slate-900/60 text-slate-400 hover:text-white hover:bg-slate-800 border border-slate-800"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* TAB 1: AGREEMENT */}
      {activeTab === "agreement" && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-1 space-y-6">
            <div className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm">
              <h2 className="text-lg font-bold text-white mb-4">Agreement Overview</h2>
              <div className="space-y-3 text-xs text-slate-400">
                <div className="flex justify-between">
                  <span>Trade ID:</span>
                  <span className="font-mono text-amber-400">{tradeId.slice(0, 14)}...</span>
                </div>
                <div className="flex justify-between">
                  <span>Buyer (Importer):</span>
                  <span className="font-mono text-slate-200">{buyerAddress.slice(0, 8)}...{buyerAddress.slice(-4)}</span>
                </div>
                <div className="flex justify-between">
                  <span>Seller (Exporter):</span>
                  <span className="font-mono text-slate-200">{sellerAddress.slice(0, 8)}...{sellerAddress.slice(-4)}</span>
                </div>
                <div className="flex justify-between">
                  <span>Contract Value:</span>
                  <span className="font-bold text-white font-mono">${totalEscrowAmount.toLocaleString()} USDC</span>
                </div>
                <div className="flex justify-between">
                  <span>Escrow Status:</span>
                  <span className="text-emerald-400 font-semibold">100% Fully Funded</span>
                </div>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm space-y-3">
              <h2 className="text-lg font-bold text-white">Trade Documentation</h2>
              <div className="space-y-2 text-xs font-mono">
                <div className="p-2.5 bg-slate-950 rounded-lg flex justify-between items-center">
                  <span>Commercial Invoice:</span>
                  <span className="text-emerald-400">Verified (IPFS)</span>
                </div>
                <div className="p-2.5 bg-slate-950 rounded-lg flex justify-between items-center">
                  <span>Purchase Order #842:</span>
                  <span className="text-emerald-400">Committed</span>
                </div>
                <div className="p-2.5 bg-slate-950 rounded-lg flex justify-between items-center">
                  <span>Incoterms 2020:</span>
                  <span className="text-amber-400">CIF Rotterdam</span>
                </div>
              </div>
            </div>
          </div>

          <div className="lg:col-span-2 space-y-6">
            <div className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm">
              <div className="flex justify-between items-center mb-6">
                <div>
                  <h2 className="text-xl font-bold text-white">Escrow Vault Allocation Breakdown</h2>
                  <p className="text-xs text-slate-400">Conditional stablecoin releases tied to attested milestone completion</p>
                </div>
                <span className="text-xs px-2.5 py-1 rounded-full bg-slate-800 text-slate-300 font-semibold font-mono">
                  3 Milestones
                </span>
              </div>

              <div className="grid grid-cols-2 gap-4 mb-6">
                <div className="p-4 bg-slate-950 rounded-xl border border-slate-800">
                  <span className="text-xs text-slate-400 block mb-1">Released to Exporter</span>
                  <span className="text-2xl font-black text-emerald-400 font-mono">${totalReleased.toLocaleString()} USDC</span>
                  <span className="text-[11px] text-slate-500 block mt-1">{(totalReleased / totalEscrowAmount * 100).toFixed(0)}% of Total</span>
                </div>
                <div className="p-4 bg-slate-950 rounded-xl border border-slate-800">
                  <span className="text-xs text-slate-400 block mb-1">Locked in Vault</span>
                  <span className="text-2xl font-black text-amber-400 font-mono">${remainingInVault.toLocaleString()} USDC</span>
                  <span className="text-[11px] text-slate-500 block mt-1">Awaiting Milestone Completion</span>
                </div>
              </div>

              <div className="space-y-4">
                {milestones.map((m, idx) => (
                  <div key={idx} className="p-5 rounded-xl bg-slate-950 border border-slate-800 space-y-3">
                    <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                      <div>
                        <span className="text-sm font-bold text-white">{m.name}</span>
                        <div className="text-xs text-slate-400 mt-0.5">{m.trigger}</div>
                      </div>
                      <span className="text-xs font-mono font-bold px-2.5 py-1 rounded bg-slate-900 text-amber-400 border border-slate-800">
                        ${m.amount.toLocaleString()} USDC ({m.percent}%)
                      </span>
                    </div>

                    <div className="flex justify-between items-center text-xs text-slate-500 pt-2 border-t border-slate-900">
                      <span>Authority: <code className="text-slate-300">{m.issuer}</code></span>
                      <div className="flex items-center gap-2">
                        {m.released ? (
                          <span className="px-2 py-0.5 rounded text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                            ✓ Payout Released
                          </span>
                        ) : m.completed ? (
                          <button
                            onClick={() => handleReleasePayment(idx)}
                            className="px-3 py-1 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs shadow-md"
                          >
                            Release Escrow Payout
                          </button>
                        ) : (
                          <button
                            onClick={() => handleCompleteMilestone(idx)}
                            className="px-3 py-1 rounded-lg bg-amber-600 hover:bg-amber-500 text-white font-bold text-xs shadow-md"
                          >
                            Verify & Complete
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: MILESTONES */}
      {activeTab === "milestones" && (
        <div className="max-w-4xl mx-auto p-8 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-6">
          <div>
            <h2 className="text-2xl font-bold text-white">Payment Release Manager (TradeEscrowVault.sol)</h2>
            <p className="text-sm text-slate-400 mt-1">
              Enforces sequential milestone dependencies and 24-hour challenge periods before releasing funds.
            </p>
          </div>

          <div className="space-y-4">
            {milestones.map((m, idx) => (
              <div key={idx} className="p-4 bg-slate-950 rounded-xl border border-slate-800 flex justify-between items-center">
                <div>
                  <span className="text-sm font-bold text-white">{m.name}</span>
                  <div className="text-xs text-slate-400 mt-1">Allocation: ${m.amount.toLocaleString()} USDC</div>
                </div>
                <div className="flex items-center gap-3">
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${m.released ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20" : m.completed ? "bg-amber-500/10 text-amber-400 border border-amber-500/20" : "bg-slate-800 text-slate-400"}`}>
                    {m.released ? "Released to Seller" : m.completed ? "Challenge Period Passed" : "Locked in Escrow"}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB 3: ATTESTATIONS */}
      {activeTab === "attestations" && (
        <div className="max-w-4xl mx-auto p-8 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-6">
          <div>
            <h2 className="text-2xl font-bold text-white">Ethereum Attestation Service (EAS) Verification</h2>
            <p className="text-sm text-slate-400 mt-1">
              Cryptographically signed off-chain and on-chain attestations verified by <code className="text-amber-400 font-mono">TradeAttestationVerifier.sol</code>.
            </p>
          </div>

          <div className="space-y-4">
            {[
              { type: "Bill of Lading Attestation", id: "EAS-UID-0x9a82bc194821a7bc", issuer: "Maersk Line Logistics", status: "VERIFIED", hash: "0x71fae8..." },
              { type: "SGS Inspection Certificate", id: "EAS-UID-0x41f87ab29c0182b7", issuer: "SGS Industrial Inspection Bureau", status: "VERIFIED", hash: "0x882bc9..." },
              { type: "Proof of Delivery Confirmation", id: "EAS-UID-0x12b98fa0174bb29a", issuer: "Port of Rotterdam Authority", status: "PENDING RECEIVER SIGNATURE", hash: "0xPending..." }
            ].map((a, idx) => (
              <div key={idx} className="p-4 bg-slate-950 rounded-xl border border-slate-800 flex justify-between items-center">
                <div>
                  <span className="text-sm font-bold text-white">{a.type}</span>
                  <div className="text-xs text-slate-400 font-mono mt-0.5">UID: {a.id} • Issuer: {a.issuer}</div>
                </div>
                <span className={`text-xs font-mono font-semibold px-2 py-0.5 rounded ${a.status === "VERIFIED" ? "text-emerald-400 bg-emerald-500/10 border border-emerald-500/20" : "text-amber-400 bg-amber-500/10 border border-amber-500/20"}`}>
                  {a.status}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB 4: DISPUTE */}
      {activeTab === "dispute" && (
        <div className="max-w-3xl mx-auto p-8 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-6">
          <div>
            <h2 className="text-2xl font-bold text-white">Dispute Arbitration Desk (TradeDisputeManager.sol)</h2>
            <p className="text-sm text-slate-400 mt-1">
              Enables independent commercial arbitrators (e.g. ICC / LCIA) to adjudicate disputes and allocate partial refunds or penalty deductions.
            </p>
          </div>

          <div className="p-5 rounded-xl bg-slate-950 border border-slate-800 space-y-3">
            <h3 className="text-sm font-bold text-white">Open Dispute Case #DISP-101</h3>
            <p className="text-xs text-slate-400">
              Disputed Milestone: <strong>Milestone 2 (Quality Inspection)</strong>. Disputed amount: <strong>$75,000 USDC</strong>.
            </p>
            <div className="flex gap-3 pt-2">
              <button
                onClick={() => alert("Arbitration Decision Executed: 70% Refunded to Buyer ($52,500 USDC), 30% Released to Seller ($22,500 USDC)")}
                className="flex-1 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-xs"
              >
                Execute Split Ruling (70% Buyer / 30% Seller)
              </button>
              <button
                onClick={() => alert("Full Refund Executed: 100% of Milestone Refunded to Buyer ($75,000 USDC)")}
                className="flex-1 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-500 text-white font-bold text-xs"
              >
                Full Refund to Buyer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
