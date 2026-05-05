import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/models/finance_summary.dart';
import 'package:gymsaas/models/gym_product.dart';
import 'package:gymsaas/models/plan.dart';
import 'package:gymsaas/models/transaction_model.dart';
import 'package:gymsaas/models/staff.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/repositories/expense_repository.dart';
import 'package:gymsaas/repositories/finance_summary_repository.dart';
import 'package:gymsaas/repositories/product_repository.dart';
import 'package:gymsaas/repositories/product_sales_repository.dart';
import 'package:gymsaas/repositories/staff_payroll_repository.dart';

/// Streams the list of gym plans.
final plansProvider = StreamProvider<List<GymPlan>>((ref) {
  final gymId = _requireGymId(ref);
  return FirebaseFirestore.instance
      .collection('gyms')
      .doc(gymId)
      .collection('plans')
      .snapshots()
      .map((snap) => snap.docs.map(GymPlan.fromFirestore).toList());
});

/// Streams all transactions ordered by date descending.
final transactionsProvider = StreamProvider<List<GymTransaction>>((ref) {
  final gymId = _requireGymId(ref);
  return FirebaseFirestore.instance
      .collection('gyms')
      .doc(gymId)
      .collection('transactions')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(GymTransaction.fromFirestore).toList());
});

/// Streams the staff list ordered by name.
final staffProvider = StreamProvider<List<Staff>>((ref) {
  final gymId = _requireGymId(ref);
  return FirebaseFirestore.instance
      .collection('gyms')
      .doc(gymId)
      .collection('staff')
      .orderBy('fullName')
      .snapshots()
      .map((snap) => snap.docs.map(Staff.fromFirestore).toList());
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(gymFirestorePathsProvider));
});

final staffPayrollRepositoryProvider = Provider<StaffPayrollRepository>((ref) {
  return StaffPayrollRepository(ref.watch(gymFirestorePathsProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(gymFirestorePathsProvider));
});

final productSalesRepositoryProvider = Provider<ProductSalesRepository>((ref) {
  return ProductSalesRepository(ref.watch(gymFirestorePathsProvider));
});

final financeSummaryRepositoryProvider = Provider<FinanceSummaryRepository>((ref) {
  return FinanceSummaryRepository(ref.watch(gymFirestorePathsProvider));
});

final financeSummaryProvider =
    StreamProvider.family<FinanceSummary, DateTime>((ref, monthDate) {
  final gymId = _requireGymId(ref);
  return ref
      .watch(financeSummaryRepositoryProvider)
      .streamSummaryForMonth(gymId, monthDate);
});

final gymProductsProvider = StreamProvider<List<GymProduct>>((ref) {
  final gymId = _requireGymId(ref);
  return ref.watch(productRepositoryProvider).streamProducts(gymId);
});

final activeGymProductsProvider = StreamProvider<List<GymProduct>>((ref) {
  final gymId = _requireGymId(ref);
  return ref.watch(productRepositoryProvider).streamActiveProducts(gymId);
});

String _requireGymId(Ref ref) {
  final gymId = ref.watch(currentGymIdProvider)?.trim();
  if (gymId == null || gymId.isEmpty) {
    throw StateError('Missing gym context for operations.');
  }
  return gymId;
}
