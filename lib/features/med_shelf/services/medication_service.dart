import 'dart:io';
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

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore.collection(AppConstants.medicationsCollection);

  Query<Map<String, dynamic>> _userQuery(String userId) =>
      _col(userId).where('userId', isEqualTo: userId).orderBy('name');

  Stream<List<MedicationModel>> watchMedications(String userId) {
    return _userQuery(userId).snapshots().map(
          (snap) =>
              snap.docs.map((d) => MedicationModel.fromFirestore(d)).toList(),
        );
  }

  Future<List<MedicationModel>> getMedications(String userId) async {
    final snap = await _userQuery(userId).get();
    return snap.docs.map((d) => MedicationModel.fromFirestore(d)).toList();
  }

  Future<MedicationModel> addMedication({
    required String userId,
    required MedicationModel medication,
    File? imageFile,
  }) async {
    final id = _uuid.v4();
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, id);
    }

    final now = DateTime.now();
    final med = medication.copyWith(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(AppConstants.medicationsCollection)
        .doc(id)
        .set(med.toFirestore());

    await _notifications.scheduleExpiryNotifications(
      medicationId: id,
      medicationName: med.name,
      expiryDate: med.expiryDate,
    );

    return med;
  }

  Future<void> updateMedication(MedicationModel medication,
      {File? imageFile}) async {
    String? imageUrl = medication.imageUrl;

    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, medication.id);
    }

    final updated = medication.copyWith(
      imageUrl: imageUrl,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.medicationsCollection)
        .doc(medication.id)
        .update(updated.toFirestore());

    await _notifications.scheduleExpiryNotifications(
      medicationId: medication.id,
      medicationName: updated.name,
      expiryDate: updated.expiryDate,
    );
  }

  Future<void> updateQuantity(String medicationId, int newQuantity) async {
    await _firestore
        .collection(AppConstants.medicationsCollection)
        .doc(medicationId)
        .update({
      'quantity': newQuantity,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteMedication(String medicationId) async {
    await _notifications.cancelExpiryNotifications(medicationId);
    await _firestore
        .collection(AppConstants.medicationsCollection)
        .doc(medicationId)
        .delete();
    // Attempt to delete image
    try {
      await _storage
          .ref('${AppConstants.medicationImagesPath}/$medicationId.jpg')
          .delete();
    } catch (_) {}
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
