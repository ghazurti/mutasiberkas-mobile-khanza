class DashboardStats {
  final int totalPasienHariIni;
  final int berkasDikirimHariIni;
  final int berkasKembaliHariIni;
  final int berkasPending;

  const DashboardStats({
    required this.totalPasienHariIni,
    required this.berkasDikirimHariIni,
    required this.berkasKembaliHariIni,
    required this.berkasPending,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalPasienHariIni: json['total_pasien_hari_ini'] as int,
        berkasDikirimHariIni: json['berkas_dikirim_hari_ini'] as int,
        berkasKembaliHariIni: json['berkas_kembali_hari_ini'] as int,
        berkasPending: json['berkas_pending'] as int,
      );
}
