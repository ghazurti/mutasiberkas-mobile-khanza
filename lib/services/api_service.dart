import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_stats.dart';
import '../models/patient.dart';
import '../models/picking_list_entry.dart';
import '../models/user_session.dart';

class ApiService {
  final String baseUrl;
  String? _token;

  ApiService({required this.baseUrl});

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<UserSession?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final session = UserSession.fromJson(jsonDecode(response.body));
        _token = session.token;
        return session;
      }
    } catch (_) {}
    return null;
  }

  Future<DashboardStats?> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard/stats'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return DashboardStats.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<Patient?> getPatientInfo(String noRm) async {
    try {
      final cleanNoRm = noRm.trim();
      final response = await http.get(
        Uri.parse('$baseUrl/api/pasien/$cleanNoRm'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return Patient.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<List<PickingListEntry>> getPickingList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rekammedis/picking-list'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PickingListEntry.fromJson(json)).toList();
      }
    } catch (_) {}
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
        headers: _headers,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateShelf(String noRm, String shelf) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/pasien/update-rak'),
        body: jsonEncode({'no_rkm_medis': noRm, 'kd_rak': shelf}),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
