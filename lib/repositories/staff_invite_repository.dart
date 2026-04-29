import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gymsaas/models/staff_invite.dart';
import 'package:gymsaas/navigation/role_capabilities.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class StaffInviteRepository {
  StaffInviteRepository(this._db, this._paths);

  final FirebaseFirestore _db;
  final GymFirestorePaths _paths;

  Stream<List<StaffInvite>> streamStaffInvites(String gymId) {
    return _paths
        .staffInvitesCollection(gymId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(StaffInvite.fromFirestore).toList());
  }

  Future<DocumentReference<Map<String, dynamic>>> createStaffInvite(
    String gymId,
    Map<String, dynamic> invite,
  ) {
    final now = FieldValue.serverTimestamp();
    return _paths.staffInvitesCollection(gymId).add({
      ...invite,
      'gymId': gymId,
      'email': _normalizeEmail(invite['email'] as String? ?? ''),
      'emailNormalized': _normalizeEmail(invite['email'] as String? ?? ''),
      'status': StaffInviteStatus.pending,
      'createdAt': invite['createdAt'] ?? now,
      'updatedAt': invite['updatedAt'] ?? now,
    });
  }

  Future<void> updateStaffInvite(
    String gymId,
    String inviteId,
    Map<String, dynamic> data,
  ) {
    return _paths.staffInviteDoc(gymId, inviteId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cancelStaffInvite(String gymId, String inviteId) {
    return updateStaffInvite(gymId, inviteId, {
      'status': StaffInviteStatus.cancelled,
    });
  }

  Future<bool> staffEmailExists(String gymId, String email) async {
    final normalizedEmail = _normalizeEmail(email);
    final staff = await _paths.staffCollection(gymId).get();
    return staff.docs.any((doc) {
      final data = doc.data();
      final staffEmail = _normalizeEmail(data['email'] as String? ?? '');
      return staffEmail == normalizedEmail;
    });
  }

  Future<bool> pendingInviteEmailExists(String gymId, String email) async {
    final normalizedEmail = _normalizeEmail(email);
    final invites = await _paths
        .staffInvitesCollection(gymId)
        .where('emailNormalized', isEqualTo: normalizedEmail)
        .where('status', isEqualTo: StaffInviteStatus.pending)
        .limit(1)
        .get();
    return invites.docs.isNotEmpty;
  }

  Future<StaffInviteClaimTarget> findPendingInviteForSignup(
    String email,
  ) async {
    final target = await findValidPendingInviteForSignupOrNull(email);
    if (target == null) {
      throw StateError(
        'No pending staff invite found for this email. Ask your gym owner/admin to invite you first.',
      );
    }
    return target;
  }

  Future<StaffInviteClaimTarget?> findValidPendingInviteForSignupOrNull(
    String email,
  ) async {
    final normalizedEmail = _normalizeEmail(email);
    final now = DateTime.now();
    _debugLog('Invite lookup started for normalized email: $normalizedEmail');

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _db
          .collectionGroup('staffInvites')
          .where('emailNormalized', isEqualTo: normalizedEmail)
          .where('status', isEqualTo: StaffInviteStatus.pending)
          .get();
    } on FirebaseException catch (error) {
      _debugLog(
        'Invite lookup FirebaseException: ${error.code} ${error.message}',
      );
      throw StateError(_mapInviteLookupFirestoreError(error));
    }

    _debugLog('Invite lookup candidate count: ${snapshot.docs.length}');

    if (snapshot.docs.isEmpty) return null;

    final matchingEmail = snapshot.docs.where((doc) {
      final invite = StaffInvite.fromFirestore(doc);
      return _normalizeEmail(invite.email) == normalizedEmail;
    }).toList();

    if (matchingEmail.isEmpty) return null;

    final allowedRoleInvites = matchingEmail.where((doc) {
      final invite = StaffInvite.fromFirestore(doc);
      return _isSignupRoleAllowed(invite.role);
    }).toList();

    if (allowedRoleInvites.isEmpty) {
      throw StateError(
        'Invite found, but its role is not allowed for staff signup. Ask your gym owner/admin to send a valid staff invite.',
      );
    }

    final withGym = allowedRoleInvites.where((doc) {
      final invite = StaffInvite.fromFirestore(doc);
      return invite.gymId.trim().isNotEmpty;
    }).toList();

    if (withGym.isEmpty) {
      throw StateError(
        'Invite found, but it is missing a gym. Ask your gym owner/admin to recreate the invite.',
      );
    }

    final validInvites = withGym.where((doc) {
      final invite = StaffInvite.fromFirestore(doc);
      return invite.expiresAt == null || invite.expiresAt!.isAfter(now);
    }).toList();

    if (validInvites.isEmpty) {
      throw StateError(
        'Invite found, but it has expired. Ask your gym owner/admin to send a new invite.',
      );
    }

    if (validInvites.length > 1) {
      throw StateError(
        'Multiple pending invites found. Please contact the gym owner.',
      );
    }

    final doc = validInvites.single;
    final invite = StaffInvite.fromFirestore(doc);
    _debugLog(
      'Selected invite ${invite.id} for gymId ${invite.gymId}.',
    );
    return StaffInviteClaimTarget(
      invite: invite,
      inviteRef: doc.reference,
    );
  }

  Future<void> claimStaffInvite({
    required StaffInviteClaimTarget target,
    required String uid,
    required String fullName,
    required String email,
    required String? phone,
  }) async {
    final normalizedEmail = _normalizeEmail(email);

    _debugLog('Claim transaction starting for uid: $uid');

    try {
      await _db.runTransaction((transaction) async {
      final inviteSnapshot = await transaction.get(target.inviteRef);
      if (!inviteSnapshot.exists) {
        throw StateError('Invite no longer exists.');
      }

      final invite = StaffInvite.fromFirestore(inviteSnapshot);
      if (invite.status != StaffInviteStatus.pending) {
        throw StateError('This invite has already been used or cancelled.');
      }

      if (_normalizeEmail(invite.email) != normalizedEmail) {
        throw StateError('Invite email does not match this account.');
      }

      if (invite.gymId.trim().isEmpty) {
        throw StateError('Invite is missing a gym.');
      }

      if (invite.expiresAt != null && !invite.expiresAt!.isAfter(DateTime.now())) {
        throw StateError('This invite has expired.');
      }

      final inviteRole = invite.role.trim().toLowerCase();
      if (!_isSignupRoleAllowed(inviteRole)) {
        throw StateError('This invite role is not supported for signup.');
      }

      final userRef = _db.collection('users').doc(uid);
      final userSnapshot = await transaction.get(userRef);
      if (userSnapshot.exists) {
        throw StateError('A user profile already exists for this account.');
      }

      final displayName =
          fullName.trim().isNotEmpty ? fullName.trim() : invite.fullName;
      final resolvedPhone =
          phone != null && phone.trim().isNotEmpty ? phone.trim() : invite.phone;
      final staffRef = _paths.staffCollection(invite.gymId).doc(uid);
      final now = FieldValue.serverTimestamp();

      transaction.set(userRef, {
        'displayName': displayName,
        'email': normalizedEmail,
        'phone': resolvedPhone,
        'role': inviteRole,
        'status': 'active',
        'defaultGymId': invite.gymId,
        'createdAt': now,
        'updatedAt': now,
        'inviteId': invite.id,
        'createdFromInvite': true,
      });
      _debugLog('users/$uid creation queued.');

      transaction.set(staffRef, {
        'authUid': uid,
        'gymId': invite.gymId,
        'fullName': displayName,
        'name': displayName,
        'email': normalizedEmail,
        'emailNormalized': normalizedEmail,
        'phone': resolvedPhone,
        'role': inviteRole,
        'status': 'active',
        'notes': invite.notes,
        'inviteId': invite.id,
        'createdAt': now,
        'updatedAt': now,
        'createdBy': invite.createdBy,
        'onDuty': false,
        'permissions': <String>[],
      });
      _debugLog('gyms/${invite.gymId}/staff/$uid creation queued.');

      transaction.update(target.inviteRef, {
        'status': StaffInviteStatus.claimed,
        'claimedAt': now,
        'claimedByUid': uid,
        'updatedAt': now,
      });
      _debugLog('Invite ${invite.id} claimed update queued.');
      });
      _debugLog('Claim transaction completed for uid: $uid');
    } on FirebaseException catch (error) {
      _debugLog(
        'Claim transaction FirebaseException: ${error.code} ${error.message}',
      );
      throw StateError(_mapClaimFirestoreError(error));
    }
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  bool _isSignupRoleAllowed(String role) {
    return {
      AppRoles.admin,
      AppRoles.reception,
      AppRoles.coach,
    }.contains(role.trim().toLowerCase());
  }

  String _mapInviteLookupFirestoreError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Invite lookup was blocked by Firestore rules. Ask support to allow staff invite lookup during signup.';
    }
    if (error.code == 'failed-precondition') {
      return 'Invite lookup requires a Firestore collection group index for staffInvites on emailNormalized and status. Create the index, then try again.';
    }
    return 'Invite lookup failed (${error.code}): ${error.message ?? 'Firestore error'}';
  }

  String _mapClaimFirestoreError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Invite claim was blocked by Firestore rules. Ask support to allow invite claim writes.';
    }
    return 'Invite claim failed (${error.code}): ${error.message ?? 'Firestore error'}';
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[StaffInviteSignup] $message');
    }
  }
}

class StaffInviteClaimTarget {
  final StaffInvite invite;
  final DocumentReference<Map<String, dynamic>> inviteRef;

  const StaffInviteClaimTarget({
    required this.invite,
    required this.inviteRef,
  });
}
