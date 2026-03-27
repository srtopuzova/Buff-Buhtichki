import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:medshelf/features/med_shelf/models/medication_model.dart';
import 'package:medshelf/features/med_shelf/services/medication_service.dart';

class MedicationProvider extends ChangeNotifier {
  final MedicationService _service = MedicationService();

  List<MedicationModel> _medications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  StreamSubscription<List<MedicationModel>>? _subscription;

  List<MedicationModel> get medications => List.unmodifiable(_medications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MedicationModel> get expired =>
      _medications.where((m) => m.isExpired).toList();

  List<MedicationModel> get expiringSoon =>
      _medications.where((m) => !m.isExpired && m.isExpiringSoon).toList();

  List<MedicationModel> get active =>
      _medications.where((m) => !m.isExpired).toList();

  void initialize(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _subscription?.cancel();
    _subscription = _service.watchMedications(userId).listen(
      (list) {
        _medications = list;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<bool> addMedication({
    required MedicationModel medication,
    File? imageFile,
  }) async {
    if (_currentUserId == null) return false;
    _setLoading(true);
    try {
      await _service.addMedication(
        userId: _currentUserId!,
        medication: medication,
        imageFile: imageFile,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateMedication(MedicationModel medication,
      {File? imageFile}) async {
    _setLoading(true);
    try {
      await _service.updateMedication(medication, imageFile: imageFile);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addBatch({
    required String medicationId,
    required MedicationBatch batch,
    required String medicationName,
  }) async {
    try {
      await _service.addBatch(
        medicationId: medicationId,
        batch: batch,
        medicationName: medicationName,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeBatch({
    required String medicationId,
    required String batchId,
    required List<MedicationBatch> currentBatches,
  }) async {
    try {
      await _service.removeBatch(
        medicationId: medicationId,
        batchId: batchId,
        currentBatches: currentBatches,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedication(String medicationId) async {
    _setLoading(true);
    try {
      await _service.deleteMedication(medicationId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
