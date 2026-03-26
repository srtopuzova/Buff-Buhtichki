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
    if (!doc.exists) {
      throw Exception('User profile not found');
    }
    return UserModel.fromFirestore(doc);
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}
