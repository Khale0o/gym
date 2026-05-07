import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/models/gym_tenant.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/repositories/platform_admin_repository.dart';

final platformAdminRepositoryProvider = Provider<PlatformAdminRepository>((ref) {
  return PlatformAdminRepository(ref.watch(firestoreProvider));
});

final platformGymsProvider = StreamProvider<List<PlatformGym>>((ref) {
  return ref.watch(platformAdminRepositoryProvider).streamGyms();
});
