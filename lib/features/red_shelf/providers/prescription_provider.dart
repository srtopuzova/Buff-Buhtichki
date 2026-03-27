import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:medshelf/features/red_shelf/models/prescription_model.dart';
import 'package:medshelf/features/red_shelf/services/prescription_service.dart';

class PrescriptionProvider extends ChangeNotifier {
  final PrescriptionService _service = PrescriptionService();

  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  List<PrescriptionModel> get prescriptions =>
      List.unmodifiable(_prescriptions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<PrescriptionModel> get pending =>
      _prescriptions.where((p) => p.isPending).toList();

  List<PrescriptionModel> get active =>
      _prescriptions.where((p) => p.isActive).toList();

  void initialize(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _service.watchPrescriptions(userId).listen(
      (list) {
        _prescriptions = list;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  Future<bool> addPrescription({
    required PrescriptionModel prescription,
    File? imageFile,
  }) async {
    if (_currentUserId == null) return false;
    _setLoading(true);
    try {
      await _service.addPrescription(
        userId: _currentUserId!,
        prescription: prescription,
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

  Future<bool> markPickedUp(PrescriptionModel prescription) async {
    try {
      await _service.markPickedUp(prescription);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordDose(String prescriptionId, bool taken) async {
    try {
      await _service.recordDose(prescriptionId, taken);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setItemReminder({
    required PrescriptionModel prescription,
    required int itemIndex,
    required int hour,
    required int minute,
  }) async {
    try {
      await _service.setItemReminder(
        prescription: prescription,
        itemIndex: itemIndex,
        hour: hour,
        minute: minute,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePrescription(String prescriptionId) async {
    _setLoading(true);
    try {
      await _service.deletePrescription(prescriptionId);
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