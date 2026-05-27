use dotenvy::dotenv;
use sqlx::mysql::MySqlPoolOptions;
use std::env;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenv().ok();
    let database_url = env::var("DATABASE_URL")?;
    let pool = MySqlPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    println!("--- Creating Shelf Location Table ---");

    let sql = "
        CREATE TABLE IF NOT EXISTS rak_penyimpanan_berkas (
            no_rkm_medis VARCHAR(15) NOT NULL,
            kd_rak VARCHAR(20) NOT NULL,
            PRIMARY KEY (no_rkm_medis)
        ) ENGINE=InnoDB;
    ";

    match sqlx::query(sql).execute(&pool).await {
        Ok(_) => println!("✅ Table 'rak_penyimpanan_berkas' created or already exists."),
        Err(e) => println!("❌ Error creating table: {}", e),
    }

    Ok(())
}
