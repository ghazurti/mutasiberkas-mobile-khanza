use axum::{Json, extract::State, http::StatusCode};
use serde::Serialize;
use sqlx::MySqlPool;

#[derive(Serialize)]
pub struct DashboardStats {
    pub total_pasien_hari_ini: i64,
    pub berkas_dikirim_hari_ini: i64,
    pub berkas_kembali_hari_ini: i64,
    pub berkas_pending: i64,
}

pub async fn get_stats(
    State(pool): State<MySqlPool>,
) -> Result<Json<DashboardStats>, StatusCode> {
    let total: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM reg_periksa r
         JOIN poliklinik pol ON r.kd_poli = pol.kd_poli
         WHERE r.tgl_registrasi = CURDATE()
         AND pol.nm_poli NOT LIKE '%IGD%'",
    )
    .fetch_one(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let dikirim: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM mutasi_berkas WHERE DATE(dikirim) = CURDATE()",
    )
    .fetch_one(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let kembali: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM mutasi_berkas WHERE DATE(kembali) = CURDATE()",
    )
    .fetch_one(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let pending = total - dikirim;

    Ok(Json(DashboardStats {
        total_pasien_hari_ini: total,
        berkas_dikirim_hari_ini: dikirim,
        berkas_kembali_hari_ini: kembali,
        berkas_pending: pending.max(0),
    }))
}
