export interface Milestone {
  name: string;
  allocationBps: number;
  challengePeriodSeconds: number;
  completed: boolean;
  released: boolean;
}

export interface TradeAgreement {
  tradeId: string;
  buyer: string;
  seller: string;
  paymentToken: string;
  totalAmount: string;
  status: "Created" | "AcceptedByBuyer" | "AcceptedBySeller" | "FullyAccepted" | "EscrowFunded" | "InExecution" | "Completed" | "Disputed";
  milestones: Milestone[];
}

export interface AttestationPayload {
  tradeId: string;
  milestoneIndex: number;
  attester: string;
  attestationType: "BillOfLading" | "InspectionCertificate" | "ProofOfDelivery";
  documentCID: string;
  documentHash: string;
  timestamp: number;
}
