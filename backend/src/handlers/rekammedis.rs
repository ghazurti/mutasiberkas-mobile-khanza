use crate::models::MutationRequest;
use axum::{Json, extract::State, http::StatusCode};
use chrono::{DateTime, FixedOffset, Utc};
use sqlx::MySqlPool;

pub async fn post_mutation(
    State(pool): State<MySqlPool>,
    Json(payload): Json<MutationRequest>,
) -> Result<StatusCode, StatusCode> {
    let clean_no_rm = payload.no_rkm_medis.trim();
    println!("📦 Mutation Request for No.RM: [{}]", clean_no_rm);

    // 1. Get the latest no_rawat and status for today
    let visit = sqlx::query!(
        "SELECT no_rawat, status_lanjut FROM reg_periksa 
         WHERE no_rkm_medis = ? AND tgl_registrasi = CURDATE() 
         ORDER BY jam_reg DESC LIMIT 1",
        clean_no_rm
    )
    .fetch_optional(&pool)
    .await;

    let (no_rawat, is_ranap) = match visit {
        Ok(Some(v)) => {
            println!("✅ Visit Found: {} ({})", v.no_rawat, v.status_lanjut);
            (v.no_rawat, v.status_lanjut == "Ranap")
        }
        Ok(None) => {
            println!("❌ No visit found for No.RM: [{}] today", clean_no_rm);
            return Err(StatusCode::NOT_FOUND);
        }
        Err(e) => {
            println!("💾 Database Error (fetching no_rawat): {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // 2. Prepare Local Timestamp (WITA +08:00) in Rust
    // This bypasses MySQL timezone configuration issues
    let offset = FixedOffset::east_opt(8 * 3600).unwrap();
    let local_now: DateTime<FixedOffset> = Utc::now().with_timezone(&offset);
    let now_str = local_now.format("%Y-%m-%d %H:%M:%S").to_string();

    // 3. Perform UPSERT on mutasi_berkas
    let result = if payload.tujuan == "Kirim" {
        println!("🚀 Sending record for {} (WITA: {})", no_rawat, now_str);
        if is_ranap {
            sqlx::query(
                "INSERT INTO mutasi_berkas (no_rawat, status, dikirim, ranap) 
                 VALUES (?, 'Sudah Dikirim', ?, ?) 
                 ON DUPLICATE KEY UPDATE status = 'Sudah Dikirim', dikirim = ?, ranap = ?",
            )
            .bind(&no_rawat)
            .bind(&now_str)
            .bind(&now_str)
            .bind(&now_str)
            .bind(&now_str)
            .execute(&pool)
            .await
        } else {
            sqlx::query(
                "INSERT INTO mutasi_berkas (no_rawat, status, dikirim, ranap) 
                 VALUES (?, 'Sudah Dikirim', ?, '0000-00-00 00:00:00') 
                 ON DUPLICATE KEY UPDATE status = 'Sudah Dikirim', dikirim = ?",
            )
            .bind(&no_rawat)
            .bind(&now_str)
            .bind(&now_str)
            .execute(&pool)
            .await
        }
    } else {
        println!("↩️ Returning record for {} (WITA: {})", no_rawat, now_str);
        sqlx::query(
            "INSERT INTO mutasi_berkas (no_rawat, status, kembali) 
             VALUES (?, 'Sudah Kembali', ?) 
             ON DUPLICATE KEY UPDATE status = 'Sudah Kembali', kembali = ?",
        )
        .bind(&no_rawat)
        .bind(&now_str)
        .bind(&now_str)
        .execute(&pool)
        .await
    };

    match result {
        Ok(_) => {
            println!("✨ Mutation SUCCESS for {}", no_rawat);
            Ok(StatusCode::CREATED)
        }
        Err(e) => {
            println!("💾 Database Error (mutation): {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}
