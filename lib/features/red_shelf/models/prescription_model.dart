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

class PrescriptionModel {
  final String id;
  final String userId;
  final String medicationName;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? doctorName;
  final String? patientName;
  final String? instructions;
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
    required this.medicationName,
    this.dosage,
    this.frequency,
    this.duration,
    this.doctorName,
    this.patientName,
    this.instructions,
    this.imageUrl,
    required this.status,
    required this.doseRecords,
    this.reminderHour,
    this.reminderMinute,
    required this.createdAt,
    required this.updatedAt,
    this.pickedUpAt,
  });

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
    return PrescriptionModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      medicationName: d['medicationName'] as String? ?? '',
      dosage: d['dosage'] as String?,
      frequency: d['frequency'] as String?,
      duration: d['duration'] as String?,
      doctorName: d['doctorName'] as String?,
      patientName: d['patientName'] as String?,
      instructions: d['instructions'] as String?,
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
        'medicationName': medicationName,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'doctorName': doctorName,
        'patientName': patientName,
        'instructions': instructions,
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
    String? medicationName,
    String? dosage,
    String? frequency,
    String? duration,
    String? doctorName,
    String? patientName,
    String? instructions,
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
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
      instructions: instructions ?? this.instructions,
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