# Phase 2J - Member Detail Timeline

## What was added

Member Detail is now a production timeline page. It keeps the existing member profile/metrics layout and adds read-only cards for:

- member summary header
- current subscription
- payments and receipts
- subscription history
- check-in history
- quick actions for Back to Members and Record Payment / Renew

The page reuses the Phase 2I `EffectiveSubscriptionStatus` helper so stale member summary fields do not blindly display as active when the end date is already past.

## Firestore paths used

All reads remain gym-scoped:

- `gyms/{gymId}/members/{memberId}`
- `gyms/{gymId}/subscriptions/{subscriptionId}`
- `gyms/{gymId}/transactions/{transactionId}`
- `gyms/{gymId}/checkins/{checkinId}`

This phase does not write or mutate Firestore data.

## Queries used

Existing providers are reused for:

- member detail: `gymMemberByIdProvider(memberId)`
- member subscriptions: `memberSubscriptionsProvider(memberId)`
- member transactions: `memberTransactionsProvider(memberId)`

New support was added for:

- member check-ins: `memberCheckinsProvider(memberId)`

The check-in query filters by `memberId`, sorts in app by `time` descending, and displays the latest 10 rows. The existing subscription and transaction streams also sort in app and the Member Detail UI displays the latest 10 rows.

## Possible index requirements

The current member-specific history streams intentionally avoid `where + orderBy` compound Firestore queries where possible, so they should not require new composite indexes.

If a future query adds server-side ordering such as `where('memberId') + orderBy('createdAt')`, Firestore may require composite indexes for:

- `subscriptions`: `memberId ASC, startDate/createdAt DESC`
- `transactions`: `memberId ASC, createdAt DESC`
- `checkins`: `memberId ASC, time/createdAt DESC`

The UI shows a friendly message if Firestore returns an index-related error.

## Quick actions

- Back to Members routes to `/members`.
- Record Payment / Renew routes to `/payments`.

Payments member preselection is left as a future enhancement because the current Payments route does not support preselected member parameters.

## Manual tests

1. Open a member with a current subscription summary and confirm the effective status badge matches Phase 2I rules.
2. Renew the member from Payments, then reopen Member Detail and confirm the new transaction appears in Payments / Receipts.
3. Confirm the new subscription appears in Subscription History.
4. Check in a valid member, then reopen Member Detail and confirm the check-in appears in Check-in History.
5. Open a member with no payments, subscriptions, or check-ins and confirm all empty states render.
6. Temporarily test missing index behavior if Firestore asks for an index and confirm a friendly section-level error appears.
7. Confirm Add Member, Payments, Plans, Check-in, and Invite flows still work.

## Known limitations

- History sections display the latest 10 rows after app-side sorting.
- Record Payment / Renew does not preselect the member yet.
- No automatic subscription expiry writes or cleanup happen in this phase.
