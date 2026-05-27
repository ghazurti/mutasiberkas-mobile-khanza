use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, sqlx::FromRow)]
pub struct Patient {
    #[sqlx(rename = "no_rkm_medis")]
    #[serde(rename = "no_rkm_medis")]
    pub no_rm: String,
    #[sqlx(rename = "nm_pasien")]
    #[serde(rename = "nm_pasien")]
    pub name: String,
    pub kd_rak: Option<String>,
}

#[derive(Deserialize)]
pub struct MutationRequest {
    pub no_rkm_medis: String,
    pub tujuan: String,
}

#[derive(Deserialize)]
pub struct LoginRequest {
    pub username: String,
    pub password: String,
}

#[derive(Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub username: String,
    pub nama: String,
    pub level: String,
}

#[derive(Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    pub nama: String,
    pub level: String,
    pub exp: usize,
}

#[allow(dead_code)]
#[derive(Deserialize)]
pub struct UpdateShelfRequest {
    pub no_rkm_medis: String,
    pub kd_rak: String,
}

#[derive(Serialize, sqlx::FromRow)]
pub struct PickingListEntry {
    pub no_rawat: String,
    #[sqlx(rename = "no_rkm_medis")]
    #[serde(rename = "no_rkm_medis")]
    pub no_rm: String,
    #[sqlx(rename = "nm_pasien")]
    #[serde(rename = "nm_pasien")]
    pub name: String,
    #[sqlx(rename = "nm_poli")]
    #[serde(rename = "nm_poli")]
    pub poli: String,
    pub kd_rak: Option<String>,
}
