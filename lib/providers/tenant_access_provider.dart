import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/models/gym_tenant.dart';
import 'package:gymsaas/navigation/role_access.dart';
import 'package:gymsaas/providers/auth_provider.dart';

final currentGymTenantAccessProvider =
    StreamProvider<GymTenantAccess?>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null || isPlatformOwnerRole(profile.role)) {
    return Stream.value(null);
  }

  final gymId = profile.defaultGymId?.trim();
  if (gymId == null || gymId.isEmpty) {
    return Stream.value(null);
  }

  return ref
      .watch(firestoreProvider)
      .collection('gyms')
      .doc(gymId)
      .snapshots()
      .map(GymTenantAccess.fromFirestore);
});
