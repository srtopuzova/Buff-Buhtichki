import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medshelf/core/constants/app_constants.dart';
import 'package:medshelf/features/auth/models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signUp({
    required String email,
    required String username,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    final userModel = UserModel(
      uid: user.uid,
      email: email.trim(),
      username: username.trim(),
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toFirestore());

    await user.updateDisplayName(username.trim());
    return userModel;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update({'lastLoginAt': Timestamp.fromDate(DateTime.now())});

    return await getUserModel(user.uid);
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserModel> getUserModel(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    final authUser = _auth.currentUser;
    final fallbackUsername = authUser?.displayName?.trim().isNotEmpty == true
        ? authUser!.displayName!.trim()
        : authUser?.email?.split('@').first ?? 'User';

    if (doc.exists) {
      final model = UserModel.fromFirestore(doc);
      // Fix empty username if it wasn't saved during signup
      if (model.username.trim().isEmpty) {
        final fixed = model.copyWith(username: fallbackUsername);
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({'username': fallbackUsername});
        return fixed;
      }
      return model;
    }

    // Document missing — create it from Firebase Auth data
    final userModel = UserModel(
      uid: uid,
      email: authUser?.email ?? '',
      username: fallbackUsername,
      createdAt: authUser?.metadata.creationTime ?? DateTime.now(),
    );
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(userModel.toFirestore());
    return userModel;
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}
