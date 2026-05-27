use crate::models::PickingListEntry;
use axum::{Json, extract::State, http::StatusCode};
use sqlx::MySqlPool;

pub async fn get_picking_list(
    State(pool): State<MySqlPool>,
) -> Result<Json<Vec<PickingListEntry>>, StatusCode> {
    let list = sqlx::query_as::<_, PickingListEntry>(
        "SELECT r.no_rawat, r.no_rkm_medis, p.nm_pasien, pol.nm_poli, rk.kd_rak 
         FROM reg_periksa r
         JOIN pasien p ON r.no_rkm_medis = p.no_rkm_medis
         JOIN poliklinik pol ON r.kd_poli = pol.kd_poli
         LEFT JOIN mutasi_berkas m ON r.no_rawat = m.no_rawat
         LEFT JOIN rak_penyimpanan_berkas rk ON r.no_rkm_medis = rk.no_rkm_medis
         WHERE r.tgl_registrasi = CURDATE()
         AND (m.status IS NULL OR m.status NOT IN ('Sudah Dikirim', 'Sudah Kembali'))
         ORDER BY r.jam_reg ASC",
    )
    .fetch_all(&pool)
    .await;

    match list {
        Ok(entries) => Ok(Json(entries)),
        Err(e) => {
            println!("💾 Database Error (picking-list): {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}
