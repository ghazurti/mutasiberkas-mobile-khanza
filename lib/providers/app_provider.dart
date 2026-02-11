import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/api_service.dart';

class AppProvider with ChangeNotifier {
  final ApiService apiService;
  final List<Patient> _scannedPatients = [];
  bool _isBatchMode = false;
  String _currentShelf = '';
  String _selectedDestination = '';

  AppProvider({required this.apiService});

  List<Patient> get scannedPatients => _scannedPatients;
  bool get isBatchMode => _isBatchMode;
  String get currentShelf => _currentShelf;
  String get selectedDestination => _selectedDestination;

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
