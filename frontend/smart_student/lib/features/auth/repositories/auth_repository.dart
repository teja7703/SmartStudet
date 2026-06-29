import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required ApiClient apiClient,
    required StorageService storageService,
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _apiClient = apiClient,
       _storageService = storageService,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  Future<UserModel?> getStoredUser() async {
    final data = await _storageService.getUser();
    if (data == null) return null;
    final user = UserModel.fromJson(data);
    // Scope the local cache to this user as early as possible.
    _storageService.setActiveUser(user.firebaseUid);
    return user;
  }

  /// Re-fetches the signed-in user from the backend so points, streak and a
  /// refreshed photo are always current after login / app start.
  Future<UserModel?> refreshCurrentUser() async {
    try {
      final response = await _apiClient.get('/api/auth/me');
      final user = UserModel.fromJson(response.data['data']);
      _storageService.setActiveUser(user.firebaseUid);
      await _storageService.saveUser(user.toJson());
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return _signInWithFirebaseCredential(credential);
    } catch (e) {
      print('GOOGLE SIGN IN ERROR => $e');
      rethrow;
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(UserModel user) onAutoVerified,
    required void Function(String message) onFailed,
    int? resendToken,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final user = await _signInWithFirebaseCredential(
            credential,
            phoneNumber: phoneNumber,
          );

          onAutoVerified(user);
        } catch (e) {
          print('AUTO VERIFY ERROR => $e');
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        onFailed(_phoneErrorMessage(e));
      },

      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      return _signInWithFirebaseCredential(
        credential,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      print('OTP VERIFY ERROR => $e');
      rethrow;
    }
  }

  Future<UserModel> _signInWithFirebaseCredential(
    AuthCredential credential, {
    String? phoneNumber,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final user = userCredential.user!;

      final response = await _apiClient.post(
        '/api/auth/login',
        data: {
          'firebaseUid': user.uid,
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? phoneNumber ?? '',
          'name': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
        },
      );

      final userModel = UserModel.fromJson(response.data['data']);

      // Scope all local cache to this user before anything reads it.
      _storageService.setActiveUser(userModel.firebaseUid);
      await _storageService.saveUser(userModel.toJson());

      return userModel;
    } catch (_) {
      rethrow;
    }
  }

  String _phoneErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'quota-exceeded':
        return 'SMS limit reached. Please try again later.';

      default:
        return e.message ?? 'Phone verification failed. Please try again.';
    }
  }

  Future<UserModel> updateProfile({
    required String firebaseUid,
    required String name,
    required String photoUrl,
  }) async {
    final response = await _apiClient.put(
      '/api/auth/profile',
      data: {'firebaseUid': firebaseUid, 'name': name, 'photoUrl': photoUrl},
    );

    final userModel = UserModel.fromJson(response.data['data']);

    await _storageService.saveUser(userModel.toJson());

    return userModel;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    // Wipe the signed-out user's entire local cache so the next account that
    // logs in on this device starts completely clean.
    await _storageService.clearActiveUserCache();
    _storageService.setActiveUser('');
  }
}
