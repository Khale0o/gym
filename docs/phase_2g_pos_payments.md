# Phase 2G POS Payments and Receipts

## What changed

Phase 2G adds a gym-scoped payments foundation. Owner, admin, and reception
users can record member payments from the new Payments screen. Payments are
stored as transaction documents and include receipt numbers.

No online gateway, Stripe, Paymob, PayTabs, POS hardware, receipt printing, or
dashboard finance migration is included in this phase.

## Firestore paths

- Transactions: `gyms/{gymId}/transactions/{transactionId}`
- Receipt counter: `gyms/{gymId}/settings/receiptCounter`
- Members updated when linked: `gyms/{gymId}/members/{memberId}`
- Subscriptions updated when linked:
  `gyms/{gymId}/subscriptions/{subscriptionId}`

For this phase, the transaction document is the receipt record. A separate
`receipts` subcollection was not added yet.

## Transaction model

`GymTransaction` supports:

- `id`
- `gymId`
- `memberId`
- `memberName`
- `subscriptionId`
- `planId`
- `type`
- `amount`
- `currency`
- `paymentMethod`
- `paymentStatus`
- `description`
- `receiptNumber`
- `createdByUid`
- `createdByName`
- `createdAt`
- `updatedAt`
- `notes`
- `metadata`

Supported transaction types:

- `subscription_payment`
- `renewal`
- `product_sale`
- `service`
- `adjustment`
- `refund`

Supported payment methods:

- `cash`
- `instapay`
- `vodafone_cash`
- `card`
- `online`
- `unknown`

Supported payment statuses:

- `paid`
- `partial`
- `unpaid`
- `refunded`

## Receipt numbers

Receipt numbers are generated inside a Firestore transaction using
`gyms/{gymId}/settings/receiptCounter.lastNumber`.

Format:

`GYM001-20260429-0001`

The prefix is derived from the gym id. For `gym_001`, it becomes `GYM001`.

## Role permissions

Can record payments:

- owner
- admin
- reception

Cannot record payments:

- coach
- member
- inactive/unknown profiles

The Payments route is `/payments`.

## Subscription update behavior

When a payment is linked to a subscription, the same Firestore transaction:

- creates `gyms/{gymId}/transactions/{transactionId}`
- updates subscription `paymentStatus`
- writes `lastPaymentAt`
- writes `lastTransactionId`
- writes `lastReceiptNumber`
- updates member summary `paymentStatus`
- refreshes member plan/subscription summary fields from the linked subscription

If no subscription is selected, the payment is recorded as a member service
payment and does not update a subscription.

## Validation

The UI and repository require:

- current gym id
- active owner/admin/reception profile
- signed-in Firebase Auth user
- selected member
- amount greater than zero
- payment method
- existing member document when `memberId` is provided
- existing subscription document when `subscriptionId` is provided

No top-level `transactions` write is performed.

## Manual tests

1. Sign in as owner/admin/reception.
2. Open Payments.
3. Select a gym-scoped member.
4. Select an unpaid or partial subscription, or leave subscription unlinked.
5. Enter a positive amount and choose `cash`.
6. Save and verify a success SnackBar with receipt number.
7. Verify `gyms/gym_001/transactions/{transactionId}` exists.
8. Verify `receiptNumber` exists.
9. If linked to subscription, verify subscription `paymentStatus` updates.
10. Verify member summary `paymentStatus` updates.
11. Sign in as coach/member and verify Payments is hidden/blocked.
12. Try amount `0` or negative and verify validation blocks it.
13. Confirm no top-level `transactions` document is created.

## Known limitations

- No real online payment gateway.
- No receipt printing/export.
- No separate `receipts` collection yet.
- No dashboard revenue migration.
- No product inventory/POS cart.
- No refund workflow beyond the model status/type foundation.
