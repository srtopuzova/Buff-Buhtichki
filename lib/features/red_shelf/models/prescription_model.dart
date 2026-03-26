import 'package:cloud_firestore/cloud_firestore.dart';

enum PrescriptionStatus { pending, active, completed, cancelled }

extension PrescriptionStatusExt on PrescriptionStatus {
  String get label {
    switch (this) {
      case PrescriptionStatus.pending:
        return 'Pending Pickup';
      case PrescriptionStatus.active:
        return 'Active';
      case PrescriptionStatus.completed:
        return 'Completed';
      case PrescriptionStatus.cancelled:
        return 'Cancelled';
    }
  }

  static PrescriptionStatus fromString(String s) {
    return PrescriptionStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => PrescriptionStatus.pending,
    );
  }
}

class DoseRecord {
  final DateTime timestamp;
  final bool taken;

  const DoseRecord({required this.timestamp, required this.taken});

  factory DoseRecord.fromMap(Map<String, dynamic> map) => DoseRecord(
        timestamp:
            (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        taken: map['taken'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'timestamp': Timestamp.fromDate(timestamp),
        'taken': taken,
      };
}

class PrescribedItem {
  final String name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? instructions;

  const PrescribedItem({
    required this.name,
    this.dosage,
    this.frequency,
    this.duration,
    this.instructions,
  });

  factory PrescribedItem.fromMap(Map<String, dynamic> map) => PrescribedItem(
        name: map['name'] as String? ?? '',
        dosage: map['dosage'] as String?,
        frequency: map['frequency'] as String?,
        duration: map['duration'] as String?,
        instructions: map['instructions'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'instructions': instructions,
      };
}

class PrescriptionModel {
  final String id;
  final String userId;
  final List<PrescribedItem> items;
  final String? doctorName;
  final String? patientName;
  final String? imageUrl;
  final PrescriptionStatus status;
  final List<DoseRecord> doseRecords;
  final int? reminderHour;
  final int? reminderMinute;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? pickedUpAt;

  const PrescriptionModel({
    required this.id,
    required this.userId,
    required this.items,
    this.doctorName,
    this.patientName,
    this.imageUrl,
    required this.status,
    required this.doseRecords,
    this.reminderHour,
    this.reminderMinute,
    required this.createdAt,
    required this.updatedAt,
    this.pickedUpAt,
  });

  // Convenience getters — used by PrescriptionCard, DoseTracker, PrescriptionService
  String get title => items.isEmpty
      ? 'Prescription'
      : items.length == 1
          ? items[0].name
          : '${items[0].name} (+${items.length - 1} more)';

  String get medicationName => title;
  String? get dosage => items.isEmpty ? null : items[0].dosage;
  String? get frequency => items.isEmpty ? null : items[0].frequency;
  String? get instructions => items.isEmpty ? null : items[0].instructions;

  bool get isPending => status == PrescriptionStatus.pending;
  bool get isActive => status == PrescriptionStatus.active;

  int get dosesToday {
    final today = DateTime.now();
    return doseRecords
        .where((d) =>
            d.taken &&
            d.timestamp.year == today.year &&
            d.timestamp.month == today.month &&
            d.timestamp.day == today.day)
        .length;
  }

  factory PrescriptionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawDoses = d['doseRecords'] as List<dynamic>? ?? [];

    // Parse items (new format) or fall back to legacy single-medication fields
    List<PrescribedItem> items;
    if (d['items'] != null) {
      items = (d['items'] as List<dynamic>)
          .map((i) => PrescribedItem.fromMap(i as Map<String, dynamic>))
          .toList();
    } else {
      final name = d['medicationName'] as String? ?? '';
      items = name.isNotEmpty
          ? [
              PrescribedItem(
                name: name,
                dosage: d['dosage'] as String?,
                frequency: d['frequency'] as String?,
                duration: d['duration'] as String?,
                instructions: d['instructions'] as String?,
              )
            ]
          : [];
    }

    return PrescriptionModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      items: items,
      doctorName: d['doctorName'] as String?,
      patientName: d['patientName'] as String?,
      imageUrl: d['imageUrl'] as String?,
      status: PrescriptionStatusExt.fromString(
          d['status'] as String? ?? 'pending'),
      doseRecords: rawDoses
          .map((r) => DoseRecord.fromMap(r as Map<String, dynamic>))
          .toList(),
      reminderHour: (d['reminderHour'] as num?)?.toInt(),
      reminderMinute: (d['reminderMinute'] as num?)?.toInt(),
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pickedUpAt: (d['pickedUpAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'items': items.map((i) => i.toMap()).toList(),
        'doctorName': doctorName,
        'patientName': patientName,
        'imageUrl': imageUrl,
        'status': status.name,
        'doseRecords': doseRecords.map((d) => d.toMap()).toList(),
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'pickedUpAt':
            pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      };

  PrescriptionModel copyWith({
    String? id,
    String? userId,
    List<PrescribedItem>? items,
    String? doctorName,
    String? patientName,
    String? imageUrl,
    PrescriptionStatus? status,
    List<DoseRecord>? doseRecords,
    int? reminderHour,
    int? reminderMinute,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? pickedUpAt,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      doseRecords: doseRecords ?? this.doseRecords,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
    );
  }
}
