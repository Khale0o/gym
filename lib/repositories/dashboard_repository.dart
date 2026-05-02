import 'dart:async';

import 'package:gymsaas/models/checkin.dart';
import 'package:gymsaas/models/dashboard_summary.dart';
import 'package:gymsaas/models/effective_subscription_status.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/models/subscription.dart';
import 'package:gymsaas/models/transaction_model.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class DashboardRepository {
  DashboardRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<DashboardSummary> streamSummary(String gymId) {
    final controller = StreamController<DashboardSummary>();
    var members = <Member>[];
    var subscriptions = <GymSubscription>[];
    var transactions = <GymTransaction>[];
    var checkins = <CheckIn>[];
    var occupancyCount = 0;
    var occupancyCapacity = 0;
    var hasMembers = false;
    var hasSubscriptions = false;
    var hasTransactions = false;
    var hasCheckins = false;
    var hasOccupancy = false;

    void emitIfReady() {
      if (!hasMembers ||
          !hasSubscriptions ||
          !hasTransactions ||
          !hasCheckins ||
          !hasOccupancy ||
          controller.isClosed) {
        return;
      }

      controller.add(
        _buildSummary(
          DashboardSourceData(
            members: members,
            subscriptions: subscriptions,
            transactions: transactions,
            checkins: checkins,
            occupancyCount: occupancyCount,
            occupancyCapacity: occupancyCapacity,
          ),
        ),
      );
    }

    final subscriptionsToCancel = <StreamSubscription<dynamic>>[];

    subscriptionsToCancel.add(
      _paths.membersCollection(gymId).snapshots().listen(
        (snap) {
          members = snap.docs.map(Member.fromFirestore).toList();
          hasMembers = true;
          emitIfReady();
        },
        onError: controller.addError,
      ),
    );

    subscriptionsToCancel.add(
      _paths.subscriptionsCollection(gymId).snapshots().listen(
        (snap) {
          subscriptions = snap.docs.map(GymSubscription.fromFirestore).toList();
          hasSubscriptions = true;
          emitIfReady();
        },
        onError: controller.addError,
      ),
    );

    subscriptionsToCancel.add(
      _paths.transactionsCollection(gymId).snapshots().listen(
        (snap) {
          transactions = snap.docs.map(GymTransaction.fromFirestore).toList();
          hasTransactions = true;
          emitIfReady();
        },
        onError: controller.addError,
      ),
    );

    subscriptionsToCancel.add(
      _paths.checkinsCollection(gymId).snapshots().listen(
        (snap) {
          checkins = snap.docs.map(CheckIn.fromFirestore).toList();
          hasCheckins = true;
          emitIfReady();
        },
        onError: controller.addError,
      ),
    );

    subscriptionsToCancel.add(
      _paths.occupancyDoc(gymId).snapshots().listen(
        (snap) {
          final data = snap.data() ?? <String, dynamic>{};
          occupancyCount = _safeInt(data['count']);
          occupancyCapacity = _safeCapacity(data);
          hasOccupancy = true;
          emitIfReady();
        },
        onError: controller.addError,
      ),
    );

    controller.onCancel = () async {
      for (final sub in subscriptionsToCancel) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  DashboardSummary _buildSummary(DashboardSourceData data) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month);

    final activeMembers = data.members.where((member) {
      final status = member.status.trim().toLowerCase();
      final accountStatus = member.accountStatus?.trim().toLowerCase();
      return status == 'active' &&
          (accountStatus == null ||
              accountStatus.isEmpty ||
              accountStatus == 'active');
    }).length;

    var activeSubscriptions = 0;
    var expiredSubscriptions = 0;
    var expiringSoonSubscriptions = 0;
    var partialSubscriptions = 0;
    final expiringSoonItems = <GymSubscription>[];
    final expiredItems = <GymSubscription>[];

    for (final subscription in data.subscriptions) {
      final status = resolveEffectiveSubscriptionStatus(
        subscriptionStatus: subscription.status,
        subscriptionEndDate: subscription.endDate,
        paymentStatus: subscription.paymentStatus,
      ).status;

      if (status == EffectiveSubscriptionStatus.expired) {
        expiredSubscriptions++;
        expiredItems.add(subscription);
      }
      if (status == EffectiveSubscriptionStatus.active ||
          status == EffectiveSubscriptionStatus.expiringSoon ||
          status == EffectiveSubscriptionStatus.partial) {
        activeSubscriptions++;
      }
      if (status == EffectiveSubscriptionStatus.expiringSoon) {
        expiringSoonSubscriptions++;
        expiringSoonItems.add(subscription);
      }
      if (status == EffectiveSubscriptionStatus.partial) {
        partialSubscriptions++;
      }
    }

    final todayCheckinItems = data.checkins.where((checkin) {
      return _isInRange(checkin.time, today, tomorrow);
    }).toList()
      ..sort((a, b) => b.time.compareTo(a.time));

    final revenueTransactions = data.transactions.where((transaction) {
      return transaction.paymentStatus == TransactionPaymentStatus.paid ||
          transaction.paymentStatus == TransactionPaymentStatus.partial;
    }).toList();

    final todayTransactions = revenueTransactions
        .where((transaction) => _isInRange(transaction.date, today, tomorrow))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final monthTransactions = revenueTransactions
        .where((transaction) => !transaction.date.isBefore(monthStart))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final todayRevenue = todayTransactions.fold<double>(
      0,
      (total, transaction) => total + transaction.amount,
    );
    final monthRevenue = monthTransactions.fold<double>(
      0,
      (total, transaction) => total + transaction.amount,
    );

    final recentTransactions = [...data.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentCheckins = [...data.checkins]
      ..sort((a, b) => b.time.compareTo(a.time));

    return DashboardSummary(
      totalMembers: data.members.length,
      activeMembers: activeMembers,
      activeSubscriptions: activeSubscriptions,
      expiredSubscriptions: expiredSubscriptions,
      expiringSoonSubscriptions: expiringSoonSubscriptions,
      todayCheckins: todayCheckinItems.length,
      todayRevenue: todayRevenue,
      monthRevenue: monthRevenue,
      occupancyCount: data.occupancyCount,
      occupancyCapacity: data.occupancyCapacity,
      recentTransactions: recentTransactions.take(10).toList(),
      recentCheckins: recentCheckins.take(10).toList(),
      partialSubscriptions: partialSubscriptions,
      expiringSoonItems: _sortSubscriptionsByEndDate(expiringSoonItems)
          .take(10)
          .toList(),
      expiredItems: _sortSubscriptionsByEndDate(expiredItems).take(10).toList(),
      todayTransactions: todayTransactions.take(10).toList(),
      monthTransactions: monthTransactions.take(10).toList(),
      todayCheckinItems: todayCheckinItems.take(10).toList(),
    );
  }

  List<GymSubscription> _sortSubscriptionsByEndDate(
    List<GymSubscription> subscriptions,
  ) {
    return [...subscriptions]
      ..sort((a, b) {
        final aEnd = a.endDate ?? DateTime(9999);
        final bEnd = b.endDate ?? DateTime(9999);
        return aEnd.compareTo(bEnd);
      });
  }

  bool _isInRange(DateTime value, DateTime start, DateTime end) {
    return !value.isBefore(start) && value.isBefore(end);
  }

  static int _safeInt(dynamic value) {
    final number = value is num ? value.toInt() : 0;
    return number < 0 ? 0 : number;
  }

  static int _safeCapacity(Map<String, dynamic> data) {
    for (final key in const ['capacity', 'maxCapacity', 'gymCapacity']) {
      final value = _safeInt(data[key]);
      if (value > 0) return value;
    }
    return 0;
  }
}
