import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Manages Firebase Authentication.
///
/// Strategy:
///   • Anonymous sign-in happens automatically on first launch.
///     This gives every user a persistent UID without requiring registration.
///   • Users can optionally upgrade to email/password to retain progress
///     across reinstalls and devices.
///   • If Firebase is not configured the service degrades gracefully and
///     [currentUid] returns null.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Test-only constructor that accepts a pre-configured [FirebaseAuth].
  @visibleForTesting
  AuthService.forTesting(FirebaseAuth auth)
      : _auth = auth,
        _user = null,
        _initialized = false;

  FirebaseAuth? _auth;
  User? _user;
  bool _initialized = false;

  // ── Rate limiting ─────────────────────────────────────────────────────────
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 2);
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  User? get currentUser => _user;
  String? get currentUid => _user?.uid;
  bool get isSignedIn => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? true;
  bool get isInitialized => _initialized;

  /// Whether sign-in is currently blocked due to too many failed attempts.
  bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  /// Seconds remaining until lockout expires, or 0 if not locked out.
  int get lockoutSecondsRemaining => isLockedOut
      ? _lockoutUntil!.difference(DateTime.now()).inSeconds
      : 0;

  /// Call once after Firebase.initializeApp() succeeds.
  Future<void> init() async {
    try {
      _auth ??= FirebaseAuth.instance;
      _user = _auth!.currentUser;

      // Sign in anonymously if no existing session.
      if (_user == null) {
        final result = await _auth!.signInAnonymously();
        _user = result.user;
      }

      _auth!.authStateChanges().listen((user) {
        _user = user;
        notifyListeners();
      });

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[Auth] init failed: $e');
    }
  }

  /// Register with email and password.
  /// Tries to link an anonymous account first to preserve existing progress.
  Future<AuthResult> registerWithEmail(String email, String password) async {
    if (_auth == null) return AuthResult.firebaseUnavailable;
    try {
      final credential =
          EmailAuthProvider.credential(email: email, password: password);

      if (_user != null && _user!.isAnonymous) {
        // Link anonymous account → preserves local progress UID.
        await _user!.linkWithCredential(credential);
      } else {
        await _auth!.createUserWithEmailAndPassword(
            email: email, password: password);
      }
      _user = _auth!.currentUser;
      notifyListeners();
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code);
    } catch (e) {
      debugPrint('[Auth] register failed: $e');
      return AuthResult.unknown;
    }
  }

  /// Sign in with email and password.
  /// Returns [AuthResult.rateLimited] after [_maxAttempts] consecutive
  /// failures. The lockout lasts [_lockoutDuration] and then resets.
  Future<AuthResult> signInWithEmail(String email, String password) async {
    if (_auth == null) return AuthResult.firebaseUnavailable;
    if (isLockedOut) return AuthResult.rateLimited;

    try {
      await _auth!.signInWithEmailAndPassword(
          email: email, password: password);
      _user = _auth!.currentUser;
      _failedAttempts = 0;
      _lockoutUntil = null;
      notifyListeners();
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _lockoutUntil = DateTime.now().add(_lockoutDuration);
        _failedAttempts = 0;
      }
      return _mapFirebaseError(e.code);
    } catch (e) {
      debugPrint('[Auth] sign-in failed: $e');
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _lockoutUntil = DateTime.now().add(_lockoutDuration);
        _failedAttempts = 0;
      }
      return AuthResult.unknown;
    }
  }

  /// Sign out and immediately sign back in anonymously.
  Future<void> signOut() async {
    if (_auth == null) return;
    try {
      await _auth!.signOut();
      final result = await _auth!.signInAnonymously();
      _user = result.user;
      notifyListeners();
    } catch (e) {
      debugPrint('[Auth] sign-out failed: $e');
    }
  }

  AuthResult _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return AuthResult.emailInUse;
      case 'invalid-email':
        return AuthResult.invalidEmail;
      case 'wrong-password':
      case 'invalid-credential':
        return AuthResult.wrongPassword;
      case 'user-not-found':
        return AuthResult.userNotFound;
      case 'weak-password':
        return AuthResult.weakPassword;
      default:
        return AuthResult.unknown;
    }
  }
}

enum AuthResult {
  success,
  emailInUse,
  invalidEmail,
  wrongPassword,
  userNotFound,
  weakPassword,
  firebaseUnavailable,
  rateLimited,
  unknown;

  String get message {
    switch (this) {
      case AuthResult.success:
        return 'Success';
      case AuthResult.emailInUse:
        return 'That email is already registered.';
      case AuthResult.invalidEmail:
        return 'Please enter a valid email address.';
      case AuthResult.wrongPassword:
        return 'Incorrect email or password.';
      case AuthResult.userNotFound:
        return 'No account found with that email.';
      case AuthResult.weakPassword:
        return 'Password must be at least 6 characters.';
      case AuthResult.firebaseUnavailable:
        return 'Accounts are not available right now.';
      case AuthResult.rateLimited:
        return 'Too many failed attempts. Please try again later.';
      case AuthResult.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
}
