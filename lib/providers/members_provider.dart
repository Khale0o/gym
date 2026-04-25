import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/models/member.dart';

/// Streams the full members list ordered by name.
final membersProvider = StreamProvider<List<Member>>((ref) {
  return FirebaseFirestore.instance
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
