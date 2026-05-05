import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/repositories/member_invite_repository.dart';
import 'package:gymsaas/repositories/staff_invite_repository.dart';

final staffInviteSignupControllerProvider =
    Provider<StaffInviteSignupController>((ref) {
  return StaffInviteSignupController(
    auth: ref.watch(firebaseAuthProvider),
    staffInvites: ref.watch(staffInviteRepositoryProvider),
    memberInvites: ref.watch(memberInviteRepositoryProvider),
  );
});

class StaffInviteSignupController {
  StaffInviteSignupController({
    required FirebaseAuth auth,
    required StaffInviteRepository staffInvites,
    required MemberInviteRepository memberInvites,
  })  : _auth = auth,
        _staffInvites = staffInvites,
        _memberInvites = memberInvites;

  final FirebaseAuth _auth;
  final StaffInviteRepository _staffInvites;
  final MemberInviteRepository _memberInvites;

  Future<String?> signUpAndClaimStaffInvite({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    User? createdUser;
    final normalizedEmail = email.trim().toLowerCase();
    final localValidationError = _validateBeforeAuthCreate(
      fullName: fullName,
      email: normalizedEmail,
      password: password,
    );
    if (localValidationError != null) {
      return localValidationError;
    }

    final oldUser = _auth.currentUser;
    _debugLog('Old currentUser before signup starts: ${oldUser?.uid ?? 'none'}');

    try {
      if (oldUser != null) {
        _debugLog('Signing out old currentUser before invite signup.');
        await _auth.signOut();
      }
      _debugLog('Firebase Auth createUserWithEmailAndPassword starting.');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      createdUser = credential.user;

      if (createdUser == null) {
        throw StateError('Account creation failed. Please try again.');
      }

      _debugLog('Firebase Auth user created with uid: ${createdUser.uid}');
      _debugLog('credential.user.uid after Auth creation: ${createdUser.uid}');
      await createdUser.updateDisplayName(fullName.trim());
      _debugLog('Normalized email being searched: $normalizedEmail');
      _debugLog('Pending invite lookup starting.');
      final staffTarget = await _staffInvites
          .findValidPendingInviteForSignupOrNull(normalizedEmail);
      final memberTarget = await _memberInvites
          .findValidPendingInviteForSignupOrNull(normalizedEmail);

      if (staffTarget != null && memberTarget != null) {
        throw StateError(
          'Both staff and member invites exist for this email. Please contact the gym owner.',
        );
      }
      if (staffTarget == null && memberTarget == null) {
        throw StateError('No pending invite found for this email.');
      }

      final isMemberInvite = memberTarget != null;
      final gymId =
          isMemberInvite ? memberTarget.invite.gymId : staffTarget!.invite.gymId;
      final inviteId =
          isMemberInvite ? memberTarget.invite.id : staffTarget!.invite.id;
      _debugLog(
        'Invite lookup succeeded with ${isMemberInvite ? 'member' : 'staff'} invite $inviteId for gymId $gymId.',
      );
      _debugLog(
        'Claiming email $normalizedEmail with invite $inviteId and gymId $gymId.',
      );
      _debugLog('Claim transaction request starting.');
      if (isMemberInvite) {
        await _memberInvites.claimMemberInvite(
          target: memberTarget,
          uid: createdUser.uid,
          fullName: fullName,
          email: normalizedEmail,
          phone: phone.trim().isEmpty ? null : phone.trim(),
        );
      } else {
        await _staffInvites.claimStaffInvite(
          target: staffTarget!,
          uid: createdUser.uid,
          fullName: fullName,
          email: normalizedEmail,
          phone: phone.trim().isEmpty ? null : phone.trim(),
        );
      }
      _debugLog('Invite claim succeeded. Signing out newly created staff user.');
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (error) {
      _debugLog('FirebaseAuthException: ${error.code} ${error.message}');
      if (createdUser != null) {
        return await _cleanupCreatedAuthUser(
          createdUser,
          _mapFailureAfterAuth(
            'Firebase Auth update failed (${error.code}): ${error.message ?? 'Auth error'}',
          ),
        );
      }
      return _mapSignUpError(error);
    } catch (error) {
      _debugLog('Signup/claim error: $error');
      if (createdUser != null) {
        return await _cleanupCreatedAuthUser(
          createdUser,
          _mapFailureAfterAuth(error),
        );
      }
      await _auth.signOut();
      return error.toString().replaceFirst('Bad state: ', '');
    }
  }

  String _mapSignUpError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email. Sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Weak password. Use at least 8 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Unable to create account right now.';
    }
  }

  String? _validateBeforeAuthCreate({
    required String fullName,
    required String email,
    required String password,
  }) {
    if (fullName.trim().isEmpty) {
      return 'Full name is required.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    if (password.length < 8) {
      return 'Weak password. Use at least 8 characters.';
    }
    return null;
  }

  Future<String> _cleanupCreatedAuthUser(User createdUser, String reason) async {
    try {
      _debugLog('Attempting to delete newly created Auth user: ${createdUser.uid}');
      await createdUser.delete();
      await _auth.signOut();
      _debugLog('Newly created Auth user deleted after claim failure.');
      return '$reason No app profile was created. Please try again.';
    } catch (cleanupError) {
      _debugLog('Auth cleanup failed: $cleanupError');
      await _auth.signOut();
      return '$reason The Auth account was created, but invite setup failed and automatic cleanup failed. Please contact the gym owner/admin to clean up the account.';
    }
  }

  String _mapFailureAfterAuth(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '');
    final lower = message.toLowerCase();
    if (lower.contains('collection group index') ||
        lower.contains('requires a firestore') ||
        lower.contains('failed-precondition')) {
      return 'Invite lookup needs a Firestore index before signup can finish.';
    }
    if (lower.contains('permission-denied') ||
        lower.contains('blocked by firestore rules')) {
      return 'Invite lookup or claim was blocked by Firestore rules. Please contact the gym owner/admin.';
    }
    if (lower.contains('no pending invite')) {
      return 'No pending invite was found for this email. Ask the gym owner/admin to send an invite first.';
    }
    if (lower.contains('expired')) {
      return 'This invite has expired. Ask the gym owner/admin to send a new invite.';
    }
    return 'Invite signup failed: $message';
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[StaffInviteSignup] $message');
    }
  }
}
