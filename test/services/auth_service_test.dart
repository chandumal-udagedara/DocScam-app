import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doc_scam_mobile_app/services/auth_service.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseAuth>(),
  MockSpec<UserCredential>(),
  MockSpec<User>(),
])
import 'auth_service_test.mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late AuthService service;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    service = AuthService.forTesting(mockAuth);

    // Default: no existing user
    when(mockAuth.currentUser).thenReturn(null);
    when(mockAuth.authStateChanges())
        .thenAnswer((_) => const Stream<User?>.empty());
  });

  // ---------------------------------------------------------------------------
  // AuthResult.message
  // ---------------------------------------------------------------------------

  group('AuthResult.message', () {
    test('every enum value has a non-empty message', () {
      for (final result in AuthResult.values) {
        expect(result.message, isNotEmpty);
      }
    });

    test('success message is "Success"', () {
      expect(AuthResult.success.message, 'Success');
    });

    test('emailInUse has descriptive message', () {
      expect(AuthResult.emailInUse.message, contains('already registered'));
    });

    test('wrongPassword has descriptive message', () {
      expect(AuthResult.wrongPassword.message, contains('Incorrect'));
    });

    test('firebaseUnavailable has descriptive message', () {
      expect(AuthResult.firebaseUnavailable.message, contains('not available'));
    });
  });

  // ---------------------------------------------------------------------------
  // init()
  // ---------------------------------------------------------------------------

  group('init()', () {
    test('signs in anonymously when no existing user', () async {
      final mockCred = MockUserCredential();
      final mockUser = MockUser();
      when(mockUser.uid).thenReturn('anon-uid-123');
      when(mockCred.user).thenReturn(mockUser);
      when(mockAuth.signInAnonymously())
          .thenAnswer((_) async => mockCred);

      await service.init();

      verify(mockAuth.signInAnonymously()).called(1);
      expect(service.isInitialized, isTrue);
    });

    test('skips anonymous sign-in when user already exists', () async {
      final mockUser = MockUser();
      when(mockUser.uid).thenReturn('existing-uid');
      when(mockAuth.currentUser).thenReturn(mockUser);

      await service.init();

      verifyNever(mockAuth.signInAnonymously());
      expect(service.isInitialized, isTrue);
    });

    test('degrades gracefully when Firebase throws', () async {
      when(mockAuth.currentUser).thenThrow(Exception('Firebase not ready'));

      await service.init();

      expect(service.isInitialized, isFalse);
      expect(service.currentUid, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // signInWithEmail()
  // ---------------------------------------------------------------------------

  group('signInWithEmail()', () {
    test('returns success on valid credentials', () async {
      final mockCred = MockUserCredential();
      final mockUser = MockUser();
      when(mockUser.uid).thenReturn('uid-456');
      when(mockCred.user).thenReturn(mockUser);
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockCred);

      // Initialize first so _auth is set
      when(mockAuth.signInAnonymously())
          .thenAnswer((_) async => mockCred);
      await service.init();

      final result =
          await service.signInWithEmail('test@test.com', 'password123');
      expect(result, AuthResult.success);
    });

    test('maps wrong-password error correctly', () async {
      final mockCred = MockUserCredential();
      final mockUser = MockUser();
      when(mockCred.user).thenReturn(mockUser);
      when(mockAuth.signInAnonymously())
          .thenAnswer((_) async => mockCred);
      await service.init();

      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(
        code: 'wrong-password',
        message: 'Wrong password',
      ));

      final result =
          await service.signInWithEmail('test@test.com', 'bad');
      expect(result, AuthResult.wrongPassword);
    });

    test('maps user-not-found error correctly', () async {
      final mockCred = MockUserCredential();
      final mockUser = MockUser();
      when(mockCred.user).thenReturn(mockUser);
      when(mockAuth.signInAnonymously())
          .thenAnswer((_) async => mockCred);
      await service.init();

      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(
        code: 'user-not-found',
        message: 'User not found',
      ));

      final result =
          await service.signInWithEmail('nope@test.com', 'pass');
      expect(result, AuthResult.userNotFound);
    });
  });

  // ---------------------------------------------------------------------------
  // registerWithEmail()
  // ---------------------------------------------------------------------------

  group('registerWithEmail()', () {
    test('maps email-already-in-use error', () async {
      final mockCred = MockUserCredential();
      final mockUser = MockUser();
      when(mockUser.isAnonymous).thenReturn(false);
      when(mockCred.user).thenReturn(mockUser);
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockAuth.signInAnonymously())
          .thenAnswer((_) async => mockCred);
      await service.init();

      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'Email already in use',
      ));

      final result =
          await service.registerWithEmail('taken@test.com', 'pass123');
      expect(result, AuthResult.emailInUse);
    });

    test('maps weak-password error', () async {
      final mockCred = MockUserCredential();
      final mockUser = MockUser();
      when(mockUser.isAnonymous).thenReturn(false);
      when(mockCred.user).thenReturn(mockUser);
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockAuth.signInAnonymously())
          .thenAnswer((_) async => mockCred);
      await service.init();

      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(
        code: 'weak-password',
        message: 'Weak password',
      ));

      final result =
          await service.registerWithEmail('test@test.com', '12');
      expect(result, AuthResult.weakPassword);
    });

    test('returns unknown on unexpected exception', () async {
      final mockCred = MockUserCredential();
      final mockUser = MockUser();
      when(mockUser.isAnonymous).thenReturn(false);
      when(mockCred.user).thenReturn(mockUser);
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockAuth.signInAnonymously())
          .thenAnswer((_) async => mockCred);
      await service.init();

      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(Exception('Network error'));

      final result =
          await service.registerWithEmail('test@test.com', 'pass123');
      expect(result, AuthResult.unknown);
    });
  });

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  group('getters', () {
    test('isAnonymous returns true when no user', () {
      expect(service.isAnonymous, isTrue);
    });

    test('isSignedIn returns false when no user', () {
      expect(service.isSignedIn, isFalse);
    });

    test('currentUid returns null when no user', () {
      expect(service.currentUid, isNull);
    });
  });
}
