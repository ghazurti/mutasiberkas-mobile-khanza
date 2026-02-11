import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient.dart';
import '../models/picking_list_entry.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<Patient?> getPatientInfo(String noRm) async {
    try {
      final cleanNoRm = noRm.trim();
      final response = await http.get(
        Uri.parse('$baseUrl/api/pasien/$cleanNoRm'),
      );
      if (response.statusCode == 200) {
        return Patient.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  Future<List<PickingListEntry>> getPickingList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rekammedis/picking-list'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PickingListEntry.fromJson(json)).toList();
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }

  Future<bool> postMutation({
    required String noRm,
    required String destination,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rekammedis/mutasi-berkas'),
        body: jsonEncode({
          'no_rkm_medis': noRm,
          'tujuan': destination,
          'tgl_pinjam': DateTime.now().toIso8601String().substring(0, 10),
        }),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateShelf(String noRm, String shelf) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/pasien/update-rak'),
        body: jsonEncode({'no_rkm_medis': noRm, 'kd_rak': shelf}),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
