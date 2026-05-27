use crate::models::{Claims, LoginRequest, LoginResponse};
use axum::{Json, extract::State, http::StatusCode};
use jsonwebtoken::{EncodingKey, Header, encode};
use sqlx::MySqlPool;
use std::env;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(sqlx::FromRow)]
struct UserRow {
    username: String,
    nama: Option<String>,
}

pub async fn login(
    State(pool): State<MySqlPool>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    let secret = env::var("JWT_SECRET").unwrap_or_else(|_| "khanza-secret-key".to_string());

    // Khanza menyimpan id_user = AES_ENCRYPT(username, 'nur')
    // dan password = AES_ENCRYPT(password, 'windi')
    let row = sqlx::query_as::<_, UserRow>(
        r#"SELECT
            CONVERT(AES_DECRYPT(u.id_user, 'nur'), CHAR) as username,
            COALESCE(p.nama, CONVERT(AES_DECRYPT(u.id_user, 'nur'), CHAR)) as nama
           FROM user u
           LEFT JOIN petugas p ON CONVERT(AES_DECRYPT(u.id_user, 'nur'), CHAR) = p.nip
           WHERE u.id_user = AES_ENCRYPT(?, 'nur')
             AND u.password = AES_ENCRYPT(?, 'windi')"#,
    )
    .bind(&payload.username)
    .bind(&payload.password)
    .fetch_optional(&pool)
    .await
    .map_err(|e| {
        println!("❌ DB Error during login: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let user = row.ok_or_else(|| {
        println!("❌ Login failed for user: {}", payload.username);
        StatusCode::UNAUTHORIZED
    })?;

    let exp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs() as usize
        + 8 * 3600; // 8 jam

    let nama = user.nama.clone().unwrap_or_else(|| user.username.clone());

    let claims = Claims {
        sub: user.username.clone(),
        nama: nama.clone(),
        level: String::new(),
        exp,
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    println!("✅ Login success: {} ({})", user.username, nama);

    Ok(Json(LoginResponse {
        token,
        username: user.username,
        nama,
        level: String::new(),
    }))
}
