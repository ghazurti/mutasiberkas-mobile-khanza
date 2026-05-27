use crate::models::{Patient, UpdateShelfRequest};
use axum::{
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use sqlx::MySqlPool;

pub async fn get_patient(
    State(pool): State<MySqlPool>,
    Path(no_rm): Path<String>,
) -> Result<Json<Patient>, StatusCode> {
    let clean_no_rm = no_rm.trim();
    println!("🔍 Searching for Patient: [{}]", clean_no_rm);

    // 1. Try exact match as provided
    let patient = sqlx::query_as::<_, Patient>(
        "SELECT p.no_rkm_medis, p.nm_pasien, r.kd_rak 
         FROM pasien p 
         LEFT JOIN rak_penyimpanan_berkas r ON p.no_rkm_medis = r.no_rkm_medis 
         WHERE p.no_rkm_medis = ?",
    )
    .bind(clean_no_rm)
    .fetch_one(&pool)
    .await;

    if let Ok(p) = patient {
        println!("✅ Patient Found: {}", p.name);
        return Ok(Json(p));
    }

    // 2. Try with leading zeros padding for different lengths (6, 8, 10)
    if clean_no_rm.chars().all(|c| c.is_digit(10)) {
        let lengths = vec![6, 8, 10];
        for len in lengths {
            if clean_no_rm.len() < len {
                let padded = format!("{:0>width$}", clean_no_rm, width = len);
                println!("🔄 Trying padded: [{}]", padded);
                let p_padded = sqlx::query_as::<_, Patient>(
                    "SELECT p.no_rkm_medis, p.nm_pasien, r.kd_rak 
                     FROM pasien p 
                     LEFT JOIN rak_penyimpanan_berkas r ON p.no_rkm_medis = r.no_rkm_medis 
                     WHERE p.no_rkm_medis = ?",
                )
                .bind(padded)
                .fetch_one(&pool)
                .await;

                if let Ok(p) = p_padded {
                    println!("✅ Patient Found (Padded): {}", p.name);
                    return Ok(Json(p));
                }
            }
        }
    }

    println!("❌ Patient Not Found: [{}]", clean_no_rm);
    Err(StatusCode::NOT_FOUND)
}

pub async fn update_shelf(
    State(pool): State<MySqlPool>,
    Json(payload): Json<UpdateShelfRequest>,
) -> Result<StatusCode, StatusCode> {
    println!(
        "📍 Updating Shelf for No.RM: [{}] -> {}",
        payload.no_rkm_medis, payload.kd_rak
    );

    let result = sqlx::query(
        "INSERT INTO rak_penyimpanan_berkas (no_rkm_medis, kd_rak) 
         VALUES (?, ?) 
         ON DUPLICATE KEY UPDATE kd_rak = VALUES(kd_rak)",
    )
    .bind(&payload.no_rkm_medis)
    .bind(&payload.kd_rak)
    .execute(&pool)
    .await;

    match result {
        Ok(_) => {
            println!("✅ Shelf updated successfully.");
            Ok(StatusCode::OK)
        }
        Err(e) => {
            println!("💾 Database Error (updating shelf): {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}
