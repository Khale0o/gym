import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/models/membership_plan.dart';
import 'package:gymsaas/models/subscription.dart';
import 'package:gymsaas/models/transaction_model.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class CreateTransactionInput {
  const CreateTransactionInput({
    required this.memberId,
    required this.memberName,
    required this.subscriptionId,
    required this.planId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.description,
    required this.createdByUid,
    required this.createdByName,
    required this.notes,
    this.metadata,
  });

  final String memberId;
  final String memberName;
  final String? subscriptionId;
  final String? planId;
  final String type;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final String description;
  final String createdByUid;
  final String? createdByName;
  final String? notes;
  final Map<String, dynamic>? metadata;
}

class CreatedTransaction {
  const CreatedTransaction({
    required this.id,
    required this.receiptNumber,
    this.subscriptionId,
  });

  final String id;
  final String receiptNumber;
  final String? subscriptionId;
}

class CreateRenewalPaymentInput {
  const CreateRenewalPaymentInput({
    required this.memberId,
    required this.memberName,
    required this.planId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdByUid,
    required this.createdByName,
    required this.notes,
    this.baseSubscriptionId,
  });

  final String memberId;
  final String memberName;
  final String planId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final String createdByUid;
  final String? createdByName;
  final String? notes;
  final String? baseSubscriptionId;
}

class TransactionRepository {
  TransactionRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<List<GymTransaction>> streamTransactions(String gymId) {
    return _paths
        .transactionsCollection(gymId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(GymTransaction.fromFirestore).toList());
  }

  Stream<List<GymTransaction>> streamMemberTransactions(
    String gymId,
    String memberId,
  ) {
    return _paths
        .transactionsCollection(gymId)
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snap) {
      final rows = snap.docs.map(GymTransaction.fromFirestore).toList();
      rows.sort((a, b) => b.date.compareTo(a.date));
      return rows;
    });
  }

  Future<CreatedTransaction> createTransaction({
    required String gymId,
    required CreateTransactionInput input,
  }) async {
    if (gymId.trim().isEmpty) {
      throw StateError('Current gym is required.');
    }
    if (!input.amount.isFinite || input.amount <= 0) {
      throw StateError('Amount must be greater than zero.');
    }
    if (input.paymentMethod.trim().isEmpty) {
      throw StateError('Payment method is required.');
    }

    final db = _paths.gymDoc(gymId).firestore;
    final memberRef = input.memberId.trim().isEmpty
        ? null
        : _paths.memberDoc(gymId, input.memberId.trim());
    final subscriptionRef = input.subscriptionId == null ||
            input.subscriptionId!.trim().isEmpty
        ? null
        : _paths.subscriptionDoc(gymId, input.subscriptionId!.trim());
    final counterRef = _paths.settingsCollection(gymId).doc('receiptCounter');
    final transactionRef = _paths.transactionsCollection(gymId).doc();

    String? receiptNumber;

    await db.runTransaction((transaction) async {
      Member? member;
      if (memberRef != null) {
        final memberSnap = await transaction.get(memberRef);
        if (!memberSnap.exists) {
          throw StateError('Member not found.');
        }
        member = Member.fromFirestore(memberSnap);
      }

      GymSubscription? subscription;
      if (subscriptionRef != null) {
        final subscriptionSnap = await transaction.get(subscriptionRef);
        if (!subscriptionSnap.exists) {
          throw StateError('Subscription not found.');
        }
        subscription = GymSubscription.fromFirestore(subscriptionSnap);
      }

      final counterSnap = await transaction.get(counterRef);
      final counterData = counterSnap.data() ?? <String, dynamic>{};
      final nextSequence = ((counterData['lastNumber'] as num?) ?? 0).toInt() + 1;
      final now = DateTime.now();
      final dateKey =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      receiptNumber =
          '${_gymReceiptPrefix(gymId)}-$dateKey-${nextSequence.toString().padLeft(4, '0')}';

      transaction.set(
        counterRef,
        {
          'lastNumber': nextSequence,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(transactionRef, {
        'gymId': gymId,
        'memberId': member?.id ?? input.memberId.trim(),
        'memberName': member?.fullName ?? input.memberName.trim(),
        'subscriptionId': subscription?.id ?? input.subscriptionId,
        'planId': subscription?.planId ?? input.planId,
        'type': input.type,
        'amount': input.amount,
        'currency': input.currency,
        'paymentMethod': input.paymentMethod,
        'paymentStatus': input.paymentStatus,
        'description': input.description,
        'receiptNumber': receiptNumber,
        'createdByUid': input.createdByUid,
        'createdByName': input.createdByName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'notes': input.notes,
        'metadata': input.metadata,
      });

      if (subscriptionRef != null) {
        transaction.set(
          subscriptionRef,
          {
            'paymentStatus': input.paymentStatus,
            'updatedAt': FieldValue.serverTimestamp(),
            'lastPaymentAt': FieldValue.serverTimestamp(),
            'lastTransactionId': transactionRef.id,
            'lastReceiptNumber': receiptNumber,
          },
          SetOptions(merge: true),
        );
      }

      if (memberRef != null) {
        transaction.set(
          memberRef,
          {
            'paymentStatus': input.paymentStatus,
            if (subscription != null) ...{
              'currentPlanId': subscription.planId,
              'currentPlanName': subscription.planName,
              'subscriptionStatus': subscription.status,
              'subscriptionEndDate': subscription.endDate == null
                  ? null
                  : Timestamp.fromDate(subscription.endDate!),
            },
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });

    return CreatedTransaction(
      id: transactionRef.id,
      receiptNumber: receiptNumber!,
    );
  }

  Future<CreatedTransaction> createRenewalPayment({
    required String gymId,
    required CreateRenewalPaymentInput input,
  }) async {
    if (gymId.trim().isEmpty) {
      throw StateError('Current gym is required.');
    }
    if (input.memberId.trim().isEmpty) {
      throw StateError('Select a member first.');
    }
    if (input.planId.trim().isEmpty) {
      throw StateError('Plan is required for renewal.');
    }
    if (!input.amount.isFinite || input.amount <= 0) {
      throw StateError('Amount must be greater than zero.');
    }
    if (input.paymentMethod.trim().isEmpty ||
        input.paymentMethod == TransactionPaymentMethod.unknown) {
      throw StateError('Payment method is required.');
    }

    final db = _paths.gymDoc(gymId).firestore;
    final memberRef = _paths.memberDoc(gymId, input.memberId.trim());
    final planRef = _paths.planDoc(gymId, input.planId.trim());
    final baseSubscriptionRef = input.baseSubscriptionId == null ||
            input.baseSubscriptionId!.trim().isEmpty
        ? null
        : _paths.subscriptionDoc(gymId, input.baseSubscriptionId!.trim());
    final counterRef = _paths.settingsCollection(gymId).doc('receiptCounter');
    final transactionRef = _paths.transactionsCollection(gymId).doc();
    final subscriptionRef = _activatesSubscription(input.paymentStatus)
        ? _paths.subscriptionsCollection(gymId).doc()
        : null;

    String? receiptNumber;

    await db.runTransaction((transaction) async {
      final memberSnap = await transaction.get(memberRef);
      if (!memberSnap.exists) {
        throw StateError('Member not found.');
      }
      final member = Member.fromFirestore(memberSnap);

      final planSnap = await transaction.get(planRef);
      if (!planSnap.exists) {
        throw StateError('Plan not found.');
      }
      final plan = MembershipPlan.fromFirestore(planSnap);
      if (!plan.isActive) {
        throw StateError('Plan is not active.');
      }
      if (plan.durationDays <= 0) {
        throw StateError('Plan duration must be greater than zero.');
      }

      GymSubscription? baseSubscription;
      if (baseSubscriptionRef != null) {
        final baseSnap = await transaction.get(baseSubscriptionRef);
        if (baseSnap.exists) {
          final candidate = GymSubscription.fromFirestore(baseSnap);
          if (candidate.memberId == member.id && candidate.planId == plan.id) {
            baseSubscription = candidate;
          }
        }
      }

      final counterSnap = await transaction.get(counterRef);
      final counterData = counterSnap.data() ?? <String, dynamic>{};
      final nextSequence = ((counterData['lastNumber'] as num?) ?? 0).toInt() + 1;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateKey =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      receiptNumber =
          '${_gymReceiptPrefix(gymId)}-$dateKey-${nextSequence.toString().padLeft(4, '0')}';

      DateTime? startDate;
      DateTime? endDate;
      if (subscriptionRef != null) {
        final previousEnd = baseSubscription?.endDate;
        final nextStart = previousEnd == null
            ? today
            : DateTime(previousEnd.year, previousEnd.month, previousEnd.day)
                .add(const Duration(days: 1));
        startDate = nextStart.isAfter(today) ? nextStart : today;
        endDate = startDate.add(Duration(days: plan.durationDays));
      }

      transaction.set(
        counterRef,
        {
          'lastNumber': nextSequence,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (subscriptionRef != null && startDate != null && endDate != null) {
        transaction.set(subscriptionRef, {
          'gymId': gymId,
          'memberId': member.id,
          'memberName': member.fullName,
          'planId': plan.id,
          'planName': plan.name,
          'startDate': Timestamp.fromDate(startDate),
          'endDate': Timestamp.fromDate(endDate),
          'status': SubscriptionStatus.active,
          'paymentStatus': input.paymentStatus,
          'amount': input.amount,
          'currency': input.currency,
          'paymentMethod': input.paymentMethod,
          'createdBy': input.createdByUid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastPaymentAt': FieldValue.serverTimestamp(),
          'lastTransactionId': transactionRef.id,
          'lastReceiptNumber': receiptNumber,
          'renewedFromSubscriptionId': baseSubscription?.id,
          'notes': input.notes,
        });
      }

      transaction.set(transactionRef, {
        'gymId': gymId,
        'memberId': member.id,
        'memberName': member.fullName,
        'subscriptionId': subscriptionRef?.id,
        'planId': plan.id,
        'type': TransactionType.renewal,
        'amount': input.amount,
        'currency': input.currency,
        'paymentMethod': input.paymentMethod,
        'paymentStatus': input.paymentStatus,
        'description': 'Renewal for ${plan.name}',
        'receiptNumber': receiptNumber,
        'createdByUid': input.createdByUid,
        'createdByName': input.createdByName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'notes': input.notes,
        'metadata': {
          'source': 'phase_2h_subscription_renewal',
          'baseSubscriptionId': baseSubscription?.id,
          if (startDate != null) 'subscriptionStartDate': Timestamp.fromDate(startDate),
          if (endDate != null) 'subscriptionEndDate': Timestamp.fromDate(endDate),
        },
      });

      if (subscriptionRef != null && startDate != null && endDate != null) {
        transaction.set(
          memberRef,
          {
            'currentPlanId': plan.id,
            'currentPlanName': plan.name,
            'subscriptionStatus': SubscriptionStatus.active,
            'subscriptionStartDate': Timestamp.fromDate(startDate),
            'subscriptionEndDate': Timestamp.fromDate(endDate),
            'paymentStatus': input.paymentStatus,
            'lastPaymentAt': FieldValue.serverTimestamp(),
            'lastTransactionId': transactionRef.id,
            'lastReceiptNumber': receiptNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        transaction.set(
          memberRef,
          {
            'paymentStatus': input.paymentStatus,
            'lastTransactionId': transactionRef.id,
            'lastReceiptNumber': receiptNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });

    return CreatedTransaction(
      id: transactionRef.id,
      receiptNumber: receiptNumber!,
      subscriptionId: subscriptionRef?.id,
    );
  }

  String _gymReceiptPrefix(String gymId) {
    final compact = gymId
        .replaceAll(RegExp('[^A-Za-z0-9]'), '')
        .toUpperCase()
        .replaceFirst(RegExp('^GYM'), '');
    final suffix = compact.isEmpty ? gymId.hashCode.abs().toString() : compact;
    return 'GYM${suffix.padLeft(3, '0')}';
  }

  bool _activatesSubscription(String paymentStatus) {
    return paymentStatus == TransactionPaymentStatus.paid ||
        paymentStatus == TransactionPaymentStatus.partial;
  }
}
