import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medshelf/features/auth/models/user_model.dart';
import 'package:medshelf/features/auth/services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _userModel;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get userModel => _userModel;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _userModel = null;
    } else {
      try {
        _userModel = await _authService.getUserModel(user.uid);
        _status = AuthStatus.authenticated;
      } catch (_) {
        _status = AuthStatus.authenticated;
        _userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          username: user.displayName ?? 'User',
          createdAt: DateTime.now(),
        );
      }
    }
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _userModel = await _authService.signUp(
        email: email,
        username: username,
        password: password,
      );
      _status = AuthStatus.authenticated;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _userModel = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    _userModel = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
