import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:medshelf/core/constants/app_constants.dart';
import 'package:medshelf/features/med_shelf/models/medication_model.dart';
import 'package:medshelf/shared/services/notification_service.dart';

class MedicationService {
  static final MedicationService _instance = MedicationService._internal();
  factory MedicationService() => _instance;
  MedicationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();
  final _notifications = NotificationService();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.medicationsCollection);

  Query<Map<String, dynamic>> _userQuery(String userId) =>
      _col.where('userId', isEqualTo: userId);

  Stream<List<MedicationModel>> watchMedications(String userId) {
    return _userQuery(userId).snapshots().map((snap) {
      final list =
          snap.docs.map((d) => MedicationModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<List<MedicationModel>> getMedications(String userId) async {
    final snap = await _userQuery(userId).get();
    final list =
        snap.docs.map((d) => MedicationModel.fromFirestore(d)).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<MedicationModel> addMedication({
    required String userId,
    required MedicationModel medication,
    File? imageFile,
  }) async {
    final id = _uuid.v4();
    String? imageUrl;

    if (imageFile != null) {
      try {
        imageUrl = await _uploadImage(imageFile, id);
      } catch (e) {
        debugPrint('Image upload skipped: $e');
      }
    }

    final now = DateTime.now();
    final med = medication.copyWith(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      createdAt: now,
      updatedAt: now,
    );

    await _col.doc(id).set(med.toFirestore());

    for (final batch in med.batches) {
      await _notifications.scheduleExpiryNotificationsForBatch(
        batchId: batch.id,
        medicationName: med.name,
        expiryDate: batch.expiryDate,
      );
    }

    return med;
  }

  Future<void> updateMedication(MedicationModel medication,
      {File? imageFile}) async {
    String? imageUrl = medication.imageUrl;

    if (imageFile != null) {
      try {
        imageUrl = await _uploadImage(imageFile, medication.id);
      } catch (e) {
        debugPrint('Image upload skipped: $e');
      }
    }

    final updated = medication.copyWith(
      imageUrl: imageUrl,
      updatedAt: DateTime.now(),
    );

    await _col.doc(medication.id).update(updated.toFirestore());

    for (final batch in updated.batches) {
      await _notifications.scheduleExpiryNotificationsForBatch(
        batchId: batch.id,
        medicationName: updated.name,
        expiryDate: batch.expiryDate,
      );
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    // Cancel notifications for all batches before deleting
    try {
      final doc = await _col.doc(medicationId).get();
      if (doc.exists) {
        final med = MedicationModel.fromFirestore(doc);
        for (final batch in med.batches) {
          await _notifications.cancelExpiryNotificationsForBatch(batch.id);
        }
      }
    } catch (_) {}

    await _col.doc(medicationId).delete();

    try {
      await _storage
          .ref('${AppConstants.medicationImagesPath}/$medicationId.jpg')
          .delete();
    } catch (_) {}
  }

  /// Add a new box to an existing medication entry.
  Future<void> addBatch({
    required String medicationId,
    required MedicationBatch batch,
    required String medicationName,
  }) async {
    final doc = await _col.doc(medicationId).get();
    if (!doc.exists) return;

    final med = MedicationModel.fromFirestore(doc);
    final updatedBatches = [...med.batches, batch];

    await _col.doc(medicationId).update({
      'batches': updatedBatches.map((b) => b.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _notifications.scheduleExpiryNotificationsForBatch(
      batchId: batch.id,
      medicationName: medicationName,
      expiryDate: batch.expiryDate,
    );
  }

  /// Remove a box from an existing medication entry.
  Future<void> removeBatch({
    required String medicationId,
    required String batchId,
    required List<MedicationBatch> currentBatches,
  }) async {
    final updatedBatches =
        currentBatches.where((b) => b.id != batchId).toList();

    await _col.doc(medicationId).update({
      'batches': updatedBatches.map((b) => b.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _notifications.cancelExpiryNotificationsForBatch(batchId);
  }

  Future<String> _uploadImage(File imageFile, String id) async {
    final ref = _storage.ref('${AppConstants.medicationImagesPath}/$id.jpg');
    final task = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }
}
