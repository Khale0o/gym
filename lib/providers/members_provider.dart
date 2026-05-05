import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/providers/auth_provider.dart';

/// Streams the full members list ordered by name.
final membersProvider = StreamProvider<List<Member>>((ref) {
  final gymId = ref.watch(currentGymIdProvider)?.trim();
  if (gymId == null || gymId.isEmpty) {
    throw StateError('Missing gym context for members.');
  }
  return FirebaseFirestore.instance
      .collection('gyms')
      .doc(gymId)
      .collection('members')
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(Member.fromFirestore).toList());
});

/// Provides a single member by id (reads from the members stream).
final memberByIdProvider =
    Provider.family<AsyncValue<Member?>, String>((ref, id) {
  return ref.watch(membersProvider).whenData(
        (list) => list.cast<Member?>().firstWhere(
              (m) => m!.id == id,
              orElse: () => null,
            ),
      );
});
