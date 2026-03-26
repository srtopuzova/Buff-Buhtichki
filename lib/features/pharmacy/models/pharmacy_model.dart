class PharmacyModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final bool isOpen24h;
  final String? openHours;
  double? distanceMeters;

  PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.isOpen24h = false,
    this.openHours,
    this.distanceMeters,
  });

  PharmacyModel copyWith({double? distanceMeters}) {
    return PharmacyModel(
      id: id,
      name: name,
      address: address,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
      isOpen24h: isOpen24h,
      openHours: openHours,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}
