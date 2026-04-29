# Phase 2E Plans and Subscriptions

## Firestore paths

- Plans: `gyms/{gymId}/plans/{planId}`
- Subscriptions: `gyms/{gymId}/subscriptions/{subscriptionId}`
- Members: `gyms/{gymId}/members/{memberId}`

## Models

- `MembershipPlan`: name, description, price, currency, duration days,
  features, active state, timestamps.
- `GymSubscription`: member, plan, dates, status, payment status, amount,
  currency, payment method, createdBy, timestamps, cancellation, notes.

## Status values

Subscription status:

- `active`
- `expired`
- `pending`
- `cancelled`

Payment status:

- `paid`
- `unpaid`
- `partial`

Payment method:

- `cash`
- `instapay`
- `vodafone_cash`
- `card`
- `online`
- `unknown`

## Add Member behavior

Add Member remains gym-scoped. If a plan is selected, the app uses a batched
write to create:

- the member document
- optional member invite, when email is provided
- the subscription document
- member summary fields: `currentPlanId`, `currentPlanName`,
  `subscriptionStatus`, `subscriptionEndDate`

Duplicate invite checks happen before the batch. If no plan is selected, only
the member and optional invite are created.

## Plans UI

Owner/admin can access `/plans` and create plans. The screen includes a guarded
"Create default plans" action that only works if the gym has no plans.

Reception cannot manage plans, but can view active plans inside Add Member and
assign an initial subscription to a new member.

## Manual tests

1. As owner/admin, open Plans and create default plans.
2. As reception, verify Plans nav is hidden but Add Member can select active
   plans.
3. Add a member with Basic plan, payment status `paid`, payment method `cash`.
4. Verify `gyms/{gymId}/members/{memberId}` exists.
5. Verify `gyms/{gymId}/memberInvites/{inviteId}` exists if email was provided.
6. Verify `gyms/{gymId}/subscriptions/{subscriptionId}` exists.
7. Verify member has `currentPlanId`, `currentPlanName`,
   `subscriptionStatus`, and `subscriptionEndDate`.
8. Add a member without selecting a plan and verify creation still succeeds.
9. Sign in as a member and verify the member app does not crash.
10. As coach/member, verify Plans route is hidden/blocked.

## Known limitations

- No POS, receipts, online payment gateway, or real finance reporting.
- Dashboard and finance screens still use their existing legacy data.
- Check-in is not blocked by expired subscriptions yet.
- Member app is only guarded against missing linked member data; it is not fully
  migrated to subscription-driven content.
- NFC active-session uniqueness is not part of this phase.
