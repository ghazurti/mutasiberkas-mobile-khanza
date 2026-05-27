class Patient {
  final String noRm;
  final String name;
  final String? shelf;
  final String? status;

  Patient({
    required this.noRm,
    required this.name,
    this.shelf,
    this.status,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      noRm: json['no_rkm_medis'] ?? '',
      name: json['nm_pasien'] ?? '',
      shelf: json['kd_rak'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'no_rkm_medis': noRm,
      'nm_pasien': name,
      'kd_rak': shelf,
      'status': status,
    };
  }
}
