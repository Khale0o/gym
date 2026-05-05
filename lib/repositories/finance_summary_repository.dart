import 'dart:async';

import 'package:gymsaas/models/finance_summary.dart';
import 'package:gymsaas/models/gym_expense.dart';
import 'package:gymsaas/models/product_sale.dart';
import 'package:gymsaas/models/staff_payroll.dart';
import 'package:gymsaas/models/transaction_model.dart';
import 'package:gymsaas/repositories/expense_repository.dart';
import 'package:gymsaas/repositories/product_sales_repository.dart';
import 'package:gymsaas/repositories/staff_payroll_repository.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class FinanceSummaryRepository {
  FinanceSummaryRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<FinanceSummary> streamSummaryForMonth(
    String gymId,
    DateTime monthDate,
  ) {
    final controller = StreamController<FinanceSummary>();
    final expensesRepo = ExpenseRepository(_paths);
    final payrollRepo = StaffPayrollRepository(_paths);
    final salesRepo = ProductSalesRepository(_paths);

    var transactions = <GymTransaction>[];
    var expenses = <GymExpense>[];
    var payroll = <GymStaffPayroll>[];
    var sales = <ProductSale>[];
    var hasTransactions = false;
    var hasExpenses = false;
    var hasPayroll = false;
    var hasSales = false;

    void emitIfReady() {
      if (!hasTransactions ||
          !hasExpenses ||
          !hasPayroll ||
          !hasSales ||
          controller.isClosed) {
        return;
      }
      controller.add(
        buildSummary(
          monthDate: monthDate,
          transactions: transactions,
          expenses: expenses,
          payroll: payroll,
          sales: sales,
        ),
      );
    }

    final subs = <StreamSubscription<dynamic>>[];
    subs.add(_paths.transactionsCollection(gymId).snapshots().listen((snap) {
      final range = _monthRange(monthDate);
      transactions = snap.docs
          .map(GymTransaction.fromFirestore)
          .where((tx) => _inRange(tx.createdAt ?? tx.date, range))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      hasTransactions = true;
      emitIfReady();
    }, onError: controller.addError));

    subs.add(expensesRepo.streamExpensesForMonth(gymId, monthDate).listen((rows) {
      expenses = rows;
      hasExpenses = true;
      emitIfReady();
    }, onError: controller.addError));

    subs.add(payrollRepo.streamPayrollForMonth(gymId, monthDate).listen((rows) {
      payroll = rows;
      hasPayroll = true;
      emitIfReady();
    }, onError: controller.addError));

    subs.add(salesRepo.streamSalesForMonth(gymId, monthDate).listen((rows) {
      sales = rows;
      hasSales = true;
      emitIfReady();
    }, onError: controller.addError));

    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };
    return controller.stream;
  }

  FinanceSummary buildSummary({
    required DateTime monthDate,
    required List<GymTransaction> transactions,
    required List<GymExpense> expenses,
    required List<GymStaffPayroll> payroll,
    required List<ProductSale> sales,
  }) {
    final paidTransactions = transactions.where((tx) {
      return tx.paymentStatus == TransactionPaymentStatus.paid ||
          tx.paymentStatus == TransactionPaymentStatus.partial;
    }).toList();
    final paidSales =
        sales.where((sale) => sale.status == ProductSaleStatus.paid).toList();
    final paidExpenses =
        expenses.where((item) => item.status == GymExpenseStatus.paid).toList();
    final paidPayroll =
        payroll.where((item) => item.status == StaffPayrollStatus.paid).toList();

    final membershipRevenue = _sum(paidTransactions, (tx) => tx.amount);
    final productRevenue = _sum(paidSales, (sale) => sale.totalRevenue);
    final operatingExpenses = _sum(paidExpenses, (item) => item.amount);
    final staffSalaryCosts = _sum(paidPayroll, (item) => item.salaryAmount);
    final productCosts = _sum(paidSales, (sale) => sale.totalCost);
    final totalRevenue = membershipRevenue + productRevenue;
    final totalCosts = operatingExpenses + staffSalaryCosts + productCosts;

    return FinanceSummary(
      month: DateTime(monthDate.year, monthDate.month),
      membershipRevenue: membershipRevenue,
      productRevenue: productRevenue,
      totalRevenue: totalRevenue,
      operatingExpenses: operatingExpenses,
      staffSalaryCosts: staffSalaryCosts,
      productCosts: productCosts,
      totalCosts: totalCosts,
      grossProductProfit: productRevenue - productCosts,
      netProfit: totalRevenue - totalCosts,
      pendingExpenses: _sum(
        expenses.where((item) => item.status == GymExpenseStatus.pending),
        (item) => item.amount,
      ),
      pendingPayroll: _sum(
        payroll.where((item) => item.status == StaffPayrollStatus.pending),
        (item) => item.salaryAmount,
      ),
      pendingProductSales: _sum(
        sales.where((item) => item.status == ProductSaleStatus.pending),
        (item) => item.totalRevenue,
      ),
      unpaidOrPartialReceipts: _sum(
        transactions.where((tx) =>
            tx.paymentStatus == TransactionPaymentStatus.partial ||
            tx.paymentStatus == TransactionPaymentStatus.unpaid),
        (tx) => tx.amount,
      ),
      paidReceiptsCount: transactions
          .where((tx) => tx.paymentStatus == TransactionPaymentStatus.paid)
          .length,
      partialReceiptsCount: transactions
          .where((tx) => tx.paymentStatus == TransactionPaymentStatus.partial)
          .length,
      paidProductSalesCount: paidSales.length,
      paidExpensesCount: paidExpenses.length,
      paidPayrollCount: paidPayroll.length,
      revenueByPaymentMethod: _group(
        [...paidTransactions, ...paidSales],
        (item) => item is GymTransaction ? item.paymentMethod : (item as ProductSale).paymentMethod,
        (item) => item is GymTransaction ? item.amount : (item as ProductSale).totalRevenue,
      ),
      expensesByCategory: _group(
        paidExpenses,
        (item) => item.category,
        (item) => item.amount,
      ),
      productSalesByCategory: _group(
        paidSales,
        (item) => item.productCategory,
        (item) => item.totalRevenue,
      ),
      payrollByRole: _group(
        paidPayroll,
        (item) => item.role.trim().isEmpty ? 'unknown' : item.role,
        (item) => item.salaryAmount,
      ),
      recentIncomeTransactions: paidTransactions.take(10).toList(),
      recentProductSales: sales.take(10).toList(),
      recentExpenses: expenses.take(10).toList(),
      recentPayrollEntries: payroll.take(10).toList(),
    );
  }
}

({DateTime start, DateTime end}) _monthRange(DateTime monthDate) {
  final start = DateTime(monthDate.year, monthDate.month);
  final end = DateTime(monthDate.year, monthDate.month + 1);
  return (start: start, end: end);
}

bool _inRange(DateTime date, ({DateTime start, DateTime end}) range) {
  return !date.isBefore(range.start) && date.isBefore(range.end);
}

double _sum<T>(Iterable<T> rows, double Function(T row) valueOf) {
  return rows.fold<double>(0, (total, row) => total + valueOf(row));
}

Map<String, double> _group<T>(
  Iterable<T> rows,
  String Function(T row) keyOf,
  double Function(T row) valueOf,
) {
  final result = <String, double>{};
  for (final row in rows) {
    final key = keyOf(row).trim().isEmpty ? 'unknown' : keyOf(row).trim();
    result[key] = (result[key] ?? 0) + valueOf(row);
  }
  return result;
}
