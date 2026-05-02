# Phase 2M - Payment Methods Integration and Receipt Details

## What changed

Payments now consumes gym business settings for enabled payment methods and the recent receipts list supports a production-friendly receipt details view.

This phase touched:

- `lib/screens/payments/payments_screen.dart`
- `docs/phase_2m_payment_methods_receipts.md`

No auth, invites, member creation, plans, dashboard, settings save logic, check-in validation, PDF, printing, gateways, NFC, AI, or notifications were added.

## Firestore paths used

- `gyms/{gymId}/settings/app`
  - Reads `enabledPaymentMethods`.
- `gyms/{gymId}/transactions/{transactionId}`
  - Existing Payments data source for recent receipts and transaction details.
- `gyms/{gymId}/members/{memberId}`
  - Read when opening receipt details to show member phone when available.

Existing payment and renewal writes remain gym-scoped and continue to use the existing transaction flow.

## Payment method fallback rules

Supported payment methods are:

- `cash`
- `instapay`
- `vodafone_cash`
- `card`
- `online`

Payments uses `gyms/{gymId}/settings/app.enabledPaymentMethods` when present.

Fallback behavior:

- If the app settings document is missing, Payments falls back to all supported methods.
- If `enabledPaymentMethods` is missing, empty, or contains no supported values, Payments falls back to all supported methods.
- If the selected method is disabled by settings, the screen resets it to the first enabled method.
- Saving validates that the selected method is currently enabled.
- If no valid method is available, saving is blocked with a clear error.

## Receipt details behavior

Recent receipts in Payments are tappable. Tapping a receipt opens a mobile-safe modal bottom sheet showing:

- receipt number
- amount and currency
- payment method
- payment status
- member name
- member phone when available
- plan or description when available
- linked subscription id when available
- transaction id
- created date
- created by
- notes

The sheet includes:

- copy receipt number action
- close action
- View Member action when `memberId` exists

Missing member, phone, plan, notes, or subscription data renders as a friendly fallback instead of crashing.

## Manual tests

1. Sign in as owner/admin, open Settings, and enable only `cash` and `instapay`.
2. Open Payments and confirm only Cash and Instapay appear.
3. Save a payment with Cash and confirm it succeeds.
4. Disable Cash, keep Instapay enabled, reopen Payments, and confirm the selected method resets safely.
5. Remove or empty `enabledPaymentMethods` in Firestore and confirm Payments falls back to all supported methods.
6. Tap a recent receipt and confirm the details sheet opens.
7. Confirm receipt details do not crash when member, phone, subscription, or notes are missing.
8. Sign in as reception and confirm Payments still works with enabled methods.
9. Sign in as coach/member and confirm Payments is still hidden or blocked by existing route permissions.
10. Confirm Members, Plans, Check-in, Dashboard, Settings, and Staff still work.

## Known limitations

- Receipt details are in-app only; no PDF, print, email, or share flow is included.
- Online/card methods are only labels/settings choices in this phase; no gateway processing is implemented.
- Plan name is displayed from existing transaction data when available. If future transactions denormalize a richer plan name field, the details sheet can show that directly.
- Member phone is loaded from the member document when `memberId` exists, so it may show a fallback if the member was deleted or cannot be read.
