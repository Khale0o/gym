import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/models/plan.dart';
import 'package:gymsaas/models/transaction_model.dart';
import 'package:gymsaas/models/staff.dart';

/// Streams the list of gym plans.
final plansProvider = StreamProvider<List<GymPlan>>((ref) {
  return FirebaseFirestore.instance
      .collection('plans')
      .snapshots()
      .map((snap) => snap.docs.map(GymPlan.fromFirestore).toList());
});

/// Streams all transactions ordered by date descending.
final transactionsProvider = StreamProvider<List<GymTransaction>>((ref) {
  return FirebaseFirestore.instance
      .collection('transactions')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(GymTransaction.fromFirestore).toList());
});

/// Streams the staff list ordered by name.
final staffProvider = StreamProvider<List<Staff>>((ref) {
  return FirebaseFirestore.instance
      .collection('staff')
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(Staff.fromFirestore).toList());
});
