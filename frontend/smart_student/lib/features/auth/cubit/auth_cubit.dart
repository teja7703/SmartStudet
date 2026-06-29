import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final user = await _repository.getStoredUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
        // Refresh from the backend so points/streak/photo are current.
        final fresh = await _repository.refreshCurrentUser();
        if (fresh != null && !isClosed) emit(AuthAuthenticated(fresh));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await _repository.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      final message = e.toString().contains('cancelled')
          ? 'Sign in was cancelled'
          : 'Failed to sign in. Please try again.';
      emit(AuthError(message));
      emit(AuthUnauthenticated());
    }
  }

  /// Sends an OTP to [phoneNumber] (full E.164 format, e.g. +9198XXXXXXXX).
  Future<void> sendOtp(String phoneNumber, {int? resendToken}) async {
    emit(AuthOtpInProgress(phoneNumber: phoneNumber));
    try {
      await _repository.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        resendToken: resendToken,
        onCodeSent: (verificationId, token) {
          emit(AuthCodeSent(
            verificationId: verificationId,
            phoneNumber: phoneNumber,
            resendToken: token,
          ));
        },
        onAutoVerified: (user) => emit(AuthAuthenticated(user)),
        onFailed: (message) {
          emit(AuthError(message));
          emit(AuthUnauthenticated());
        },
      );
    } catch (e) {
      emit(const AuthError('Could not send OTP. Please try again.'));
      emit(AuthUnauthenticated());
    }
  }

  /// Verifies the [smsCode] for a previously sent OTP.
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
    int? resendToken,
  }) async {
    emit(AuthOtpInProgress(
      verificationId: verificationId,
      phoneNumber: phoneNumber,
    ));
    try {
      final user = await _repository.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
        phoneNumber: phoneNumber,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(const AuthError('Invalid or expired OTP. Please try again.'));
      // Stay on the OTP step so the user can retry.
      emit(AuthCodeSent(
        verificationId: verificationId,
        phoneNumber: phoneNumber,
        resendToken: resendToken,
      ));
    }
  }

  /// Returns to the phone-entry step.
  void resetToPhoneEntry() {
    emit(AuthUnauthenticated());
  }

  /// Updates the signed-in user's name/photo and refreshes the auth state.
  Future<void> updateProfile({
    required String name,
    required String photoUrl,
  }) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    final updated = await _repository.updateProfile(
      firebaseUid: current.user.firebaseUid,
      name: name,
      photoUrl: photoUrl,
    );
    emit(AuthAuthenticated(updated));
  }

  Future<void> signOut() async {
    await _repository.signOut();
    emit(AuthUnauthenticated());
  }
}
