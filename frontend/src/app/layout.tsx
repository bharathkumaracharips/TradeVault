import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "TradeEscrow | Milestone-Based Trade Finance Escrow DApp",
  description: "Smart contract escrow for international trade with EAS attestations, Bill of Lading, SGS inspection, and conditional stablecoin releases",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className="bg-slate-950 text-slate-100 antialiased selection:bg-amber-600 selection:text-white">
        <header className="border-b border-slate-800 bg-slate-900/60 backdrop-blur sticky top-0 z-50">
          <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-amber-500 to-emerald-600 flex items-center justify-center text-white font-black text-lg shadow-lg shadow-amber-500/20">
                TE
              </div>
              <div>
                <span className="font-bold text-lg text-white tracking-tight">TradeEscrow DApp</span>
                <span className="ml-2 text-xs px-2 py-0.5 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/20 font-mono">
                  EAS + Stablecoin Escrow
                </span>
              </div>
            </div>
            <div className="flex items-center space-x-6 text-sm font-medium text-slate-300">
              <a href="#trade" className="hover:text-amber-400 transition-colors">Trade Agreement</a>
              <a href="#milestones" className="hover:text-amber-400 transition-colors">Milestones</a>
              <a href="#attestations" className="hover:text-amber-400 transition-colors">Attestations & BoL</a>
              <a href="#disputes" className="hover:text-amber-400 transition-colors">Arbitration</a>
            </div>
          </div>
        </header>
        <main>{children}</main>
        <footer className="border-t border-slate-800/80 py-8 text-center text-xs text-slate-500">
          TradeEscrow Protocol • Milestone-Based Cross-Border Settlement • Ethereum Attestation Service
        </footer>
      </body>
    </html>
  );
}
