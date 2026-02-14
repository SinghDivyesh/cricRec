// lib/core/utils/auth_error_handler.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  /// Convert FirebaseAuthException to user-friendly error messages
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
    // ================= LOGIN ERRORS =================
      case 'user-not-found':
        return 'No account found with this email address';

      case 'wrong-password':
        return 'Incorrect password. Please try again';

      case 'invalid-email':
        return 'Please enter a valid email address';

      case 'user-disabled':
        return 'This account has been disabled';

      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';

    // ================= SIGNUP ERRORS =================
      case 'email-already-in-use':
        return 'An account already exists with this email';

      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';

      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';

    // ================= NETWORK ERRORS =================
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';

    // ================= OTHER ERRORS =================
      case 'invalid-credential':
        return 'Invalid email or password';

      case 'account-exists-with-different-credential':
        return 'An account exists with the same email but different sign-in method';

      case 'requires-recent-login':
        return 'Please log in again to complete this action';

      default:
        return e.message ?? 'Authentication failed. Please try again';
    }
  }

  /// Check if error is recoverable (user can retry)
  static bool isRecoverable(FirebaseAuthException e) {
    const recoverableErrors = [
      'network-request-failed',
      'too-many-requests',
      'wrong-password',
      'invalid-credential',
    ];

    return recoverableErrors.contains(e.code);
  }

  /// Get action suggestion based on error
  static String? getActionSuggestion(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Would you like to create a new account?';

      case 'email-already-in-use':
        return 'Try logging in instead';

      case 'weak-password':
        return 'Use a combination of letters, numbers, and symbols';

      case 'network-request-failed':
        return 'Check your internet connection and try again';

      case 'too-many-requests':
        return 'Wait a few minutes before trying again';

      default:
        return null;
    }
  }
}
