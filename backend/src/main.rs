use axum::{
    Router,
    routing::{get, post, put},
};
use dotenvy::dotenv;
use std::env;
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;

mod db;
mod handlers;
mod models;

#[tokio::main]
async fn main() {
    dotenv().ok();

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let pool = db::init_pool(&database_url).await;

    let app = Router::new()
        .route("/api/pasien/:no_rm", get(handlers::pasien::get_patient))
        .route(
            "/api/rekammedis/mutasi-berkas",
            post(handlers::rekammedis::post_mutation),
        )
        .route(
            "/api/rekammedis/picking-list",
            get(handlers::picking::get_picking_list),
        )
        .route(
            "/api/pasien/update-rak",
            put(handlers::pasien::update_shelf),
        )
        .layer(CorsLayer::permissive())
        .with_state(pool);

    let addr = env::var("SERVER_ADDR").unwrap_or_else(|_| "0.0.0.0:3000".to_string());
    let addr: SocketAddr = addr.parse().expect("Invalid SERVER_ADDR");

    println!("Backend server running on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
