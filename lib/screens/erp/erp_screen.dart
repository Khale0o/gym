import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/firestore_error_messages.dart';
import 'package:gymsaas/core/helpers.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/models/finance_summary.dart';
import 'package:gymsaas/models/gym_expense.dart';
import 'package:gymsaas/models/gym_product.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/models/product_sale.dart';
import 'package:gymsaas/models/staff.dart';
import 'package:gymsaas/models/staff_payroll.dart';
import 'package:gymsaas/models/transaction_model.dart';
import 'package:gymsaas/navigation/role_capabilities.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/erp_provider.dart';
import 'package:gymsaas/providers/gym_scoped_providers.dart';
import 'package:gymsaas/widgets/apex_card.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';

class ErpScreen extends ConsumerStatefulWidget {
  const ErpScreen({super.key});

  @override
  ConsumerState<ErpScreen> createState() => _ErpScreenState();
}

class _ErpScreenState extends ConsumerState<ErpScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final activeProfile = profile?.status.trim().toLowerCase() == 'active';
    final canManageFinance =
        activeProfile && RoleCapabilities.canViewFinance(profile?.role ?? '');
    final summaryAsync = ref.watch(financeSummaryProvider(_month));
    final activeProductsAsync = ref.watch(activeGymProductsProvider);
    final productsAsync = ref.watch(gymProductsProvider);
    final membersAsync = ref.watch(gymMembersProvider);
    final staffAsync = ref.watch(gymStaffProvider);
    final isMobile = MediaQuery.of(context).size.width < 760;

    if (!canManageFinance) {
      return const Scaffold(
        backgroundColor: bgDark,
        body: Center(
          child: ApexText(
            'You do not have permission to access finance data.',
            color: redAlert,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FinanceHeader(
                month: _month,
                onPrevious: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                onNext: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
                onCurrent: () {
                  final now = DateTime.now();
                  setState(() => _month = DateTime(now.year, now.month));
                },
              ),
              const SizedBox(height: 14),
              _ActionBar(
                isMobile: isMobile,
                onAddExpense: () => _openExpenseDialog(),
                onAddProduct: () => _openProductDialog(),
                onSellProduct: () => _openProductSaleDialog(
                  activeProductsAsync.valueOrNull ?? const <GymProduct>[],
                  membersAsync.valueOrNull ?? const <Member>[],
                ),
                onAddPayroll: () => _openPayrollDialog(
                  staffAsync.valueOrNull ?? const <Staff>[],
                ),
              ),
              const SizedBox(height: 18),
              summaryAsync.when(
                loading: () => const _FinanceLoading(),
                error: (error, _) => _FinanceError(error: error),
                data: (summary) => _FinanceBody(
                  summary: summary,
                  isMobile: isMobile,
                  onCancelExpense: _cancelExpense,
                  onCancelSale: _cancelProductSale,
                  onCancelPayroll: _cancelPayroll,
                  onShowTransaction: _showTransactionDetails,
                  onShowExpense: _showExpenseDetails,
                  onShowSale: _showProductSaleDetails,
                  onShowPayroll: _showPayrollDetails,
                  products: productsAsync.valueOrNull ?? const <GymProduct>[],
                  onShowProduct: _showProductDetails,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openExpenseDialog() {
    return showDialog<void>(
      context: context,
      builder: (_) => const _ExpenseDialog(),
    );
  }

  Future<void> _openProductDialog() {
    return showDialog<void>(
      context: context,
      builder: (_) => const _ProductDialog(),
    );
  }

  Future<void> _openProductSaleDialog(
    List<GymProduct> products,
    List<Member> members,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => _ProductSaleDialog(products: products, members: members),
    );
  }

  Future<void> _openPayrollDialog(List<Staff> staff) {
    return showDialog<void>(
      context: context,
      builder: (_) => _PayrollDialog(staff: staff, month: _month),
    );
  }

  Future<void> _cancelExpense(GymExpense expense) async {
    final reason = await _askCancellationReason('Cancel Expense');
    if (reason == null) return;
    await _runAction(() async {
      final gymId = _currentGymId();
      final uid = ref.read(currentAuthUserProvider)?.uid ?? '';
      await ref.read(expenseRepositoryProvider).cancelExpense(
            gymId: gymId,
            expenseId: expense.id,
            cancelledBy: uid,
            reason: reason,
          );
      _showSnack('Expense cancelled.', greenSuccess);
    });
  }

  Future<void> _cancelProductSale(ProductSale sale) async {
    final reason = await _askCancellationReason('Cancel Product Sale');
    if (reason == null) return;
    await _runAction(() async {
      final gymId = _currentGymId();
      final uid = ref.read(currentAuthUserProvider)?.uid ?? '';
      await ref.read(productSalesRepositoryProvider).cancelProductSale(
            gymId: gymId,
            saleId: sale.id,
            cancelledBy: uid,
            reason: reason,
          );
      _showSnack('Product sale cancelled.', greenSuccess);
    });
  }

  Future<void> _cancelPayroll(GymStaffPayroll payroll) async {
    final reason = await _askCancellationReason('Cancel Payroll Entry');
    if (reason == null) return;
    await _runAction(() async {
      final gymId = _currentGymId();
      final uid = ref.read(currentAuthUserProvider)?.uid ?? '';
      await ref.read(staffPayrollRepositoryProvider).cancelPayrollPayment(
            gymId: gymId,
            payrollId: payroll.id,
            cancelledBy: uid,
            reason: reason,
          );
      _showSnack('Payroll entry cancelled.', greenSuccess);
    });
  }

  Future<String?> _askCancellationReason(String title) {
    return showDialog<String>(
      context: context,
      builder: (_) => _CancelReasonDialog(title: title),
    );
  }

  void _showTransactionDetails(GymTransaction transaction) {
    _showDetailsSheet(
      title: 'Receipt Details',
      rows: [
        _DetailRow('Receipt', transaction.receiptNumber),
        _DetailRow('Transaction ID', transaction.id),
        _DetailRow('Member', transaction.memberName),
        _DetailRow('Amount', _amount(transaction.amount, transaction.currency)),
        _DetailRow('Payment Method', _label(transaction.paymentMethod)),
        _DetailRow('Payment Status', _label(transaction.paymentStatus)),
        _DetailRow('Plan ID', transaction.planId),
        _DetailRow('Subscription ID', transaction.subscriptionId),
        _DetailRow('Created At', _formatDateTime(transaction.createdAt)),
        _DetailRow('Created By', transaction.createdByName ?? transaction.createdByUid),
        _DetailRow('Notes', transaction.notes),
        _DetailRow('Status', transaction.paymentStatus),
      ],
    );
  }

  void _showExpenseDetails(GymExpense expense) {
    _showDetailsSheet(
      title: 'Expense Details',
      rows: [
        _DetailRow('Expense ID', expense.id),
        _DetailRow('Title', expense.title),
        _DetailRow('Category', _label(expense.category)),
        _DetailRow('Amount', _amount(expense.amount, expense.currency)),
        _DetailRow('Payment Method', _label(expense.paymentMethod)),
        _DetailRow('Status', _label(expense.status)),
        _DetailRow('Expense Date', _formatDate(expense.date)),
        _DetailRow('Created At', _formatDateTime(expense.createdAt)),
        _DetailRow('Created By', expense.createdBy),
        _DetailRow('Notes', expense.notes),
        _DetailRow('Cancelled At', _formatDateTime(expense.cancelledAt)),
        _DetailRow('Cancelled By', expense.cancelledBy),
        _DetailRow('Cancellation Reason', expense.cancellationReason),
      ],
    );
  }

  void _showPayrollDetails(GymStaffPayroll payroll) {
    _showDetailsSheet(
      title: 'Payroll Details',
      rows: [
        _DetailRow('Payroll ID', payroll.id),
        _DetailRow('Staff', payroll.staffName),
        _DetailRow('Staff ID', payroll.staffId),
        _DetailRow('Role', payroll.role),
        _DetailRow('Salary Amount', _amount(payroll.salaryAmount, payroll.currency)),
        _DetailRow('Period', _formatMonth(payroll.periodMonth)),
        _DetailRow('Payment Date', _formatDate(payroll.paymentDate)),
        _DetailRow('Payment Method', _label(payroll.paymentMethod)),
        _DetailRow('Status', _label(payroll.status)),
        _DetailRow('Created At', _formatDateTime(payroll.createdAt)),
        _DetailRow('Created By', payroll.createdBy),
        _DetailRow('Notes', payroll.notes),
        _DetailRow('Cancelled At', _formatDateTime(payroll.cancelledAt)),
        _DetailRow('Cancelled By', payroll.cancelledBy),
        _DetailRow('Cancellation Reason', payroll.cancellationReason),
      ],
    );
  }

  void _showProductSaleDetails(ProductSale sale) {
    _showDetailsSheet(
      title: 'Product Sale Details',
      rows: [
        _DetailRow('Sale ID', sale.id),
        _DetailRow('Product', sale.productName),
        _DetailRow('Product ID', sale.productId),
        _DetailRow('Quantity', '${sale.quantity}'),
        _DetailRow('Unit Price', _amount(sale.unitSellingPrice, sale.currency)),
        _DetailRow('Total Sale', _amount(sale.totalRevenue, sale.currency)),
        _DetailRow('Cost Amount', _amount(sale.totalCost, sale.currency)),
        _DetailRow('Profit', _amount(sale.grossProfit, sale.currency)),
        _DetailRow('Payment Method', _label(sale.paymentMethod)),
        _DetailRow('Status', _label(sale.status)),
        _DetailRow('Sold At', _formatDateTime(sale.saleDate)),
        _DetailRow('Created At', _formatDateTime(sale.createdAt)),
        _DetailRow('Created By', sale.createdBy),
        _DetailRow('Notes', sale.notes),
        _DetailRow('Cancelled At', _formatDateTime(sale.cancelledAt)),
        _DetailRow('Cancelled By', sale.cancelledBy),
        _DetailRow('Cancellation Reason', sale.cancellationReason),
      ],
    );
  }

  void _showProductDetails(GymProduct product) {
    _showDetailsSheet(
      title: 'Product Inventory Details',
      rows: [
        _DetailRow('Product ID', product.id),
        _DetailRow('Name', product.name),
        _DetailRow('Category', _label(product.category)),
        _DetailRow('Selling Price', _amount(product.sellingPrice, product.currency)),
        _DetailRow('Cost Price', _amount(product.costPrice, product.currency)),
        _DetailRow('Stock Quantity', product.stockQuantity?.toString() ?? 'Not tracked'),
        _DetailRow('Status', _label(product.status)),
        _DetailRow('Created At', _formatDateTime(product.createdAt)),
        _DetailRow('Updated At', _formatDateTime(product.updatedAt)),
        _DetailRow('Notes', product.description),
      ],
    );
  }

  void _showDetailsSheet({
    required String title,
    required List<_DetailRow> rows,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailsSheet(title: title, rows: rows),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      _showSnack(friendlyFirestoreErrorMessage(error), redAlert);
    }
  }

  String _currentGymId() {
    final gymId = ref.read(currentGymIdProvider)?.trim();
    if (gymId == null || gymId.isEmpty) {
      throw StateError('No current gym is selected.');
    }
    return gymId;
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}

class _FinanceHeader extends StatelessWidget {
  const _FinanceHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 10,
      children: [
        const GoldHeading('Finance & Operations', fontSize: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
              color: gold,
              tooltip: 'Previous month',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderDark),
              ),
              child: ApexText(
                _monthLabel(month),
                color: const Color(0xFFE0E0E0),
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
              color: gold,
              tooltip: 'Next month',
            ),
            TextButton(
              onPressed: onCurrent,
              child: const ApexText('Current Month', color: gold),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isMobile,
    required this.onAddExpense,
    required this.onAddProduct,
    required this.onSellProduct,
    required this.onAddPayroll,
  });

  final bool isMobile;
  final VoidCallback onAddExpense;
  final VoidCallback onAddProduct;
  final VoidCallback onSellProduct;
  final VoidCallback onAddPayroll;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _ActionButton(Icons.receipt_long_rounded, 'Add Expense', onAddExpense),
      _ActionButton(Icons.inventory_2_rounded, 'Add Product', onAddProduct),
      _ActionButton(Icons.point_of_sale_rounded, 'Sell Product', onSellProduct),
      _ActionButton(Icons.payments_rounded, 'Add Staff Salary', onAddPayroll),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons
          .map(
            (button) => SizedBox(
              width: isMobile ? double.infinity : null,
              child: FilledButton.icon(
                onPressed: button.onPressed,
                icon: Icon(button.icon, size: 17),
                label: Text(button.label),
                style: FilledButton.styleFrom(backgroundColor: gold),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActionButton {
  const _ActionButton(this.icon, this.label, this.onPressed);
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class _FinanceBody extends StatelessWidget {
  const _FinanceBody({
    required this.summary,
    required this.isMobile,
    required this.onCancelExpense,
    required this.onCancelSale,
    required this.onCancelPayroll,
    required this.onShowTransaction,
    required this.onShowExpense,
    required this.onShowSale,
    required this.onShowPayroll,
    required this.products,
    required this.onShowProduct,
  });

  final FinanceSummary summary;
  final bool isMobile;
  final ValueChanged<GymExpense> onCancelExpense;
  final ValueChanged<ProductSale> onCancelSale;
  final ValueChanged<GymStaffPayroll> onCancelPayroll;
  final ValueChanged<GymTransaction> onShowTransaction;
  final ValueChanged<GymExpense> onShowExpense;
  final ValueChanged<ProductSale> onShowSale;
  final ValueChanged<GymStaffPayroll> onShowPayroll;
  final List<GymProduct> products;
  final ValueChanged<GymProduct> onShowProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (summary.isEmptyMonth) ...[
          const _EmptyMonth(),
          const SizedBox(height: 14),
        ],
        _KpiGrid(summary: summary, isMobile: isMobile),
        const SizedBox(height: 16),
        _TwoColumn(
          isMobile: isMobile,
          left: _BreakdownCard(
            title: 'Revenue by Payment Method',
            rows: summary.revenueByPaymentMethod,
          ),
          right: _BreakdownCard(
            title: 'Expense by Category',
            rows: summary.expensesByCategory,
          ),
        ),
        const SizedBox(height: 16),
        _TwoColumn(
          isMobile: isMobile,
          left: _BreakdownCard(
            title: 'Product Sales Summary',
            rows: summary.productSalesByCategory,
            footer: 'Gross product profit ${_money(summary.grossProductProfit)}',
          ),
          right: _BreakdownCard(
            title: 'Staff Payroll Summary',
            rows: summary.payrollByRole,
            footer: 'Pending payroll ${_money(summary.pendingPayroll)}',
          ),
        ),
        const SizedBox(height: 16),
        _TwoColumn(
          isMobile: isMobile,
          left: _RecentTransactions(
            items: summary.recentIncomeTransactions,
            onShow: onShowTransaction,
          ),
          right: _RecentProductSales(
            items: summary.recentProductSales,
            onCancel: onCancelSale,
            onShow: onShowSale,
          ),
        ),
        const SizedBox(height: 16),
        _TwoColumn(
          isMobile: isMobile,
          left: _RecentExpenses(
            items: summary.recentExpenses,
            onCancel: onCancelExpense,
            onShow: onShowExpense,
          ),
          right: _RecentPayroll(
            items: summary.recentPayrollEntries,
            onCancel: onCancelPayroll,
            onShow: onShowPayroll,
          ),
        ),
        const SizedBox(height: 16),
        _ProductInventory(items: products, onShow: onShowProduct),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary, required this.isMobile});

  final FinanceSummary summary;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Kpi('Total Revenue', summary.totalRevenue, greenSuccess),
      _Kpi('Membership Revenue', summary.membershipRevenue, blueInfo),
      _Kpi('Product Revenue', summary.productRevenue, greenSuccess),
      _Kpi('Operating Expenses', summary.operatingExpenses, redAlert),
      _Kpi('Staff Salaries', summary.staffSalaryCosts, orangeWarning),
      _Kpi('Product Costs', summary.productCosts, orangeWarning),
      _Kpi('Net Profit', summary.netProfit, summary.netProfit >= 0 ? gold : redAlert),
      _Kpi('Pending Obligations', summary.pendingObligations, orangeWarning),
    ];
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: isMobile ? 1.08 : 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards.map((card) => _KpiCard(kpi: card)).toList(),
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});

  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.analytics_rounded, color: kpi.color, size: 18),
          const Spacer(),
          GoldHeading(_money(kpi.value), fontSize: 17),
          const SizedBox(height: 5),
          ApexText(kpi.label, color: const Color(0xFF999999), maxLines: 2),
        ],
      ),
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({
    required this.isMobile,
    required this.left,
    required this.right,
  });

  final bool isMobile;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(children: [left, const SizedBox(height: 16), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.rows,
    this.footer,
  });

  final String title;
  final Map<String, double> rows;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldHeading(title, fontSize: 15),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const ApexText('No paid records this month.', color: Color(0xFF777777))
          else
            ...rows.entries.map(
              (row) => _AmountRow(label: _label(row.key), value: row.value),
            ),
          if (footer != null) ...[
            const SizedBox(height: 10),
            ApexText(footer!, color: gold, fontWeight: FontWeight.w700),
          ],
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.items, required this.onShow});

  final List<GymTransaction> items;
  final ValueChanged<GymTransaction> onShow;

  @override
  Widget build(BuildContext context) {
    return _RecentCard(
      title: 'Recent Membership Payments',
      empty: 'No membership payments this month.',
      children: items
          .map(
            (tx) => _ListRow(
              title: tx.memberName.isEmpty ? tx.receiptNumber : tx.memberName,
              subtitle: '${tx.paymentMethod} / ${tx.paymentStatus}',
              amount: tx.amount,
              onTap: () => onShow(tx),
            ),
          )
          .toList(),
    );
  }
}

class _RecentProductSales extends StatelessWidget {
  const _RecentProductSales({
    required this.items,
    required this.onCancel,
    required this.onShow,
  });

  final List<ProductSale> items;
  final ValueChanged<ProductSale> onCancel;
  final ValueChanged<ProductSale> onShow;

  @override
  Widget build(BuildContext context) {
    return _RecentCard(
      title: 'Recent Product Sales',
      empty: 'No product sales this month.',
      children: items
          .map(
            (sale) => _ListRow(
              title: sale.productName,
              subtitle: '${sale.quantity} sold / ${sale.status}',
              amount: sale.totalRevenue,
              onCancel: sale.status == ProductSaleStatus.cancelled
                  ? null
                  : () => onCancel(sale),
              onTap: () => onShow(sale),
            ),
          )
          .toList(),
    );
  }
}

class _RecentExpenses extends StatelessWidget {
  const _RecentExpenses({
    required this.items,
    required this.onCancel,
    required this.onShow,
  });

  final List<GymExpense> items;
  final ValueChanged<GymExpense> onCancel;
  final ValueChanged<GymExpense> onShow;

  @override
  Widget build(BuildContext context) {
    return _RecentCard(
      title: 'Recent Expenses',
      empty: 'No expenses this month.',
      children: items
          .map(
            (expense) => _ListRow(
              title: expense.title,
              subtitle: '${_label(expense.category)} / ${expense.status}',
              amount: expense.amount,
              onCancel: expense.status == GymExpenseStatus.cancelled
                  ? null
                  : () => onCancel(expense),
              onTap: () => onShow(expense),
            ),
          )
          .toList(),
    );
  }
}

class _RecentPayroll extends StatelessWidget {
  const _RecentPayroll({
    required this.items,
    required this.onCancel,
    required this.onShow,
  });

  final List<GymStaffPayroll> items;
  final ValueChanged<GymStaffPayroll> onCancel;
  final ValueChanged<GymStaffPayroll> onShow;

  @override
  Widget build(BuildContext context) {
    return _RecentCard(
      title: 'Recent Payroll Payments',
      empty: 'No payroll entries this month.',
      children: items
          .map(
            (payroll) => _ListRow(
              title: payroll.staffName,
              subtitle: '${payroll.role} / ${payroll.status}',
              amount: payroll.salaryAmount,
              onCancel: payroll.status == StaffPayrollStatus.cancelled
                  ? null
                  : () => onCancel(payroll),
              onTap: () => onShow(payroll),
            ),
          )
          .toList(),
    );
  }
}

class _ProductInventory extends StatelessWidget {
  const _ProductInventory({required this.items, required this.onShow});

  final List<GymProduct> items;
  final ValueChanged<GymProduct> onShow;

  @override
  Widget build(BuildContext context) {
    return _RecentCard(
      title: 'Products Inventory',
      empty: 'No products have been added yet.',
      children: items
          .map(
            (product) => _ListRow(
              title: product.name,
              subtitle:
                  '${_label(product.category)} / ${product.stockQuantity?.toString() ?? 'Not tracked'} in stock / ${product.status}',
              amount: product.sellingPrice,
              onTap: () => onShow(product),
            ),
          )
          .toList(),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.title,
    required this.empty,
    required this.children,
  });

  final String title;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldHeading(title, fontSize: 15),
          const SizedBox(height: 12),
          if (children.isEmpty)
            ApexText(empty, color: const Color(0xFF777777))
          else
            ...children,
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.onCancel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final double amount;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApexText(title, color: const Color(0xFFE0E0E0), maxLines: 1),
                const SizedBox(height: 3),
                ApexText(subtitle, color: const Color(0xFF777777), fontSize: 11),
              ],
            ),
          ),
          ApexText(_money(amount), color: gold, fontWeight: FontWeight.w700),
          if (onCancel != null)
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              color: orangeWarning,
              tooltip: 'Cancel',
            ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderDark),
            ),
            child: row,
          ),
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: ApexText(label, color: const Color(0xFFBBBBBB))),
          ApexText(_money(value), color: gold, fontWeight: FontWeight.w700),
        ],
      ),
    );
  }
}

class _FinanceLoading extends StatelessWidget {
  const _FinanceLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerCard(),
        ),
      ),
    );
  }
}

class _FinanceError extends StatelessWidget {
  const _FinanceError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ApexCard(
      child: ApexText(friendlyFirestoreErrorMessage(error), color: redAlert),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String? value;
}

class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({required this.title, required this.rows});

  final String title;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows
        .where((row) => row.value != null && row.value!.trim().isNotEmpty)
        .toList();
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(child: GoldHeading(title, fontSize: 17)),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFFE0E0E0),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(color: borderDark, height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: visibleRows.length,
                    separatorBuilder: (_, __) => const Divider(color: borderDark),
                    itemBuilder: (context, index) {
                      final row = visibleRows[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ApexText(
                            row.label,
                            color: const Color(0xFF888888),
                            fontSize: 11,
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            row.value!.trim(),
                            style: const TextStyle(
                              color: Color(0xFFE6E6E6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog({required this.title});

  final String title;

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cardDark,
      title: GoldHeading(widget.title, fontSize: 17),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 4,
        style: const TextStyle(color: Color(0xFFE8E8E8)),
        decoration: InputDecoration(
          labelText: 'Reason',
          errorText: _error,
          labelStyle: const TextStyle(color: Color(0xFF888888)),
          filled: true,
          fillColor: const Color(0xFF0A0A0A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: gold),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep Record'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.isEmpty) {
              setState(() => _error = 'A reason is required.');
              return;
            }
            Navigator.of(context).pop(reason);
          },
          child: const Text('Cancel Record'),
        ),
      ],
    );
  }
}

class _EmptyMonth extends StatelessWidget {
  const _EmptyMonth();

  @override
  Widget build(BuildContext context) {
    return const ApexCard(
      child: ApexText(
        'No finance records for this month yet.',
        color: Color(0xFF888888),
      ),
    );
  }
}

class _ExpenseDialog extends ConsumerStatefulWidget {
  const _ExpenseDialog();

  @override
  ConsumerState<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends ConsumerState<_ExpenseDialog> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _date = TextEditingController(text: _dateInput(DateTime.now()));
  final _notes = TextEditingController();
  String _category = GymExpenseCategory.other;
  String _method = TransactionPaymentMethod.cash;
  String _status = GymExpenseStatus.paid;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _date.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceDialog(
      title: 'Add Expense',
      saving: _saving,
      onSave: _save,
      children: [
        _Field(controller: _title, label: 'Title'),
        _Field(controller: _amount, label: 'Amount', numeric: true),
        _Dropdown(
          label: 'Category',
          value: _category,
          values: GymExpenseCategory.all,
          onChanged: (value) => setState(() => _category = value),
        ),
        _PaymentMethodDropdown(value: _method, onChanged: (v) => setState(() => _method = v)),
        _Dropdown(
          label: 'Status',
          value: _status,
          values: const [GymExpenseStatus.paid, GymExpenseStatus.pending],
          onChanged: (value) => setState(() => _status = value),
        ),
        _Field(controller: _date, label: 'Date YYYY-MM-DD'),
        _Field(controller: _notes, label: 'Notes', maxLines: 2),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(expenseRepositoryProvider).createExpense(
            gymId: _gymId(ref),
            title: _title.text,
            category: _category,
            amount: _positiveDouble(_amount.text, 'Expense amount'),
            currency: 'EGP',
            paymentMethod: _method,
            date: _parseDate(_date.text),
            status: _status,
            notes: _notes.text,
            createdBy: ref.read(currentAuthUserProvider)?.uid,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(context, 'Expense added.', greenSuccess);
    } catch (error) {
      if (!mounted) return;
      _snack(context, friendlyFirestoreErrorMessage(error), redAlert);
      setState(() => _saving = false);
    }
  }
}

class _ProductDialog extends ConsumerStatefulWidget {
  const _ProductDialog();

  @override
  ConsumerState<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<_ProductDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _selling = TextEditingController();
  final _cost = TextEditingController(text: '0');
  final _stock = TextEditingController();
  String _category = GymProductCategory.supplement;
  String _status = GymProductStatus.active;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _selling.dispose();
    _cost.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceDialog(
      title: 'Add Product',
      saving: _saving,
      onSave: _save,
      children: [
        _Field(controller: _name, label: 'Name'),
        _Dropdown(
          label: 'Category',
          value: _category,
          values: GymProductCategory.all,
          onChanged: (value) => setState(() => _category = value),
        ),
        _Field(controller: _description, label: 'Description', maxLines: 2),
        _Field(controller: _selling, label: 'Selling Price', numeric: true),
        _Field(controller: _cost, label: 'Cost Price', numeric: true),
        _Field(controller: _stock, label: 'Stock Quantity optional', numeric: true),
        _Dropdown(
          label: 'Status',
          value: _status,
          values: const [GymProductStatus.active, GymProductStatus.inactive],
          onChanged: (value) => setState(() => _status = value),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final stockText = _stock.text.trim();
      await ref.read(productRepositoryProvider).createProduct(
            gymId: _gymId(ref),
            name: _name.text,
            category: _category,
            description: _description.text,
            sellingPrice: _positiveDouble(_selling.text, 'Selling price'),
            costPrice: _nonNegativeDouble(_cost.text, 'Cost price'),
            currency: 'EGP',
            stockQuantity: stockText.isEmpty
                ? null
                : _nonNegativeInt(stockText, 'Stock quantity'),
            status: _status,
            createdBy: ref.read(currentAuthUserProvider)?.uid,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(context, 'Product added.', greenSuccess);
    } catch (error) {
      if (!mounted) return;
      _snack(context, friendlyFirestoreErrorMessage(error), redAlert);
      setState(() => _saving = false);
    }
  }
}

class _ProductSaleDialog extends ConsumerStatefulWidget {
  const _ProductSaleDialog({required this.products, required this.members});

  final List<GymProduct> products;
  final List<Member> members;

  @override
  ConsumerState<_ProductSaleDialog> createState() => _ProductSaleDialogState();
}

class _ProductSaleDialogState extends ConsumerState<_ProductSaleDialog> {
  final _quantity = TextEditingController(text: '1');
  final _notes = TextEditingController();
  String? _productId;
  String _memberId = '';
  String _method = TransactionPaymentMethod.cash;
  String _status = ProductSaleStatus.paid;
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceDialog(
      title: 'Sell Product',
      saving: _saving,
      onSave: _save,
      children: [
        _Dropdown<String>(
          label: 'Product',
          value: _productId,
          values: widget.products.map((p) => p.id).toList(),
          labelOf: (id) {
            final product = widget.products.firstWhere((p) => p.id == id);
            final stock = product.stockQuantity == null
                ? 'stock not tracked'
                : '${product.stockQuantity} in stock';
            return '${product.name} - ${_money(product.sellingPrice)} - $stock';
          },
          onChanged: (value) => setState(() => _productId = value),
        ),
        _Dropdown<String>(
          label: 'Member optional',
          value: _memberId,
          values: ['', ...widget.members.map((m) => m.id)],
          labelOf: (id) {
            if (id.isEmpty) return 'Walk-in / no member';
            return widget.members.firstWhere((m) => m.id == id).fullName;
          },
          onChanged: (value) => setState(() => _memberId = value),
        ),
        _Field(controller: _quantity, label: 'Quantity', numeric: true),
        _PaymentMethodDropdown(value: _method, onChanged: (v) => setState(() => _method = v)),
        _Dropdown(
          label: 'Status',
          value: _status,
          values: const [ProductSaleStatus.paid, ProductSaleStatus.pending],
          onChanged: (value) => setState(() => _status = value),
        ),
        _Field(controller: _notes, label: 'Notes', maxLines: 2),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final productId = _productId;
      if (productId == null || productId.isEmpty) {
        throw StateError('Select a product.');
      }
      final product = widget.products.firstWhere((p) => p.id == productId);
      final member = _memberId.isEmpty
          ? null
          : widget.members.firstWhere((m) => m.id == _memberId);
      await ref.read(productSalesRepositoryProvider).createProductSale(
            gymId: _gymId(ref),
            product: product,
            memberId: member?.id,
            memberName: member?.fullName,
            quantity: _positiveInt(_quantity.text, 'Quantity'),
            paymentMethod: _method,
            status: _status,
            saleDate: DateTime.now(),
            notes: _notes.text,
            createdBy: ref.read(currentAuthUserProvider)?.uid,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(context, 'Product sale recorded.', greenSuccess);
    } catch (error) {
      if (!mounted) return;
      _snack(context, friendlyFirestoreErrorMessage(error), redAlert);
      setState(() => _saving = false);
    }
  }
}

class _PayrollDialog extends ConsumerStatefulWidget {
  const _PayrollDialog({required this.staff, required this.month});

  final List<Staff> staff;
  final DateTime month;

  @override
  ConsumerState<_PayrollDialog> createState() => _PayrollDialogState();
}

class _PayrollDialogState extends ConsumerState<_PayrollDialog> {
  final _amount = TextEditingController();
  final _period = TextEditingController();
  final _paymentDate = TextEditingController(text: _dateInput(DateTime.now()));
  final _notes = TextEditingController();
  String? _staffId;
  String _method = TransactionPaymentMethod.cash;
  String _status = StaffPayrollStatus.paid;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _period.text =
        '${widget.month.year}-${widget.month.month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _amount.dispose();
    _period.dispose();
    _paymentDate.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceDialog(
      title: 'Add Staff Salary',
      saving: _saving,
      onSave: _save,
      children: [
        _Dropdown<String>(
          label: 'Staff',
          value: _staffId,
          values: widget.staff.map((s) => s.id).toList(),
          labelOf: (id) => widget.staff.firstWhere((s) => s.id == id).fullName,
          onChanged: (value) => setState(() => _staffId = value),
        ),
        _Field(controller: _amount, label: 'Salary Amount', numeric: true),
        _Field(controller: _period, label: 'Period Month YYYY-MM'),
        _Field(controller: _paymentDate, label: 'Payment Date YYYY-MM-DD'),
        _PaymentMethodDropdown(value: _method, onChanged: (v) => setState(() => _method = v)),
        _Dropdown(
          label: 'Status',
          value: _status,
          values: const [StaffPayrollStatus.paid, StaffPayrollStatus.pending],
          onChanged: (value) => setState(() => _status = value),
        ),
        _Field(controller: _notes, label: 'Notes', maxLines: 2),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final staffId = _staffId;
      if (staffId == null || staffId.isEmpty) throw StateError('Select staff.');
      final staff = widget.staff.firstWhere((s) => s.id == staffId);
      await ref.read(staffPayrollRepositoryProvider).createPayrollPayment(
            gymId: _gymId(ref),
            staffId: staff.id,
            staffName: staff.fullName,
            role: staff.role,
            salaryAmount: _positiveDouble(_amount.text, 'Salary amount'),
            currency: 'EGP',
            periodMonth: _parseMonth(_period.text),
            paymentDate: _parseDate(_paymentDate.text),
            paymentMethod: _method,
            status: _status,
            notes: _notes.text,
            createdBy: ref.read(currentAuthUserProvider)?.uid,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(context, 'Payroll payment recorded.', greenSuccess);
    } catch (error) {
      if (!mounted) return;
      _snack(context, friendlyFirestoreErrorMessage(error), redAlert);
      setState(() => _saving = false);
    }
  }
}

class _FinanceDialog extends StatelessWidget {
  const _FinanceDialog({
    required this.title,
    required this.children,
    required this.saving,
    required this.onSave,
  });

  final String title;
  final List<Widget> children;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: cardDark,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoldHeading(title, fontSize: 16),
              const SizedBox(height: 14),
              ...children,
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.of(context).pop(),
                    child: const ApexText('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: saving ? null : onSave,
                    style: FilledButton.styleFrom(backgroundColor: gold),
                    child: Text(saving ? 'Saving' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.numeric = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool numeric;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF888888)),
          filled: true,
          fillColor: const Color(0xFF0A0A0A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: gold),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodDropdown extends StatelessWidget {
  const _PaymentMethodDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Dropdown(
      label: 'Payment Method',
      value: value,
      values: const [
        TransactionPaymentMethod.cash,
        TransactionPaymentMethod.instapay,
        TransactionPaymentMethod.vodafoneCash,
        TransactionPaymentMethod.card,
        TransactionPaymentMethod.online,
      ],
      onChanged: onChanged,
    );
  }
}

class _Dropdown<T extends Object> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.labelOf,
  });

  final String label;
  final T? value;
  final List<T> values;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelOf;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        value: value != null && values.contains(value) ? value : null,
        dropdownColor: cardDark,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF888888)),
          filled: true,
          fillColor: const Color(0xFF0A0A0A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 13),
        items: values
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(labelOf?.call(item) ?? _label(item.toString())),
              ),
            )
            .toList(),
        onChanged: (item) {
          if (item != null) onChanged(item);
        },
      ),
    );
  }
}

String _gymId(WidgetRef ref) {
  final gymId = ref.read(currentGymIdProvider)?.trim();
  if (gymId == null || gymId.isEmpty) throw StateError('No current gym selected.');
  return gymId;
}

double _positiveDouble(String value, String label) {
  final parsed = double.tryParse(value.trim());
  if (parsed == null || !parsed.isFinite || parsed <= 0) {
    throw StateError('$label must be greater than zero.');
  }
  return parsed;
}

double _nonNegativeDouble(String value, String label) {
  final parsed = double.tryParse(value.trim().isEmpty ? '0' : value.trim());
  if (parsed == null || !parsed.isFinite || parsed < 0) {
    throw StateError('$label must be zero or greater.');
  }
  return parsed;
}

int _positiveInt(String value, String label) {
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed <= 0) {
    throw StateError('$label must be greater than zero.');
  }
  return parsed;
}

int _nonNegativeInt(String value, String label) {
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed < 0) {
    throw StateError('$label must be zero or greater.');
  }
  return parsed;
}

DateTime _parseDate(String value) {
  final parts = value.trim().split('-');
  if (parts.length != 3) throw StateError('Date must use YYYY-MM-DD.');
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    throw StateError('Date must use YYYY-MM-DD.');
  }
  return DateTime(year, month, day);
}

DateTime _parseMonth(String value) {
  final parts = value.trim().split('-');
  if (parts.length != 2) throw StateError('Period month must use YYYY-MM.');
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) {
    throw StateError('Period month must use YYYY-MM.');
  }
  return DateTime(year, month);
}

String _dateInput(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _monthLabel(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _money(double value) {
  return '${formatCurrency(value)} EGP';
}

String _amount(double value, String currency) {
  final code = currency.trim().isEmpty ? 'EGP' : currency.trim();
  return '${formatCurrency(value)} $code';
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  return _dateInput(date);
}

String _formatDateTime(DateTime? date) {
  if (date == null) return '';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_dateInput(date)} $hour:$minute';
}

String _formatMonth(DateTime? date) {
  if (date == null) return '';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

String _label(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

void _snack(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: color),
  );
}
