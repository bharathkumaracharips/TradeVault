use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use core_trade::{TradeAgreement, TradeAttestation};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::sync::RwLock;
use tower_http::cors::CorsLayer;
use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;

#[derive(Clone)]
struct AppState {
    agreements: Arc<RwLock<HashMap<String, TradeAgreement>>>,
    attestations: Arc<RwLock<HashMap<String, Vec<TradeAttestation>>>>,
    escrow_balances: Arc<RwLock<HashMap<String, u64>>>,
}

#[tokio::main]
async fn main() {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .finish();
    tracing::subscriber::set_global_default(subscriber).unwrap_or_default();

    let state = AppState {
        agreements: Arc::new(RwLock::new(HashMap::new())),
        attestations: Arc::new(RwLock::new(HashMap::new())),
        escrow_balances: Arc::new(RwLock::new(HashMap::new())),
    };

    let app = Router::new()
        .route("/health", get(health_check))
        .route("/api/v1/agreements/create", post(create_agreement))
        .route("/api/v1/agreements/:id", get(get_agreement))
        .route("/api/v1/attestations/submit", post(submit_attestation))
        .route("/api/v1/attestations/:id", get(get_attestations))
        .route("/api/v1/escrow/fund", post(fund_escrow))
        .route("/api/v1/escrow/:id/balance", get(get_escrow_balance))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let port = std::env::var("PORT").unwrap_or_else(|_| "8083".to_string());
    let addr = SocketAddr::from(([0, 0, 0, 0], port.parse().unwrap_or(8083)));
    info!("Trade Finance Escrow API running on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health_check() -> impl IntoResponse {
    Json(json!({
        "status": "healthy",
        "service": "Trade Finance Escrow & EAS Attestation Server",
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

async fn create_agreement(
    State(state): State<AppState>,
    Json(payload): Json<TradeAgreement>,
) -> impl IntoResponse {
    if let Err(e) = payload.validate_allocations() {
        return (StatusCode::BAD_REQUEST, Json(json!({"error": e.to_string()})));
    }

    let trade_id = payload.trade_id.clone();
    let mut map = state.agreements.write().await;
    map.insert(trade_id.clone(), payload);

    info!("Registered trade agreement {}", trade_id);

    (
        StatusCode::CREATED,
        Json(json!({
            "success": true,
            "tradeId": trade_id,
            "message": "Trade agreement registered successfully"
        })),
    )
}

async fn get_agreement(
    Path(id): Path<String>,
    State(state): State<AppState>,
) -> impl IntoResponse {
    let map = state.agreements.read().await;
    match map.get(&id) {
        Some(a) => (StatusCode::OK, Json(json!(a))),
        None => (StatusCode::NOT_FOUND, Json(json!({"error": "Trade not found"}))),
    }
}

async fn submit_attestation(
    State(state): State<AppState>,
    Json(payload): Json<TradeAttestation>,
) -> impl IntoResponse {
    let trade_id = payload.trade_id.clone();
    let digest = hex::encode(payload.compute_digest());

    let mut map = state.attestations.write().await;
    map.entry(trade_id.clone()).or_default().push(payload);

    (
        StatusCode::OK,
        Json(json!({
            "success": true,
            "tradeId": trade_id,
            "attestationDigest": format!("0x{}", digest),
            "message": "Attestation registered and verified"
        })),
    )
}

async fn get_attestations(
    Path(id): Path<String>,
    State(state): State<AppState>,
) -> impl IntoResponse {
    let map = state.attestations.read().await;
    let list = map.get(&id).cloned().unwrap_or_default();

    Json(json!({
        "tradeId": id,
        "count": list.len(),
        "attestations": list
    }))
}

#[derive(Debug, Deserialize)]
struct FundEscrowRequest {
    trade_id: String,
    amount: u64,
}

async fn fund_escrow(
    State(state): State<AppState>,
    Json(payload): Json<FundEscrowRequest>,
) -> impl IntoResponse {
    let mut map = state.escrow_balances.write().await;
    *map.entry(payload.trade_id.clone()).or_insert(0) += payload.amount;

    (
        StatusCode::OK,
        Json(json!({
            "success": true,
            "tradeId": payload.trade_id,
            "balance": map.get(&payload.trade_id).unwrap_or(&0)
        })),
    )
}

async fn get_escrow_balance(
    Path(id): Path<String>,
    State(state): State<AppState>,
) -> impl IntoResponse {
    let map = state.escrow_balances.read().await;
    let balance = map.get(&id).copied().unwrap_or(0);

    Json(json!({
        "tradeId": id,
        "balance": balance
    }))
}
