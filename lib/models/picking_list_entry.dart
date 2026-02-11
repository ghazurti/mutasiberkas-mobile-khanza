class PickingListEntry {
  final String noRawat;
  final String noRm;
  final String name;
  final String poli;
  final String? shelf;

  PickingListEntry({
    required this.noRawat,
    required this.noRm,
    required this.name,
    required this.poli,
    this.shelf,
  });

  factory PickingListEntry.fromJson(Map<String, dynamic> json) {
    return PickingListEntry(
      noRawat: json['no_rawat'] ?? '',
      noRm: json['no_rkm_medis'] ?? '',
      name: json['nm_pasien'] ?? '',
      poli: json['nm_poli'] ?? '',
      shelf: json['kd_rak'],
    );
  }
}
