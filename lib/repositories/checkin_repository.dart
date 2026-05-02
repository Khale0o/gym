import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/checkin.dart';
import 'package:gymsaas/models/member_access_eligibility.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/models/subscription.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class CheckInValidationResult {
  const CheckInValidationResult._({
    required this.allowed,
    required this.message,
    this.member,
    this.subscription,
  });

  final bool allowed;
  final String message;
  final Member? member;
  final GymSubscription? subscription;

  factory CheckInValidationResult.allowed({
    required Member member,
    required GymSubscription subscription,
  }) {
    return CheckInValidationResult._(
      allowed: true,
      message: 'Access granted',
      member: member,
      subscription: subscription,
    );
  }

  factory CheckInValidationResult.blocked(String message) {
    return CheckInValidationResult._(allowed: false, message: message);
  }
}

class CheckInAdmission {
  const CheckInAdmission({
    required this.memberName,
    required this.planName,
  });

  final String memberName;
  final String planName;
}

class CheckInRepository {
  CheckInRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<List<CheckIn>> streamRecentCheckins(String gymId) {
    return _paths
        .checkinsCollection(gymId)
        .orderBy('time', descending: true)
        .limit(8)
        .snapshots()
        .map((snap) => snap.docs.map(CheckIn.fromFirestore).toList());
  }

  Stream<List<CheckIn>> streamMemberCheckins(
    String gymId,
    String memberId, {
    int limit = 10,
  }) {
    return _paths
        .checkinsCollection(gymId)
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snap) {
      final rows = snap.docs.map(CheckIn.fromFirestore).toList();
      rows.sort((a, b) => b.time.compareTo(a.time));
      return rows.take(limit).toList();
    });
  }

  Stream<double> streamOccupancy(String gymId) {
    return _paths.occupancyDoc(gymId).snapshots().map((snap) {
      if (!snap.exists) return 0.0;
      final data = snap.data() ?? <String, dynamic>{};
      return ((data['count'] as num?) ?? 0).toDouble();
    });
  }

  Future<void> setOccupancy(String gymId, double count) async {
    final db = _paths.gymDoc(gymId).firestore;
    final occupancyRef = _paths.occupancyDoc(gymId);
    final safeCount = count.round().clamp(0, 1 << 30);

    await db.runTransaction((transaction) async {
      final snap = await transaction.get(occupancyRef);
      transaction.set(
        occupancyRef,
        {
          'count': safeCount,
          if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<CheckInValidationResult> validateMemberForCheckIn({
    required String gymId,
    required String memberId,
  }) async {
    final memberSnap = await _paths.memberDoc(gymId, memberId).get();
    final subscriptionSnap = await _selectSubscriptionSnapshot(gymId, memberId);
    return _validateSnapshots(memberSnap, subscriptionSnap);
  }

  Future<CheckInAdmission> checkInMember({
    required String gymId,
    required String memberId,
    required String method,
  }) async {
    final subscriptionSnap = await _selectSubscriptionSnapshot(gymId, memberId);
    final db = _paths.gymDoc(gymId).firestore;
    final memberRef = _paths.memberDoc(gymId, memberId);
    final occupancyRef = _paths.occupancyDoc(gymId);
    final checkinRef = _paths.checkinsCollection(gymId).doc();

    CheckInAdmission? admission;

    await db.runTransaction((transaction) async {
      final memberSnap = await transaction.get(memberRef);
      final freshSubscriptionSnap = subscriptionSnap == null
          ? null
          : await transaction.get(subscriptionSnap.reference);
      final validation = _validateSnapshots(memberSnap, freshSubscriptionSnap);
      if (!validation.allowed ||
          validation.member == null ||
          validation.subscription == null) {
        throw StateError(validation.message);
      }

      final occupancySnap = await transaction.get(occupancyRef);
      final occupancyData = occupancySnap.data() ?? <String, dynamic>{};
      final currentCount = ((occupancyData['count'] as num?) ?? 0).toInt();
      final member = validation.member!;
      final subscription = validation.subscription!;
      final now = Timestamp.now();

      transaction.set(checkinRef, {
        'gymId': gymId,
        'memberId': member.id,
        'name': member.fullName,
        'memberName': member.fullName,
        'time': now,
        'method': method,
        'plan': subscription.planName,
        'planId': subscription.planId,
        'subscriptionId': subscription.id,
        'subscriptionStatus': subscription.status,
        'paymentStatus': subscription.paymentStatus,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        occupancyRef,
        {
          'count': currentCount + 1,
          if (!occupancySnap.exists) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        memberRef,
        {
          'lastCheckInAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      admission = CheckInAdmission(
        memberName: member.fullName,
        planName: subscription.planName,
      );
    });

    return admission!;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
      _selectSubscriptionSnapshot(String gymId, String memberId) async {
    final snap = await _paths
        .subscriptionsCollection(gymId)
        .where('memberId', isEqualTo: memberId)
        .where('status', isEqualTo: SubscriptionStatus.active)
        .get();
    if (snap.docs.isEmpty) return null;

    final docs = [...snap.docs];
    docs.sort((a, b) {
      final aEnd = (a.data()['endDate'] as Timestamp?)?.toDate();
      final bEnd = (b.data()['endDate'] as Timestamp?)?.toDate();
      return (bEnd ?? DateTime(1900)).compareTo(aEnd ?? DateTime(1900));
    });
    return docs.first;
  }

  CheckInValidationResult _validateSnapshots(
    DocumentSnapshot<Map<String, dynamic>> memberSnap,
    DocumentSnapshot<Map<String, dynamic>>? subscriptionSnap,
  ) {
    if (!memberSnap.exists) {
      return CheckInValidationResult.blocked('Member not found.');
    }

    final member = Member.fromFirestore(memberSnap);
    final status = member.status.trim().toLowerCase();
    final accountStatus = member.accountStatus?.trim().toLowerCase();
    if (status != 'active') {
      return CheckInValidationResult.blocked('Member is inactive.');
    }
    if (accountStatus != null &&
        accountStatus.isNotEmpty &&
        accountStatus != 'active') {
      return CheckInValidationResult.blocked('Member account is inactive.');
    }

    final accessMessage = blockedAccessStatusMessage(member.accessStatus);
    if (accessMessage != null) {
      return CheckInValidationResult.blocked(accessMessage);
    }

    final summaryStatus = member.subscriptionStatus?.trim().toLowerCase();
    if (summaryStatus != null &&
        summaryStatus.isNotEmpty &&
        summaryStatus != SubscriptionStatus.active) {
      return summaryStatus == SubscriptionStatus.expired
          ? CheckInValidationResult.blocked('Subscription expired.')
          : CheckInValidationResult.blocked('No active subscription found.');
    }

    if (_isBeforeToday(member.subscriptionEndDate)) {
      return CheckInValidationResult.blocked('Subscription expired.');
    }

    if (subscriptionSnap == null || !subscriptionSnap.exists) {
      return CheckInValidationResult.blocked('No active subscription found.');
    }

    final subscription = GymSubscription.fromFirestore(subscriptionSnap);
    if (subscription.status != SubscriptionStatus.active) {
      return CheckInValidationResult.blocked('No active subscription found.');
    }

    if (subscription.endDate == null || _isBeforeToday(subscription.endDate)) {
      return CheckInValidationResult.blocked('Subscription expired.');
    }

    if (subscription.paymentStatus != SubscriptionPaymentStatus.paid &&
        subscription.paymentStatus != SubscriptionPaymentStatus.partial) {
      return CheckInValidationResult.blocked('Subscription is unpaid.');
    }

    return CheckInValidationResult.allowed(
      member: member,
      subscription: subscription,
    );
  }

  bool _isBeforeToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(date.year, date.month, date.day);
    return value.isBefore(today);
  }
}
