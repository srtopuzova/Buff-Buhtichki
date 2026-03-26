import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:medshelf/core/constants/app_constants.dart';
import 'package:medshelf/features/red_shelf/models/prescription_model.dart';
import 'package:medshelf/shared/services/notification_service.dart';

class PrescriptionService {
  static final PrescriptionService _instance =
      PrescriptionService._internal();
  factory PrescriptionService() => _instance;
  PrescriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();
  final _notifications = NotificationService();

  Stream<List<PrescriptionModel>> watchPrescriptions(String userId) {
    return _firestore
        .collection(AppConstants.prescriptionsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => PrescriptionModel.fromFirestore(d))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<PrescriptionModel> addPrescription({
    required String userId,
    required PrescriptionModel prescription,
    File? imageFile,
  }) async {
    final id = _uuid.v4();
    String? imageUrl;

    if (imageFile != null) {
      try {
        imageUrl = await _uploadImage(imageFile, id);
      } catch (e) {
        // Storage not configured — save without image
      }
    }

    final now = DateTime.now();
    final rx = prescription.copyWith(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(AppConstants.prescriptionsCollection)
        .doc(id)
        .set(rx.toFirestore());

    if (rx.isActive &&
        rx.reminderHour != null &&
        rx.reminderMinute != null) {
      await _notifications.scheduleDoseReminder(
        prescriptionId: id,
        medicationName: rx.medicationName,
        hour: rx.reminderHour!,
        minute: rx.reminderMinute!,
        instructions: rx.instructions,
      );
    }

    return rx;
  }

  Future<void> updatePrescription(PrescriptionModel prescription,
      {File? imageFile}) async {
    String? imageUrl = prescription.imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, prescription.id);
    }

    final updated = prescription.copyWith(
      imageUrl: imageUrl,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.prescriptionsCollection)
        .doc(prescription.id)
        .update(updated.toFirestore());

    if (updated.isActive &&
        updated.reminderHour != null &&
        updated.reminderMinute != null) {
      await _notifications.scheduleDoseReminder(
        prescriptionId: updated.id,
        medicationName: updated.medicationName,
        hour: updated.reminderHour!,
        minute: updated.reminderMinute!,
        instructions: updated.instructions,
      );
    } else {
      await _notifications.cancelDoseReminder(prescription.id);
    }
  }

  Future<void> markPickedUp(String prescriptionId) async {
    await _firestore
        .collection(AppConstants.prescriptionsCollection)
        .doc(prescriptionId)
        .update({
      'status': PrescriptionStatus.active.name,
      'pickedUpAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> recordDose(String prescriptionId, bool taken) async {
    final record = DoseRecord(timestamp: DateTime.now(), taken: taken);
    await _firestore
        .collection(AppConstants.prescriptionsCollection)
        .doc(prescriptionId)
        .update({
      'doseRecords': FieldValue.arrayUnion([record.toMap()]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deletePrescription(String prescriptionId) async {
    await _notifications.cancelDoseReminder(prescriptionId);
    await _firestore
        .collection(AppConstants.prescriptionsCollection)
        .doc(prescriptionId)
        .delete();
    try {
      await _storage
          .ref('${AppConstants.prescriptionImagesPath}/$prescriptionId.jpg')
          .delete();
    } catch (_) {}
  }

  Future<String> _uploadImage(File imageFile, String id) async {
    final ref = _storage
        .ref('${AppConstants.prescriptionImagesPath}/$id.jpg');
    final task = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }
}