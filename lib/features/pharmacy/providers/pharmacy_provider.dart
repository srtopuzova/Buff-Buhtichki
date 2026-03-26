import 'package:flutter/foundation.dart';
import 'package:medshelf/features/pharmacy/models/pharmacy_model.dart';
import 'package:medshelf/features/pharmacy/services/pharmacy_service.dart';

class PharmacyProvider extends ChangeNotifier {
  final PharmacyService _service = PharmacyService();

  List<PharmacyModel> _pharmacies = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLocation = false;

  List<PharmacyModel> get pharmacies => List.unmodifiable(_pharmacies);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLocation => _hasLocation;

  Future<void> loadNearbyPharmacies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _service.getNearbyPharmacies(limit: 10);
      _pharmacies = results;
      _hasLocation = results.isNotEmpty && results.first.distanceMeters != null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
