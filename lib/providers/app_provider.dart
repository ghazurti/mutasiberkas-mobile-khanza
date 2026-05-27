import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../models/user_session.dart';
import '../services/api_service.dart';

class AppProvider with ChangeNotifier {
  final ApiService apiService;
  final List<Patient> _scannedPatients = [];
  bool _isBatchMode = false;
  String _currentShelf = '';
  String _selectedDestination = '';
  UserSession? _session;

  AppProvider({required this.apiService});

  List<Patient> get scannedPatients => _scannedPatients;
  bool get isBatchMode => _isBatchMode;
  String get currentShelf => _currentShelf;
  String get selectedDestination => _selectedDestination;
  UserSession? get session => _session;
  bool get isLoggedIn => _session != null;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');
    final nama = prefs.getString('nama');
    final level = prefs.getString('level');

    if (token != null && username != null && nama != null && level != null) {
      _session = UserSession(
          token: token, username: username, nama: nama, level: level);
      apiService.setToken(token);
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    final session = await apiService.login(username, password);
    if (session == null) return false;

    _session = session;
    apiService.setToken(session.token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', session.token);
    await prefs.setString('username', session.username);
    await prefs.setString('nama', session.nama);
    await prefs.setString('level', session.level);

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _session = null;
    apiService.clearToken();
    _scannedPatients.clear();
    _currentShelf = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  void addScannedPatient(Patient patient) {
    _scannedPatients.insert(0, patient);
    notifyListeners();
  }

  void clearScannedPatients() {
    _scannedPatients.clear();
    notifyListeners();
  }

  void setBatchMode(bool value) {
    _isBatchMode = value;
    notifyListeners();
  }

  void setCurrentShelf(String shelf) {
    _currentShelf = shelf;
    notifyListeners();
  }

  void setSelectedDestination(String destination) {
    _selectedDestination = destination;
    notifyListeners();
  }
}
