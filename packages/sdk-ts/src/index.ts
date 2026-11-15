export * from "./types.js";

export class TradeFinanceClient {
  private baseUrl: string;

  constructor(baseUrl: string = "http://localhost:8083") {
    this.baseUrl = baseUrl;
  }

  public async getAgreement(tradeId: string): Promise<any> {
    const res = await fetch(`${this.baseUrl}/api/v1/agreements/${tradeId}`);
    return res.json();
  }

  public async submitAttestation(payload: any): Promise<any> {
    const res = await fetch(`${this.baseUrl}/api/v1/attestations/submit`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    return res.json();
  }
}
