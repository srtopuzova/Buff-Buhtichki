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

/// One physical box / unit with its own expiry date and quantity.
class MedicationBatch {
  final String id;
  final DateTime expiryDate;
  final int quantity;

  const MedicationBatch({
    required this.id,
    required this.expiryDate,
    required this.quantity,
  });

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expDay =
        DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expDay.difference(today).inDays;
  }

  bool get isExpired => daysUntilExpiry < 0;

  factory MedicationBatch.fromMap(Map<String, dynamic> map) => MedicationBatch(
        id: map['id'] as String? ?? '',
        expiryDate:
            (map['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'quantity': quantity,
      };

  MedicationBatch copyWith({DateTime? expiryDate, int? quantity}) =>
      MedicationBatch(
        id: id,
        expiryDate: expiryDate ?? this.expiryDate,
        quantity: quantity ?? this.quantity,
      );
}

class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final String? activeSubstance;
  final String? dosage;
  final String? manufacturer;
  /// Usage / indications extracted from the back of the box at scan time.
  final String? indications;
  final List<MedicationBatch> batches;
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
    this.indications,
    required this.batches,
    this.category = MedicationCategory.other,
    this.imageUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Computed from batches ────────────────────────────────────────────────

  /// Earliest expiry across all boxes (used for list sorting & card display).
  DateTime get expiryDate {
    if (batches.isEmpty) return DateTime.now();
    return batches
        .map((b) => b.expiryDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Total units across all boxes.
  int get quantity => batches.fold(0, (sum, b) => sum + b.quantity);

  /// True only when every box is expired.
  bool get isExpired =>
      batches.isEmpty || batches.every((b) => b.isExpired);

  /// Days until the soonest-expiring box.
  int get daysUntilExpiry {
    if (batches.isEmpty) return 0;
    return batches
        .map((b) => b.daysUntilExpiry)
        .reduce((a, b) => a < b ? a : b);
  }

  /// True when any non-expired box expires within 30 days.
  bool get isExpiringSoon =>
      !isExpired &&
      batches.any((b) => !b.isExpired && b.daysUntilExpiry <= 30);

  // ── Firestore ────────────────────────────────────────────────────────────

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    List<MedicationBatch> batches;
    if (d['batches'] != null) {
      batches = (d['batches'] as List)
          .map((b) => MedicationBatch.fromMap(b as Map<String, dynamic>))
          .toList();
    } else {
      // Backward compat: old flat format
      batches = [
        MedicationBatch(
          id: '${doc.id}_0',
          expiryDate:
              (d['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          quantity: (d['quantity'] as num?)?.toInt() ?? 0,
        ),
      ];
    }

    return MedicationModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      activeSubstance: d['activeSubstance'] as String?,
      dosage: d['dosage'] as String?,
      manufacturer: d['manufacturer'] as String?,
      indications: d['indications'] as String?,
      batches: batches,
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
        'indications': indications,
        'batches': batches.map((b) => b.toMap()).toList(),
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
    String? indications,
    List<MedicationBatch>? batches,
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
      indications: indications ?? this.indications,
      batches: batches ?? this.batches,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
