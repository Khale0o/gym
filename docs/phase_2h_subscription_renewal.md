# Phase 2H - Subscription Renewal Payments

## What changed

The Payments screen now supports renewal payments. Owner, admin, and reception users can select a member, select an active plan, choose a payment method and payment status, enter an amount and notes, then record the payment.

Paid and partial renewal payments create an active subscription and update the member summary used by check-in validation. Unpaid renewal payments create a receipt transaction only and do not activate the member.

## Firestore paths

All writes stay gym-scoped:

- `gyms/{gymId}/settings/receiptCounter`
- `gyms/{gymId}/transactions/{transactionId}`
- `gyms/{gymId}/subscriptions/{subscriptionId}` for paid or partial renewals
- `gyms/{gymId}/members/{memberId}`

## Renewal date logic

The Payments screen looks for the selected member's latest subscription for the selected plan that is active or expired within the last 30 days.

If a matching subscription is found, the new period starts on:

`max(today, existingSubscription.endDate + 1 day)`

If no matching active or recently expired subscription is found, the new period starts today.

The new subscription end date is:

`startDate + plan.durationDays`

## Transaction writes

`TransactionRepository.createRenewalPayment` runs one Firestore transaction that:

- increments `gyms/{gymId}/settings/receiptCounter.lastNumber`
- creates a receipt in `gyms/{gymId}/transactions`
- creates a subscription in `gyms/{gymId}/subscriptions` when payment status is `paid` or `partial`
- updates the member summary fields for paid or partial renewals:
  - `currentPlanId`
  - `currentPlanName`
  - `subscriptionStatus`
  - `subscriptionStartDate`
  - `subscriptionEndDate`
  - `paymentStatus`
  - `lastPaymentAt`
  - `lastTransactionId`
  - `lastReceiptNumber`
  - `updatedAt`

For unpaid payments, the transaction and receipt are recorded, but no active subscription is created and the member is not marked active by the payment.

## Manual tests

1. Sign in as owner, admin, or reception.
2. Open Payments.
3. Select a member and an active plan.
4. Confirm the amount defaults from the plan price and can be edited.
5. Record a paid renewal.
6. Confirm a success SnackBar shows the generated receipt number.
7. Confirm the new receipt appears in Recent Receipts.
8. Confirm Firestore has a new transaction and a new active subscription.
9. Confirm the member summary points to the selected plan and has active subscription dates.
10. Check in the member and confirm access is granted.
11. Repeat with payment status `partial` and confirm check-in is still allowed.
12. Repeat with payment status `unpaid` and confirm a receipt is created but no active subscription is created by that payment.
13. Try saving with no member, no plan, no payment method, amount `0`, and no gym selected. Confirm validation blocks saving.
14. Sign in as coach or member and confirm the screen shows the no-permission message.

## Limitations

- "Recently expired" is currently treated as an expiration within the last 30 days.
- The renewal base subscription is selected from the member subscription stream on the Payments screen. Saving is blocked until that stream has loaded.
- Unpaid renewal records do not create pending subscriptions.
