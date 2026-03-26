import 'package:medshelf/features/pharmacy/models/pharmacy_model.dart';
import 'package:medshelf/shared/services/location_service.dart';

class PharmacyService {
  static final PharmacyService _instance = PharmacyService._internal();
  factory PharmacyService() => _instance;
  PharmacyService._internal();

  final LocationService _locationService = LocationService();

  // 15 mock pharmacies near Sofia, Bulgaria
  static final List<PharmacyModel> _allPharmacies = [
    PharmacyModel(
      id: 'ph_001',
      name: 'Аптека Марешки',
      address: 'бул. Витоша 42, София',
      phone: '+359 2 981 4455',
      latitude: 42.6977,
      longitude: 23.3219,
      isOpen24h: true,
    ),
    PharmacyModel(
      id: 'ph_002',
      name: 'Аптека Пентаграф',
      address: 'ул. Граф Игнатиев 15, София',
      phone: '+359 2 987 5566',
      latitude: 42.6943,
      longitude: 23.3261,
      openHours: '08:00 – 21:00',
    ),
    PharmacyModel(
      id: 'ph_003',
      name: 'Аптека Медея',
      address: 'бул. Александър Стамболийски 22, София',
      phone: '+359 2 980 1122',
      latitude: 42.6989,
      longitude: 23.3150,
      openHours: '07:30 – 22:00',
    ),
    PharmacyModel(
      id: 'ph_004',
      name: 'Аптека Фармасист',
      address: 'ул. Раковски 128, София',
      phone: '+359 2 944 3377',
      latitude: 42.6961,
      longitude: 23.3300,
      openHours: '09:00 – 20:00',
    ),
    PharmacyModel(
      id: 'ph_005',
      name: 'Аптека Зелена',
      address: 'бул. Патриарх Евтимий 55, София',
      phone: '+359 2 963 8899',
      latitude: 42.6925,
      longitude: 23.3241,
      isOpen24h: true,
    ),
    PharmacyModel(
      id: 'ph_006',
      name: 'Аптека Хелиос',
      address: 'ул. Солунска 8, София',
      phone: '+359 2 988 6644',
      latitude: 42.7010,
      longitude: 23.3180,
      openHours: '08:00 – 21:00',
    ),
    PharmacyModel(
      id: 'ph_007',
      name: 'Аптека Надежда',
      address: 'жк Надежда, бул. Рожен 50, София',
      phone: '+359 2 832 5511',
      latitude: 42.7215,
      longitude: 23.2980,
      openHours: '08:00 – 20:00',
    ),
    PharmacyModel(
      id: 'ph_008',
      name: 'Аптека Люлин Фарм',
      address: 'жк Люлин 1, бул. Европа 12, София',
      phone: '+359 2 925 4433',
      latitude: 42.7050,
      longitude: 23.2650,
      isOpen24h: true,
    ),
    PharmacyModel(
      id: 'ph_009',
      name: 'Аптека Студентска',
      address: 'бул. Драган Цанков 5, София',
      phone: '+359 2 971 7722',
      latitude: 42.6850,
      longitude: 23.3490,
      openHours: '08:30 – 22:00',
    ),
    PharmacyModel(
      id: 'ph_010',
      name: 'Аптека Медикус',
      address: 'ул. Оборище 35, София',
      phone: '+359 2 946 1234',
      latitude: 42.7030,
      longitude: 23.3380,
      openHours: '09:00 – 21:00',
    ),
    PharmacyModel(
      id: 'ph_011',
      name: 'Аптека Биофарм',
      address: 'ул. Пиротска 66, София',
      phone: '+359 2 831 9988',
      latitude: 42.7100,
      longitude: 23.3100,
      openHours: '08:00 – 20:30',
    ),
    PharmacyModel(
      id: 'ph_012',
      name: 'Аптека Кристал',
      address: 'бул. България 102, София',
      phone: '+359 2 855 4422',
      latitude: 42.6780,
      longitude: 23.2970,
      isOpen24h: true,
    ),
    PharmacyModel(
      id: 'ph_013',
      name: 'Аптека Троя',
      address: 'жк Младост 1, ул. Андрей Сахаров 2, София',
      phone: '+359 2 974 6655',
      latitude: 42.6600,
      longitude: 23.3760,
      openHours: '08:00 – 22:00',
    ),
    PharmacyModel(
      id: 'ph_014',
      name: 'Аптека Доктор Фарм',
      address: 'ул. Г. С. Раковски 68, София',
      phone: '+359 2 989 7733',
      latitude: 42.6975,
      longitude: 23.3290,
      openHours: '09:00 – 20:00',
    ),
    PharmacyModel(
      id: 'ph_015',
      name: 'Аптека Здраве',
      address: 'бул. Сливница 150, София',
      phone: '+359 2 823 5566',
      latitude: 42.7160,
      longitude: 23.2840,
      openHours: '07:30 – 21:30',
    ),
  ];

  Future<List<PharmacyModel>> getNearbyPharmacies({int limit = 10}) async {
    final position = await _locationService.getCurrentPosition();

    if (position != null) {
      final withDistance = _allPharmacies.map((p) {
        final dist = _locationService.distanceBetween(
          position.latitude,
          position.longitude,
          p.latitude,
          p.longitude,
        );
        return p.copyWith(distanceMeters: dist);
      }).toList();

      withDistance.sort(
          (a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
      return withDistance.take(limit).toList();
    }

    // No location — return first N sorted by id
    return _allPharmacies.take(limit).toList();
  }
}
