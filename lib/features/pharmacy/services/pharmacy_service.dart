import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

    try {
      final pharmacies = await _fetchFromOverpass(lat, lon, radius: 3000);
      if (pharmacies.isNotEmpty) {
        final withDist = pharmacies.map((p) => p.copyWith(
              distanceMeters: _locationService.distanceBetween(
                  lat, lon, p.latitude, p.longitude),
            )).toList();
        withDist.sort((a, b) =>
            (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
        return withDist.take(limit).toList();
      }
    } catch (e) {
      debugPrint('Overpass API failed: $e');
    }

    return [];
  }

  Future<List<PharmacyModel>> _fetchFromOverpass(
    double lat,
    double lon, {
    int radius = 3000,
  }) async {
    final query =
        '[out:json][timeout:15];(node[amenity=pharmacy](around:$radius,$lat,$lon);'
        'way[amenity=pharmacy](around:$radius,$lat,$lon););out center 40;';

    final response = await http
        .post(
          Uri.parse('https://overpass-api.de/api/interpreter'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: 'data=${Uri.encodeComponent(query)}',
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Overpass API ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>;

    final result = <PharmacyModel>[];
    for (final e in elements) {
      final tags = (e['tags'] as Map<String, dynamic>?) ?? {};

      final name = tags['name'] as String? ??
          tags['brand'] as String? ??
          'Аптека';

      final phone = tags['phone'] as String? ??
          tags['contact:phone'] as String? ??
          tags['contact:mobile'] as String? ??
          '';

      final openHours = tags['opening_hours'] as String?;
      final isOpen24h =
          openHours == '24/7' || openHours == 'Mo-Su 00:00-24:00';

      // Coordinates
      double? elat, elon;
      if (e['type'] == 'node') {
        elat = (e['lat'] as num?)?.toDouble();
        elon = (e['lon'] as num?)?.toDouble();
      } else if (e['center'] != null) {
        elat = (e['center']['lat'] as num?)?.toDouble();
        elon = (e['center']['lon'] as num?)?.toDouble();
      }
      if (elat == null || elon == null) continue;

      // Address
      final street = tags['addr:street'] as String?;
      final houseNum = tags['addr:housenumber'] as String?;
      final city = tags['addr:city'] as String? ??
          tags['addr:town'] as String? ??
          'София';
      String address = city;
      if (street != null) {
        address = houseNum != null
            ? '$street $houseNum, $city'
            : '$street, $city';
      }

      result.add(PharmacyModel(
        id: 'osm_${e['id']}',
        name: name,
        address: address,
        phone: phone,
        latitude: elat,
        longitude: elon,
        isOpen24h: isOpen24h,
        openHours: isOpen24h ? null : openHours,
      ));
    }
    return result;
  }
}
