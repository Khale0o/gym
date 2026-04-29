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
    final oldUser = _auth.currentUser;
    _debugLog('Old currentUser before signup starts: ${oldUser?.uid ?? 'none'}');

    try {
      if (oldUser != null) {
        _debugLog('Signing out old currentUser before invite signup.');
        await _auth.signOut();
      }
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
          _mapClaimFailureAfterAuth(
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
          _mapClaimFailureAfterAuth(error),
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

  Future<String> _cleanupCreatedAuthUser(User createdUser, String reason) async {
    try {
      _debugLog('Attempting to delete newly created Auth user: ${createdUser.uid}');
      await createdUser.delete();
      await _auth.signOut();
      _debugLog('Newly created Auth user deleted after claim failure.');
      return '$reason No staff profile was created. Please try again.';
    } catch (cleanupError) {
      _debugLog('Auth cleanup failed: $cleanupError');
      await _auth.signOut();
      return '$reason The Auth account was created, but the invite claim failed and automatic cleanup failed. Please contact support to clean up the account.';
    }
  }

  String _mapClaimFailureAfterAuth(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '');
    if (message.contains('permission-denied') ||
        message.toLowerCase().contains('blocked by firestore rules')) {
      return 'Claim transaction failed because Firestore rules blocked the write.';
    }
    return 'Claim transaction failed: $message';
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[StaffInviteSignup] $message');
    }
  }
}
