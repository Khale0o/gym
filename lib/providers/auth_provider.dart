import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/models/user_profile.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(firebaseAuthProvider));
});

final currentAuthUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull ?? ref.watch(firebaseAuthProvider).currentUser;
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) {
    return Stream.value(null);
  }

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      return null;
    }
    return UserProfile.fromFirestore(doc);
  });
});

final currentGymIdProvider = Provider<String?>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.valueOrNull?.defaultGymId;
});

class AuthController {
  final FirebaseAuth _auth;

  AuthController(this._auth);

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (error) {
      return _mapSignInError(error);
    } catch (_) {
      return 'Unable to sign in right now. Please try again.';
    }
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  String _mapSignInError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Sign-in failed. Please try again.';
    }
  }
}
