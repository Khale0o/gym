import 'package:gymsaas/models/gym_expense.dart';
import 'package:gymsaas/models/product_sale.dart';
import 'package:gymsaas/models/staff_payroll.dart';
import 'package:gymsaas/models/transaction_model.dart';

class FinanceSummary {
  const FinanceSummary({
    required this.month,
    required this.membershipRevenue,
    required this.productRevenue,
    required this.totalRevenue,
    required this.operatingExpenses,
    required this.staffSalaryCosts,
    required this.productCosts,
    required this.totalCosts,
    required this.grossProductProfit,
    required this.netProfit,
    required this.pendingExpenses,
    required this.pendingPayroll,
    required this.pendingProductSales,
    required this.unpaidOrPartialReceipts,
    required this.paidReceiptsCount,
    required this.partialReceiptsCount,
    required this.paidProductSalesCount,
    required this.paidExpensesCount,
    required this.paidPayrollCount,
    required this.revenueByPaymentMethod,
    required this.expensesByCategory,
    required this.productSalesByCategory,
    required this.payrollByRole,
    required this.recentIncomeTransactions,
    required this.recentProductSales,
    required this.recentExpenses,
    required this.recentPayrollEntries,
  });

  final DateTime month;
  final double membershipRevenue;
  final double productRevenue;
  final double totalRevenue;
  final double operatingExpenses;
  final double staffSalaryCosts;
  final double productCosts;
  final double totalCosts;
  final double grossProductProfit;
  final double netProfit;
  final double pendingExpenses;
  final double pendingPayroll;
  final double pendingProductSales;
  final double unpaidOrPartialReceipts;
  final int paidReceiptsCount;
  final int partialReceiptsCount;
  final int paidProductSalesCount;
  final int paidExpensesCount;
  final int paidPayrollCount;
  final Map<String, double> revenueByPaymentMethod;
  final Map<String, double> expensesByCategory;
  final Map<String, double> productSalesByCategory;
  final Map<String, double> payrollByRole;
  final List<GymTransaction> recentIncomeTransactions;
  final List<ProductSale> recentProductSales;
  final List<GymExpense> recentExpenses;
  final List<GymStaffPayroll> recentPayrollEntries;

  double get pendingObligations => pendingExpenses + pendingPayroll;

  bool get isEmptyMonth {
    return totalRevenue == 0 &&
        totalCosts == 0 &&
        pendingObligations == 0 &&
        pendingProductSales == 0 &&
        recentIncomeTransactions.isEmpty &&
        recentProductSales.isEmpty &&
        recentExpenses.isEmpty &&
        recentPayrollEntries.isEmpty;
  }
}
