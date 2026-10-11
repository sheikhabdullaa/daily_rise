import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// LOGIN
  Future<String?> login(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = credential.user;

      if (user == null) {
        await _auth.signOut();
        return 'Login failed. Please try again.';
      }

      await user.reload();
      user = _auth.currentUser;

      if (user == null) {
        await _auth.signOut();
        return 'Login failed. Please try again.';
      }

      // Require email verification before entering the app.
      if (!user.emailVerified) {
        await _auth.signOut();
        return 'Please verify your email first. Check your inbox and spam folder.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email. Please sign up first.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return e.message ?? 'Login failed.';
      }
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  /// SIGN UP
  Future<String?> signup(String email, String password, String name) async {
    UserCredential credential;

    // STEP 1: Create Firebase Authentication account.
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Please log in.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Please choose a stronger password.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return e.message ?? 'Account creation failed.';
      }
    } catch (e) {
      return 'Account creation failed: $e';
    }

    final User? user = credential.user;

    if (user == null) {
      return 'Account could not be created. Please try again.';
    }

    // STEP 2: Save user profile in Firestore.
    try {
      await user.updateDisplayName(name.trim());

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'displayName': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // The Firebase Auth account already exists.
      // Return the real Firestore/profile error for debugging.
      return 'Account created, but profile saving failed: $e';
    }

    // STEP 3: Send email verification link.
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      return 'Account created, but verification email failed: '
          '${e.message ?? e.code}';
    } catch (e) {
      return 'Account created, but verification email failed: $e';
    }

    // Keep the user signed in so VerifyEmailScreen can check
    // the verification status and resend the verification email.
    return null;
  }

  /// CHECK EMAIL VERIFICATION
  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    await user.reload();
    user = _auth.currentUser;

    return user?.emailVerified ?? false;
  }

  /// RESEND VERIFICATION EMAIL
  Future<String?> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        return 'No active signup session. Please log in again.';
      }

      await user.reload();
      user = _auth.currentUser;

      if (user == null) {
        return 'Your session has expired. Please try again.';
      }

      if (user.emailVerified) {
        return 'Your email is already verified.';
      }

      await user.sendEmailVerification();

      return 'Verification email sent. Please check your inbox and spam folder.';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'too-many-requests':
          return 'Too many requests. Please wait before trying again.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return e.message ?? 'Could not send verification email.';
      }
    } catch (e) {
      return 'Could not send verification email: $e';
    }
  }

  /// FORGOT PASSWORD
  Future<String?> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      return 'Password reset email sent.';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return e.message ?? 'Could not send password reset email.';
      }
    } catch (e) {
      return 'Something went wrong: $e';
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
