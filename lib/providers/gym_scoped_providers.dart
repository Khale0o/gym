import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/models/checkin.dart';
import 'package:gymsaas/models/dashboard_summary.dart';
import 'package:gymsaas/models/gym_settings.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/models/membership_plan.dart';
import 'package:gymsaas/models/staff.dart';
import 'package:gymsaas/models/staff_invite.dart';
import 'package:gymsaas/models/subscription.dart';
import 'package:gymsaas/models/transaction_model.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/repositories/checkin_repository.dart';
import 'package:gymsaas/repositories/dashboard_repository.dart';
import 'package:gymsaas/repositories/gym_settings_repository.dart';
import 'package:gymsaas/repositories/member_invite_repository.dart';
import 'package:gymsaas/repositories/member_repository.dart';
import 'package:gymsaas/repositories/plan_repository.dart';
import 'package:gymsaas/repositories/staff_repository.dart';
import 'package:gymsaas/repositories/staff_invite_repository.dart';
import 'package:gymsaas/repositories/subscription_repository.dart';
import 'package:gymsaas/repositories/transaction_repository.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

final gymFirestorePathsProvider = Provider<GymFirestorePaths>((ref) {
  return GymFirestorePaths(ref.watch(firestoreProvider));
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(ref.watch(gymFirestorePathsProvider));
});

final memberInviteRepositoryProvider = Provider<MemberInviteRepository>((ref) {
  return MemberInviteRepository(
    ref.watch(firestoreProvider),
    ref.watch(gymFirestorePathsProvider),
  );
});

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(ref.watch(gymFirestorePathsProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(gymFirestorePathsProvider));
});

final gymSettingsRepositoryProvider = Provider<GymSettingsRepository>((ref) {
  return GymSettingsRepository(ref.watch(gymFirestorePathsProvider));
});

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(ref.watch(gymFirestorePathsProvider));
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(gymFirestorePathsProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(gymFirestorePathsProvider));
});

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(gymFirestorePathsProvider));
});

final staffInviteRepositoryProvider = Provider<StaffInviteRepository>((ref) {
  return StaffInviteRepository(
    ref.watch(firestoreProvider),
    ref.watch(gymFirestorePathsProvider),
  );
});

final gymMembersProvider = StreamProvider<List<Member>>((ref) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(memberRepositoryProvider).streamMembers(gymId);
});

final gymMemberByIdProvider =
    FutureProvider.family<Member?, String>((ref, memberId) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(memberRepositoryProvider).getMember(gymId, memberId);
});

final currentLinkedMemberProvider = FutureProvider<Member?>((ref) {
  final gymId = _requireCurrentGymId(ref);
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) {
    throw StateError('No signed-in user is available.');
  }
  return ref.watch(memberRepositoryProvider).getMemberByAuthUid(gymId, user.uid);
});

final gymStaffProvider = StreamProvider<List<Staff>>((ref) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(staffRepositoryProvider).streamStaff(gymId);
});

final gymStaffByIdProvider =
    FutureProvider.family<Staff?, String>((ref, staffId) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(staffRepositoryProvider).getStaff(gymId, staffId);
});

final gymStaffInvitesProvider = StreamProvider<List<StaffInvite>>((ref) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(staffInviteRepositoryProvider).streamStaffInvites(gymId);
});

final gymPlansProvider = StreamProvider<List<MembershipPlan>>((ref) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(planRepositoryProvider).streamPlans(gymId);
});

final gymActivePlansProvider = StreamProvider<List<MembershipPlan>>((ref) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(planRepositoryProvider).streamActivePlans(gymId);
});

final gymSubscriptionsProvider = StreamProvider<List<GymSubscription>>((ref) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(subscriptionRepositoryProvider).streamSubscriptions(gymId);
});

final gymTransactionsProvider = StreamProvider<List<GymTransaction>>((ref) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(transactionRepositoryProvider).streamTransactions(gymId);
});

final dashboardSummaryProvider = StreamProvider<DashboardSummary>((ref) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(dashboardRepositoryProvider).streamSummary(gymId);
});

final gymProfileProvider = StreamProvider<GymProfileSettings>((ref) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(gymSettingsRepositoryProvider).streamGymProfile(gymId);
});

final occupancySettingsProvider = StreamProvider<OccupancySettings>((ref) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(gymSettingsRepositoryProvider).streamOccupancySettings(gymId);
});

final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  final gymId = _requireCurrentGymId(ref);
  return ref.watch(gymSettingsRepositoryProvider).streamAppSettings(gymId);
});

final memberTransactionsProvider =
    StreamProvider.family<List<GymTransaction>, String>((ref, memberId) {
  final gymId = _requireCurrentGymId(ref);
  return ref
      .watch(transactionRepositoryProvider)
      .streamMemberTransactions(gymId, memberId);
});

final memberSubscriptionsProvider =
    StreamProvider.family<List<GymSubscription>, String>((ref, memberId) {
  final gymId = _requireCurrentGymId(ref);
  return ref
      .watch(subscriptionRepositoryProvider)
      .streamMemberSubscriptions(gymId, memberId);
});

final memberCheckinsProvider =
    StreamProvider.family<List<CheckIn>, String>((ref, memberId) {
  final gymId = _requireCurrentGymId(ref);
  return ref
      .watch(checkInRepositoryProvider)
      .streamMemberCheckins(gymId, memberId);
});

final activeMemberSubscriptionProvider =
    StreamProvider.family<GymSubscription?, String>((ref, memberId) {
  final gymId = _requireCurrentGymId(ref);
  return ref
      .watch(subscriptionRepositoryProvider)
      .streamActiveSubscriptionForMember(gymId, memberId);
});

String _requireCurrentGymId(Ref ref) {
  final gymId = ref.watch(currentGymIdProvider)?.trim();
  if (gymId == null || gymId.isEmpty) {
    throw StateError(
      'No current gym is selected. users/{uid}.defaultGymId is required.',
    );
  }
  return gymId;
}
