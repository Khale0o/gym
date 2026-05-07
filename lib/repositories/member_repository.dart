import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class MemberRepository {
  MemberRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<List<Member>> streamMembers(String gymId) {
    return _paths
        .membersCollection(gymId)
        .orderBy('fullName')
        .snapshots()
        .map((snap) => snap.docs.where((doc) {
              final data = doc.data();
              final accountStatus =
                  (data['accountStatus'] as String?)?.trim().toLowerCase();
              return accountStatus != 'archived' &&
                  !data.containsKey('deletedAt');
            }).map(Member.fromFirestore).toList());
  }

  Future<Member?> getMember(String gymId, String memberId) async {
    final doc = await _paths.memberDoc(gymId, memberId).get();
    if (!doc.exists) {
      return null;
    }
    return Member.fromFirestore(doc);
  }

  Future<Member?> getMemberByAuthUid(String gymId, String authUid) async {
    final snap = await _paths
        .membersCollection(gymId)
        .where('authUid', isEqualTo: authUid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      return null;
    }
    return Member.fromFirestore(snap.docs.first);
  }

  Future<void> updateMemberProfileAndAccess({
    required String gymId,
    required String memberId,
    required String fullName,
    required String phone,
    String? email,
    String? status,
    String? notes,
    String? nfcTagId,
    String? qrCode,
    String? accessCode,
    String? accessStatus,
  }) async {
    final trimmedGymId = gymId.trim();
    final trimmedMemberId = memberId.trim();
    final trimmedFullName = fullName.trim();
    final trimmedPhone = phone.trim();
    final trimmedEmail = _optionalTrimmed(email);
    final trimmedStatus = _optionalTrimmed(status);
    final trimmedNotes = _optionalTrimmed(notes);
    final trimmedNfcTagId = _optionalTrimmed(nfcTagId);
    final trimmedQrCode = _optionalTrimmed(qrCode);
    final trimmedAccessCode = _optionalTrimmed(accessCode);
    var trimmedAccessStatus = _optionalTrimmed(accessStatus)?.toLowerCase();

    if (trimmedGymId.isEmpty) {
      throw StateError('Gym ID is required.');
    }
    if (trimmedMemberId.isEmpty) {
      throw StateError('Member ID is required.');
    }
    if (trimmedFullName.isEmpty) {
      throw StateError('Full name is required.');
    }
    if (trimmedPhone.isEmpty) {
      throw StateError('Phone is required.');
    }
    if (trimmedEmail != null && !_looksLikeEmail(trimmedEmail)) {
      throw StateError('Enter a valid email address or leave email empty.');
    }

    final nfcTagIdNormalized = normalizeAccessIdentifier(trimmedNfcTagId);
    final qrCodeNormalized = normalizeAccessIdentifier(trimmedQrCode);
    final accessCodeNormalized = normalizeAccessIdentifier(trimmedAccessCode);
    final hasAccessIdentifier = nfcTagIdNormalized != null ||
        qrCodeNormalized != null ||
        accessCodeNormalized != null;

    if (hasAccessIdentifier && trimmedAccessStatus == null) {
      trimmedAccessStatus = 'active';
    }
    if (trimmedAccessStatus != null &&
        !_supportedAccessStatuses.contains(trimmedAccessStatus)) {
      throw StateError('Unsupported access status.');
    }

    await _ensureNoDuplicateNormalizedIdentifier(
      gymId: trimmedGymId,
      memberId: trimmedMemberId,
      field: 'nfcTagId',
      normalized: nfcTagIdNormalized,
      message: 'This NFC tag is already assigned to another member.',
    );
    await _ensureNoDuplicateNormalizedIdentifier(
      gymId: trimmedGymId,
      memberId: trimmedMemberId,
      field: 'qrCode',
      normalized: qrCodeNormalized,
      message: 'This QR code is already assigned to another member.',
    );
    await _ensureNoDuplicateNormalizedIdentifier(
      gymId: trimmedGymId,
      memberId: trimmedMemberId,
      field: 'accessCode',
      normalized: accessCodeNormalized,
      message: 'This access code is already assigned to another member.',
    );

    final memberRef = _paths.memberDoc(trimmedGymId, trimmedMemberId);
    final existingDoc = await memberRef.get();
    if (!existingDoc.exists) {
      throw StateError('Member not found.');
    }

    final existing = existingDoc.data() ?? <String, dynamic>{};
    final existingNfcTagId =
        normalizeAccessIdentifier(existing['nfcTagId'] as String?) ??
            normalizeAccessIdentifier(existing['nfcTagIdNormalized'] as String?);
    final existingQrCode =
        normalizeAccessIdentifier(existing['qrCode'] as String?) ??
            normalizeAccessIdentifier(existing['qrCodeNormalized'] as String?);
    final existingAccessCode =
        normalizeAccessIdentifier(existing['accessCode'] as String?) ??
            normalizeAccessIdentifier(
              existing['accessCodeNormalized'] as String?,
            );
    final previouslyHadAccessIdentifier =
        existingNfcTagId != null ||
            existingQrCode != null ||
            existingAccessCode != null;
    final accessChanged =
        existingNfcTagId != nfcTagIdNormalized ||
            existingQrCode != qrCodeNormalized ||
            existingAccessCode != accessCodeNormalized ||
            normalizeAccessIdentifier(existing['accessStatus'] as String?) !=
                trimmedAccessStatus;

    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'fullName': trimmedFullName,
      'phone': trimmedPhone,
      'email': trimmedEmail,
      'emailNormalized': trimmedEmail?.toLowerCase(),
      'status': trimmedStatus,
      'notes': trimmedNotes,
      'nfcTagId': trimmedNfcTagId,
      'nfcTagIdNormalized': nfcTagIdNormalized,
      'qrCode': trimmedQrCode,
      'qrCodeNormalized': qrCodeNormalized,
      'accessCode': trimmedAccessCode,
      'accessCodeNormalized': accessCodeNormalized,
      'accessStatus': trimmedAccessStatus,
      'updatedAt': now,
      if (accessChanged) 'accessUpdatedAt': now,
      if (!previouslyHadAccessIdentifier && hasAccessIdentifier)
        'accessAssignedAt': now,
    };

    await memberRef.update(data);
  }

  Future<bool> accessIdentifierExists({
    required String gymId,
    String? nfcTagId,
    String? qrCode,
    String? accessCode,
    String? excludeMemberId,
  }) async {
    final nfc = normalizeAccessIdentifier(nfcTagId);
    final qr = normalizeAccessIdentifier(qrCode);
    final access = normalizeAccessIdentifier(accessCode);
    final candidates = {nfc, qr, access}.whereType<String>().toSet();
    if (candidates.isEmpty) {
      return false;
    }

    final snap = await _paths.membersCollection(gymId).get();
    for (final doc in snap.docs) {
      if (excludeMemberId != null && doc.id == excludeMemberId) {
        continue;
      }
      final data = doc.data();
      for (final candidate in candidates) {
        if (_fieldMatches(data, 'nfcTagId', candidate) ||
            _fieldMatches(data, 'qrCode', candidate) ||
            _fieldMatches(data, 'accessCode', candidate)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<Member?> findMemberByAccessCode({
    required String gymId,
    required String code,
  }) async {
    final normalized = normalizeAccessIdentifier(code);
    if (normalized == null) {
      return null;
    }

    final snap = await _paths.membersCollection(gymId).get();
    final matches = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      if (_fieldMatches(data, 'nfcTagId', normalized) ||
          _fieldMatches(data, 'qrCode', normalized) ||
          _fieldMatches(data, 'accessCode', normalized)) {
        matches.add(doc);
      }
    }

    final unique = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final match in matches) {
      unique[match.id] = match;
    }
    if (unique.length > 1) {
      throw StateError('Multiple members match this access code.');
    }
    if (unique.isEmpty) {
      return null;
    }
    return Member.fromFirestore(unique.values.first);
  }

  Future<void> archiveMember({
    required String gymId,
    required String memberId,
    required String reason,
    required String performedByUid,
  }) async {
    final trimmedGymId = gymId.trim();
    final trimmedMemberId = memberId.trim();
    final trimmedReason = reason.trim();
    final trimmedPerformedBy = performedByUid.trim();

    if (trimmedGymId.isEmpty) {
      throw StateError('Gym ID is required.');
    }
    if (trimmedMemberId.isEmpty) {
      throw StateError('Member ID is required.');
    }
    if (trimmedReason.isEmpty) {
      throw StateError('Reason is required.');
    }
    if (trimmedPerformedBy.isEmpty) {
      throw StateError('Signed-in user is required.');
    }

    final memberRef = _paths.memberDoc(trimmedGymId, trimmedMemberId);
    final memberSnap = await memberRef.get();
    if (!memberSnap.exists) {
      throw StateError('Member not found.');
    }

    final now = FieldValue.serverTimestamp();
    await memberRef.update({
      'status': 'inactive',
      'accountStatus': 'archived',
      'deletedAt': now,
      'deletedBy': trimmedPerformedBy,
      'deleteReason': trimmedReason,
      'updatedAt': now,
    });
  }

  static String? normalizeAccessIdentifier(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed.toLowerCase();
  }

  static const _supportedAccessStatuses = {
    'active',
    'disabled',
    'lost',
    'replaced',
  };

  static String? _optionalTrimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  static bool _fieldMatches(
    Map<String, dynamic> data,
    String field,
    String normalized,
  ) {
    final raw = normalizeAccessIdentifier(data[field] as String?);
    final storedNormalized =
        normalizeAccessIdentifier(data['${field}Normalized'] as String?);
    return raw == normalized || storedNormalized == normalized;
  }

  Future<void> _ensureNoDuplicateNormalizedIdentifier({
    required String gymId,
    required String memberId,
    required String field,
    required String? normalized,
    required String message,
  }) async {
    if (normalized == null) {
      return;
    }

    final snap = await _paths.membersCollection(gymId).get();
    for (final doc in snap.docs) {
      if (doc.id == memberId) {
        continue;
      }
      if (_fieldMatches(doc.data(), field, normalized)) {
        throw StateError(message);
      }
    }
  }

  Future<DocumentReference<Map<String, dynamic>>> createMember(
    String gymId,
    Map<String, dynamic> memberData,
  ) {
    final now = FieldValue.serverTimestamp();
    return _paths.membersCollection(gymId).add({
      ...memberData,
      'gymId': gymId,
      'createdAt': memberData['createdAt'] ?? now,
      'updatedAt': memberData['updatedAt'] ?? now,
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> createMemberWithRelatedRecords({
    required String gymId,
    required Map<String, dynamic> memberData,
    Map<String, dynamic>? inviteData,
    Map<String, dynamic>? subscriptionData,
    Map<String, dynamic>? memberSummaryData,
  }) async {
    final firestore = _paths.membersCollection(gymId).firestore;
    final batch = firestore.batch();
    final now = FieldValue.serverTimestamp();
    final memberRef = _paths.membersCollection(gymId).doc();

    batch.set(memberRef, {
      ...memberData,
      'gymId': gymId,
      'createdAt': memberData['createdAt'] ?? now,
      'updatedAt': memberData['updatedAt'] ?? now,
    });

    if (inviteData != null) {
      final inviteRef = _paths.memberInvitesCollection(gymId).doc();
      batch.set(inviteRef, {
        ...inviteData,
        'gymId': gymId,
        'memberId': memberRef.id,
        'role': 'member',
        'status': 'pending',
        'createdAt': inviteData['createdAt'] ?? now,
        'updatedAt': inviteData['updatedAt'] ?? now,
      });
    }

    if (subscriptionData != null) {
      final subscriptionRef = _paths.subscriptionsCollection(gymId).doc();
      batch.set(subscriptionRef, {
        ...subscriptionData,
        'gymId': gymId,
        'memberId': memberRef.id,
        'createdAt': subscriptionData['createdAt'] ?? now,
        'updatedAt': subscriptionData['updatedAt'] ?? now,
      });
    }

    if (memberSummaryData != null) {
      batch.set(memberRef, {
        ...memberSummaryData,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }

    await batch.commit();
    return memberRef;
  }

  Future<void> updateMember(
    String gymId,
    String memberId,
    Map<String, dynamic> data,
  ) async {
    final touchesAccessIdentifiers = data.containsKey('nfcTagId') ||
        data.containsKey('qrCode') ||
        data.containsKey('accessCode');
    if (touchesAccessIdentifiers) {
      final duplicate = await accessIdentifierExists(
        gymId: gymId,
        nfcTagId: data['nfcTagId'] as String?,
        qrCode: data['qrCode'] as String?,
        accessCode: data['accessCode'] as String?,
        excludeMemberId: memberId,
      );
      if (duplicate) {
        throw StateError(
          'This NFC tag or QR/access code is already assigned to another member.',
        );
      }
    }
    return _paths.memberDoc(gymId, memberId).set({
      ...data,
      'gymId': gymId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
