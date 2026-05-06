import 'package:gymsaas/models/checkin.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/models/subscription.dart';
import 'package:gymsaas/models/transaction_model.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.totalMembers,
    required this.activeMembers,
    required this.activeSubscriptions,
    required this.expiredSubscriptions,
    required this.expiringSoonSubscriptions,
    required this.todayCheckins,
    required this.todayRevenue,
    required this.monthRevenue,
    required this.occupancyCount,
    required this.occupancyCapacity,
    required this.recentTransactions,
    required this.recentCheckins,
    required this.partialSubscriptions,
    required this.expiringSoonItems,
    required this.expiredItems,
    required this.todayTransactions,
    required this.monthTransactions,
    required this.todayCheckinItems,
    required this.memberItems,
    required this.activeMemberItems,
    required this.activeSubscriptionItems,
  });

  final int totalMembers;
  final int activeMembers;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final int expiringSoonSubscriptions;
  final int todayCheckins;
  final double todayRevenue;
  final double monthRevenue;
  final int occupancyCount;
  final int occupancyCapacity;
  final List<GymTransaction> recentTransactions;
  final List<CheckIn> recentCheckins;
  final int partialSubscriptions;
  final List<GymSubscription> expiringSoonItems;
  final List<GymSubscription> expiredItems;
  final List<GymTransaction> todayTransactions;
  final List<GymTransaction> monthTransactions;
  final List<CheckIn> todayCheckinItems;
  final List<Member> memberItems;
  final List<Member> activeMemberItems;
  final List<GymSubscription> activeSubscriptionItems;

  bool get isEmptyGym =>
      totalMembers == 0 &&
      activeSubscriptions == 0 &&
      recentTransactions.isEmpty &&
      recentCheckins.isEmpty;
}

class DashboardSourceData {
  const DashboardSourceData({
    required this.members,
    required this.subscriptions,
    required this.transactions,
    required this.checkins,
    required this.occupancyCount,
    required this.occupancyCapacity,
  });

  final List<Member> members;
  final List<GymSubscription> subscriptions;
  final List<GymTransaction> transactions;
  final List<CheckIn> checkins;
  final int occupancyCount;
  final int occupancyCapacity;
}
