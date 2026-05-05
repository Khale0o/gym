# Phase 2X-B Finance Details and Audit Controls

## Scope

Phase 2X-B made the existing real Finance & Operations module reviewable and audit-safe. It did not add new finance products, payment gateways, PDFs, notifications, payroll automation, inventory purchasing, super-admin logic, or unrelated UI redesigns.

## What Changed

- Added finance detail sheets for recent membership payment transactions, product sales, expenses, staff payroll entries, and products inventory.
- Added required cancellation reasons for expenses, staff payroll entries, and product sales.
- Kept payment transaction receipts read-only in this phase. Payment voiding/reversal is deferred because it can affect subscriptions, member payment state, receipts, and historical accounting.
- Updated finance cancellation writes to use status updates only. No financial or audit records are deleted.
- Added model support for `cancellationReason` on expenses, staff payroll, and product sales.
- Added product sale `stockWasTracked` so cancellation restores stock only when the original paid sale reduced stock.
- Updated Firestore rules narrowly so owner/admin cancellation updates can include `cancellationReason`.

## Detail Views Added

The Finance & Operations screen now opens mobile-safe detail sheets from the relevant finance lists:

- Payment transactions / receipts: receipt number, member, amount, method, status, plan/subscription references, creator, notes, and IDs.
- Expenses: title, category, amount, method, date, creator, notes, cancellation status, and cancellation reason.
- Staff payroll: staff, role, salary amount, period, payment date, method, creator, notes, cancellation status, and cancellation reason.
- Product sales: product, quantity, unit price, revenue, cost, profit, method, status, creator, notes, cancellation status, and cancellation reason.
- Products inventory: product name, category, selling price, cost price, stock quantity, status, timestamps, and notes/description.

## Cancel/Void Behavior

Expenses, staff payroll, and product sales are cancelled by setting audit fields:

- `status = cancelled`
- `cancelledAt`
- `cancelledBy`
- `cancellationReason`
- `updatedAt`

A cancellation reason is required before the write is attempted.

Physical deletes remain blocked. Cancelled records stay available for review but no longer count as paid revenue/cost activity in the finance summary.

## Product Sale Stock Restore

Cancelling a paid product sale runs in a Firestore transaction.

- If the original sale tracked stock, the sold quantity is restored to the product document.
- Double-cancellation is blocked before stock can be restored again.
- If the original paid sale tracked stock and the product document is missing, cancellation is blocked with a clear error so stock and audit state cannot drift silently.
- If the sale did not track stock, cancellation only marks the sale cancelled.

## Finance Summary Exclusion Rules

The Phase 2X-A summary already counts only paid/pending statuses where appropriate. Phase 2X-B keeps that behavior:

- Cancelled expenses do not count in operating expenses.
- Cancelled payroll does not count in staff salary costs or pending payroll.
- Cancelled product sales do not count in product revenue, product costs, product profit, or pending product sales.
- Payment transactions are not voided in this phase, so membership revenue behavior is unchanged.

## Permissions

Firestore paths remain gym-scoped under `gyms/{gymId}`:

- `gyms/{gymId}/transactions/{transactionId}`
- `gyms/{gymId}/expenses/{expenseId}`
- `gyms/{gymId}/staffPayroll/{payrollId}`
- `gyms/{gymId}/products/{productId}`
- `gyms/{gymId}/productSales/{saleId}`

Owner/admin can read and update finance cancellation fields inside their active gym. Reception, coach, and member roles are not granted new cancel/void permissions. Cross-gym access and inactive-user access remain blocked by the existing shared gym checks.

## Firestore Rules

Rules were updated narrowly to allow `cancellationReason` during owner/admin cancellation updates for:

- expenses
- productSales
- staffPayroll

Deletes remain denied for finance/audit collections.

## Manual Test Checklist

1. Open Finance & Operations as owner/admin.
2. Tap a recent membership payment and confirm the receipt detail sheet opens.
3. Tap a recent expense and confirm expense details and cancellation fields are shown.
4. Cancel an expense with an empty reason and confirm it is blocked.
5. Cancel an expense with a reason and confirm totals update.
6. Tap a payroll entry and confirm payroll details are shown.
7. Cancel a payroll entry with a reason and confirm staff salary costs update.
8. Tap a product sale and confirm revenue, cost, and profit details are shown.
9. Cancel a paid stock-tracked product sale and confirm stock is restored once.
10. Try cancelling the same product sale again and confirm it is blocked.
11. Tap a product inventory row and confirm product details are shown.
12. Confirm reception/coach/member cannot access new cancel controls.
13. Confirm no top-level finance collections are created.
14. Confirm no finance records are physically deleted.

## Known Limitations

- Payment transaction voiding/reversal is deferred to avoid unsafe subscription/member accounting side effects.
- No receipt PDF, invoice PDF, print/share, online payment gateway, payroll automation, inventory purchase orders, tax/VAT accounting, or super-admin billing was added.
- Firestore emulator/rules tests were not run in this phase.
