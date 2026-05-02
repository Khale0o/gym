# Phase 2I - Subscription Expiry Awareness

## Why effective status is calculated app-side

Member summary fields can become stale. For example, a member document may still have `subscriptionStatus: active` after `subscriptionEndDate` has passed. This phase adds an app-side resolver so screens can display the real effective status without writing back to Firestore.

This keeps expiry awareness safe and read-only. Check-in validation remains the source of access control, and no background migration is required.

## Rules used

The resolver returns one of:

- `active`
- `expiringSoon`
- `expired`
- `unpaid`
- `partial`
- `none`
- `cancelled`

Rules are evaluated in this order:

1. No subscription status and no end date => `none`
2. `subscriptionStatus == cancelled` => `cancelled`
3. `paymentStatus == unpaid` => `unpaid`
4. `subscriptionEndDate` before today => `expired`
5. `paymentStatus == partial` and not expired => `partial`
6. `subscriptionEndDate` within the warning threshold, default 7 days including today => `expiringSoon`
7. Otherwise => `active`

Date comparisons are day-based. A subscription ending today is still valid today and can display `expiringSoon`, not `expired`.

## Paths involved

This phase reads existing gym-scoped member summaries:

- `gyms/{gymId}/members/{memberId}`

It also preserves compatibility with subscription documents created by renewal payments:

- `gyms/{gymId}/subscriptions/{subscriptionId}`

## What changed

- Added `lib/models/effective_subscription_status.dart`
- Members list now shows effective subscription status badges.
- Member detail now shows current plan, end date, effective status, payment status, and a no-subscription notice when no summary exists.
- Payments screen now shows a small selected-member effective status hint before renewal.

## What this phase does not do

- Does not update Firestore automatically.
- Does not mark expired subscriptions in batches.
- Does not add Cloud Functions.
- Does not change check-in validation.
- Does not change Phase 2H renewal payment writes.
- Does not change auth, routing, staff invites, or member invites.

## Manual tests

1. Set a member with `subscriptionStatus: active` and `subscriptionEndDate` yesterday. Confirm Members and Member Detail display `Expired`.
2. Set `subscriptionEndDate` to today. Confirm it does not display `Expired`.
3. Set `subscriptionEndDate` within the next 7 days. Confirm it displays `Expiring Soon`.
4. Set `paymentStatus: unpaid`. Confirm it displays `Unpaid`.
5. Set `paymentStatus: partial` with a future end date. Confirm it displays `Partial`.
6. Remove current plan/subscription summary fields. Confirm it displays `No Subscription` or the no-summary notice.
7. Confirm Add Member still opens and saves normally.
8. Confirm Payments still records renewals and shows the selected member's effective status hint.
9. Confirm check-in behavior is unchanged.
