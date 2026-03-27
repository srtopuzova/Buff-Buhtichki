import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:medshelf/core/constants/app_constants.dart';
import 'package:medshelf/features/pharmacy/models/pharmacy_model.dart';
import 'package:medshelf/shared/services/location_service.dart';

class PharmacyService {
  static final PharmacyService _instance = PharmacyService._internal();
  factory PharmacyService() => _instance;
  PharmacyService._internal();

  final LocationService _locationService = LocationService();

  Future<List<PharmacyModel>> getNearbyPharmacies({int limit = 10}) async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return [];

    final lat = position.latitude;
    final lon = position.longitude;

    final pharmacies = await _fetchFromGooglePlaces(lat, lon, limit: limit);

    final withDist = pharmacies
        .map((p) => p.copyWith(
              distanceMeters: _locationService.distanceBetween(
                  lat, lon, p.latitude, p.longitude),
            ))
        .toList();
    withDist.sort(
        (a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
    return withDist;
  }

  Future<List<PharmacyModel>> _fetchFromGooglePlaces(
    double lat,
    double lon, {
    int limit = 10,
  }) async {
    final fieldMask = [
      'places.id',
      'places.displayName',
      'places.formattedAddress',
      'places.location',
      'places.nationalPhoneNumber',
      'places.regularOpeningHours',
    ].join(',');

    final response = await http
        .post(
          Uri.parse(AppConstants.googlePlacesUrl),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': AppConstants.googleMapsApiKey,
            'X-Goog-FieldMask': fieldMask,
          },
          body: jsonEncode({
            'includedTypes': ['pharmacy'],
            'maxResultCount': 20,
            'rankPreference': 'DISTANCE',
            'locationRestriction': {
              'circle': {
                'center': {'latitude': lat, 'longitude': lon},
                'radius': 5000.0,
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      debugPrint('Google Places ${response.statusCode}: ${response.body}');
      throw Exception('Google Places API ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final places = (data['places'] as List<dynamic>?) ?? [];

    return places.map((p) => _parsePlace(p as Map<String, dynamic>)).toList();
  }

  PharmacyModel _parsePlace(Map<String, dynamic> p) {
    final name =
        (p['displayName'] as Map<String, dynamic>?)?['text'] as String? ??
            'Аптека';
    final address = p['formattedAddress'] as String? ?? '';
    final phone = p['nationalPhoneNumber'] as String? ?? '';
    final lat = (p['location']?['latitude'] as num).toDouble();
    final lon = (p['location']?['longitude'] as num).toDouble();

    // Detect 24/7: a period with open but no close time
    final hours = p['regularOpeningHours'] as Map<String, dynamic>?;
    final periods = (hours?['periods'] as List<dynamic>?) ?? [];
    final isOpen24h = periods.any((period) {
      final m = period as Map<String, dynamic>;
      return m['close'] == null;
    });
    final weekdayDescriptions =
        (hours?['weekdayDescriptions'] as List<dynamic>?)
            ?.map((e) => e as String)
            .join('; ');

    return PharmacyModel(
      id: p['id'] as String? ?? '',
      name: name,
      address: address,
      phone: phone,
      latitude: lat,
      longitude: lon,
      isOpen24h: isOpen24h,
      openHours: isOpen24h ? null : weekdayDescriptions,
    );
  }
}
