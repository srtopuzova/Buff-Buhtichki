import 'package:cloud_firestore/cloud_firestore.dart';

enum MedicationCategory {
  tablet,
  capsule,
  syrup,
  injection,
  cream,
  drops,
  inhaler,
  patch,
  other,
}

extension MedicationCategoryExt on MedicationCategory {
  String get label {
    switch (this) {
      case MedicationCategory.tablet:
        return 'Tablet';
      case MedicationCategory.capsule:
        return 'Capsule';
      case MedicationCategory.syrup:
        return 'Syrup';
      case MedicationCategory.injection:
        return 'Injection';
      case MedicationCategory.cream:
        return 'Cream';
      case MedicationCategory.drops:
        return 'Drops';
      case MedicationCategory.inhaler:
        return 'Inhaler';
      case MedicationCategory.patch:
        return 'Patch';
      case MedicationCategory.other:
        return 'Other';
    }
  }

  static MedicationCategory fromString(String s) {
    return MedicationCategory.values.firstWhere(
      (e) => e.name == s,
      orElse: () => MedicationCategory.other,
    );
  }
}

class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final String? activeSubstance;
  final String? dosage;
  final String? manufacturer;
  final DateTime expiryDate;
  final int quantity;
  final MedicationCategory category;
  final String? imageUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    this.activeSubstance,
    this.dosage,
    this.manufacturer,
    required this.expiryDate,
    required this.quantity,
    this.category = MedicationCategory.other,
    this.imageUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired =>
      DateTime(expiryDate.year, expiryDate.month, expiryDate.day)
          .isBefore(DateTime.now());

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expDay.difference(today).inDays;
  }

  bool get isExpiringSoon => daysUntilExpiry >= 0 && daysUntilExpiry <= 30;

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MedicationModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      activeSubstance: d['activeSubstance'] as String?,
      dosage: d['dosage'] as String?,
      manufacturer: d['manufacturer'] as String?,
      expiryDate: (d['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quantity: (d['quantity'] as num?)?.toInt() ?? 0,
      category:
          MedicationCategoryExt.fromString(d['category'] as String? ?? 'other'),
      imageUrl: d['imageUrl'] as String?,
      notes: d['notes'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'activeSubstance': activeSubstance,
        'dosage': dosage,
        'manufacturer': manufacturer,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'quantity': quantity,
        'category': category.name,
        'imageUrl': imageUrl,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  MedicationModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? activeSubstance,
    String? dosage,
    String? manufacturer,
    DateTime? expiryDate,
    int? quantity,
    MedicationCategory? category,
    String? imageUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      activeSubstance: activeSubstance ?? this.activeSubstance,
      dosage: dosage ?? this.dosage,
      manufacturer: manufacturer ?? this.manufacturer,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
