import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/models/checkin.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';

/// Streams recent check-ins from `gyms/{gymId}/checkins`.
final recentCheckinsProvider = StreamProvider<List<CheckIn>>((ref) {
  final gymId = ref.watch(currentGymIdProvider)?.trim();
  if (gymId == null || gymId.isEmpty) {
    throw StateError('Missing gym context for check-ins.');
  }
  return ref.watch(checkInRepositoryProvider).streamRecentCheckins(gymId);
});
