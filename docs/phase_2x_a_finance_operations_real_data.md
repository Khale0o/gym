# Phase 2X-A - Finance & Operations Real Data

## What Changed

Phase 2X-A converted Finance & Operations from static/mock values into a real gym-scoped finance module.

Added:

- Real finance models for expenses, staff payroll, products, product sales, and finance summaries.
- Gym-scoped repositories for finance writes and monthly reads.
- A real Finance & Operations screen backed by live providers.
- Manual Add Expense, Add Product, Sell Product, and Add Staff Salary dialogs.
- Read-only live occupancy card in the Member App.
- Narrow Firestore rules for new finance collections.

No Phase 2X-B work was added.

## Firestore Paths

Existing paths used:

- `gyms/{gymId}/transactions/{transactionId}`
- `gyms/{gymId}/members/{memberId}`
- `gyms/{gymId}/staff/{staffId}`
- `gyms/{gymId}/settings/occupancy`

New paths used:

- `gyms/{gymId}/expenses/{expenseId}`
- `gyms/{gymId}/products/{productId}`
- `gyms/{gymId}/productSales/{saleId}`
- `gyms/{gymId}/staffPayroll/{payrollId}`

No top-level legacy collections are used by the Phase 2X-A finance module.

## Revenue Calculation

Membership revenue comes from `gyms/{gymId}/transactions`.

Included:

- `paymentStatus == paid`
- `paymentStatus == partial`

Formula:

```text
membershipRevenue = sum(paid/partial transaction.amount)
```

Product revenue comes from paid product sales:

```text
productRevenue = sum(paid productSale.totalRevenue)
totalRevenue = membershipRevenue + productRevenue
```

Pending product sales are shown separately and do not count as paid revenue.

## Expense Calculation

Operating expenses come from `gyms/{gymId}/expenses`.

Included in paid costs:

- `status == paid`

Excluded from paid costs:

- `pending`
- `cancelled`

Formula:

```text
operatingExpenses = sum(paid expense.amount)
pendingExpenses = sum(pending expense.amount)
```

Cancellation uses `status = cancelled`; records are not deleted.

## Payroll Calculation

Staff salary costs come from `gyms/{gymId}/staffPayroll`.

Included in paid costs:

- `status == paid`

Pending payroll appears as a pending obligation but does not reduce net profit.

Formula:

```text
staffSalaryCosts = sum(paid payroll.salaryAmount)
pendingPayroll = sum(pending payroll.salaryAmount)
```

Payroll entries are manual in this phase. No automatic salary generation was added.

## Product Sales Calculation

Products are stored in `gyms/{gymId}/products`.

Product sales are stored in `gyms/{gymId}/productSales`.

On paid sale:

- `totalRevenue = quantity * unitSellingPrice`
- `totalCost = quantity * unitCostPrice`
- `grossProfit = totalRevenue - totalCost`
- stock is reduced only when `stockQuantity` exists
- sale is blocked if stock would go below zero

If product cost is missing, cost defaults safely to `0`.

Formula:

```text
productCosts = sum(paid productSale.totalCost)
grossProductProfit = productRevenue - productCosts
```

Pending and cancelled product sales do not count as paid revenue.

## Net Profit Formula

```text
totalCosts = operatingExpenses + staffSalaryCosts + productCosts
netProfit = totalRevenue - totalCosts
```

Displayed KPIs:

- Total Revenue
- Membership Revenue
- Product Revenue
- Operating Expenses
- Staff Salaries
- Product Costs
- Net Profit
- Pending Obligations

## Month Logic

The selected month starts at local first day of month `00:00`.

The next month starts at the first day of the following month `00:00`.

Included records have finance dates:

```text
date >= monthStart && date < nextMonthStart
```

The implementation keeps reads gym-scoped and filters/sorts in app code to avoid adding unnecessary composite query requirements.

## Live Occupancy in Member App

The Member App now reads:

- `gyms/{gymId}/settings/occupancy`

It displays:

- current count
- capacity when available
- usage percentage when capacity is available
- friendly status:
  - Quiet: 0-49%
  - Moderate: 50-74%
  - Busy: 75-89%
  - Full: 90%+

Members cannot edit occupancy. Missing occupancy docs, missing capacity, and permission errors are handled without crashing.

## Permissions

Firestore rules were updated narrowly.

Owner/admin:

- read/write `expenses`
- read/write `products`
- read/write `productSales`
- read/write `staffPayroll`
- cancel by status update

Reception:

- unchanged for this phase
- not granted Finance & Operations access

Coach/member:

- cannot read/write finance collections
- member can read occupancy only through the existing active same-gym user rule

Security retained:

- inactive users are blocked
- cross-gym access is blocked
- deletes are blocked for finance records
- cancellation uses `status = cancelled`

## Required Firestore Indexes

No new composite index is intentionally required by Phase 2X-A. Monthly finance reads are gym-scoped and filtered in app code.

Existing invite indexes from previous phases may still be required:

- `staffInvites`: `emailNormalized` ascending, `status` ascending
- `memberInvites`: `emailNormalized` ascending, `status` ascending

## Manual Tests

1. Open Finance as owner/admin and confirm static numbers are gone.
2. Record a paid member renewal and confirm Membership Revenue increases.
3. Add a paid expense and confirm Operating Expenses increase and Net Profit decreases.
4. Add pending expense and confirm it appears pending but does not reduce paid expenses.
5. Add staff payroll paid and confirm Staff Salaries increase and Net Profit decreases.
6. Add pending payroll and confirm it appears pending only.
7. Add product with stock.
8. Sell product paid and confirm Product Revenue increases, Product Costs increase, and stock decreases.
9. Try selling more than available stock and confirm blocked.
10. Cancel expense/payroll/product sale and confirm it no longer counts.
11. Navigate to previous month and confirm month-specific data.
12. Add an expense dated previous month and confirm it appears only there.
13. Sign in as member and confirm Member App shows live occupancy read-only.
14. Confirm member cannot read finance data.
15. Confirm coach/member cannot add finance records.
16. Confirm no top-level collections are used.

## Known Limitations

- No payroll automation.
- No payslip PDF.
- No invoice PDF.
- No print/share.
- No online payment gateway.
- No barcode scanning.
- No advanced inventory purchase orders.
- No tax/VAT accounting.
- No multi-branch consolidated finance yet.
- No super-admin owner billing control in this phase.
