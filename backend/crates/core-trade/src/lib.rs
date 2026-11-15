use serde::{Deserialize, Serialize};
use sha3::{Digest, Keccak256};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum TradeError {
    #[error("Invalid milestone allocation: sum must equal 10000 bps")]
    InvalidAllocation,

    #[error("Agreement error: {0}")]
    AgreementError(String),

    #[error("Attestation verification error: {0}")]
    AttestationError(String),
}

pub type Result<T> = std::result::Result<T, TradeError>;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MilestoneDefinition {
    pub name: String,
    pub allocation_bps: u16, // e.g. 3000 = 30%
    pub challenge_period_seconds: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TradeAgreement {
    pub trade_id: String,
    pub buyer: String,
    pub seller: String,
    pub payment_token: String,
    pub total_amount: u64,
    pub milestones: Vec<MilestoneDefinition>,
    pub status: String,
}

impl TradeAgreement {
    pub fn validate_allocations(&self) -> Result<()> {
        let total: u16 = self.milestones.iter().map(|m| m.allocation_bps).sum();
        if total != 10000 {
            return Err(TradeError::InvalidAllocation);
        }
        Ok(())
    }

    pub fn calculate_payout(&self, milestone_index: usize) -> Result<u64> {
        let m = self.milestones.get(milestone_index)
            .ok_or_else(|| TradeError::AgreementError("Milestone index out of bounds".into()))?;
        Ok((self.total_amount * m.allocation_bps as u64) / 10000)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TradeAttestation {
    pub trade_id: String,
    pub milestone_index: usize,
    pub attester: String,
    pub attestation_type: String, // BillOfLading, InspectionCertificate, ProofOfDelivery
    pub document_cid: String,
    pub document_hash: String,
    pub timestamp: u64,
}

impl TradeAttestation {
    pub fn compute_digest(&self) -> [u8; 32] {
        let mut hasher = Keccak256::new();
        hasher.update(self.trade_id.as_bytes());
        hasher.update(&self.milestone_index.to_be_bytes());
        hasher.update(self.attester.as_bytes());
        hasher.update(self.document_hash.as_bytes());
        hasher.update(&self.timestamp.to_be_bytes());
        let res = hasher.finalize();
        let mut out = [0u8; 32];
        out.copy_from_slice(&res);
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_milestone_allocation_validation() {
        let trade = TradeAgreement {
            trade_id: "0x123".into(),
            buyer: "0xBuyer".into(),
            seller: "0xSeller".into(),
            payment_token: "0xUSDC".into(),
            total_amount: 100_000_000, // 100,000 USDC
            milestones: vec![
                MilestoneDefinition { name: "Shipping".into(), allocation_bps: 3000, challenge_period_seconds: 3600 },
                MilestoneDefinition { name: "Inspection".into(), allocation_bps: 3000, challenge_period_seconds: 3600 },
                MilestoneDefinition { name: "Delivery".into(), allocation_bps: 4000, challenge_period_seconds: 3600 },
            ],
            status: "Created".into(),
        };

        assert!(trade.validate_allocations().is_ok());
        assert_eq!(trade.calculate_payout(0).unwrap(), 30_000_000);
        assert_eq!(trade.calculate_payout(2).unwrap(), 40_000_000);
    }
}
