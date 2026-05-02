# Phase 2F Subscription-Aware Check-In

## What changed

Check-in validation now uses the signed-in user's `users/{uid}.defaultGymId`
through `currentGymIdProvider`. The check-in screen reads members from
`gyms/{gymId}/members`, writes check-ins to `gyms/{gymId}/checkins`, and updates
occupancy at `gyms/{gymId}/settings/occupancy`.

## Firestore paths

- Members: `gyms/{gymId}/members/{memberId}`
- Subscriptions: `gyms/{gymId}/subscriptions/{subscriptionId}`
- Check-ins: `gyms/{gymId}/checkins/{checkinId}`
- Occupancy: `gyms/{gymId}/settings/occupancy`

## Validation rules

A check-in is allowed only when:

- current gym context exists
- member document exists in the current gym
- member `status` is `active`
- member `accountStatus`, when present, is `active`
- member summary `subscriptionStatus`, when present, is `active`
- member summary `subscriptionEndDate`, when present, is today or later
- an active subscription document exists for the member
- subscription `endDate` is today or later
- subscription `paymentStatus` is `paid` or `partial`

Blocked states show clear errors:

- `Member not found.`
- `Member is inactive.`
- `No active subscription.`
- `Subscription expired.`
- `Unpaid subscription.`
- `Missing gym context.`

## Atomic transaction

`CheckInRepository.checkInMember` selects the current active subscription, then
re-reads the member, subscription, and occupancy documents inside a Firestore
transaction. If validation still passes, the transaction:

- creates a check-in document
- increments `settings/occupancy.count`
- creates the occupancy document if it does not exist
- updates the member `lastCheckInAt`

Manual occupancy changes use a transaction and clamp the count to zero or above.

## Manual tests

1. Add a member with Basic plan, `paid`, active subscription.
2. Check in the member and verify `gyms/gym_001/checkins/{checkinId}` exists.
3. Verify `gyms/gym_001/settings/occupancy.count` increments.
4. Set member `subscriptionStatus` to `expired`; check-in should be blocked.
5. Set member `subscriptionEndDate` to yesterday; check-in should be blocked.
6. Set subscription `paymentStatus` to `unpaid`; check-in should be blocked.
7. Set member `status` or `accountStatus` to inactive; check-in should be blocked.
8. Delete `gyms/gym_001/settings/occupancy`; valid check-in should recreate it.
9. Use manual decrement at zero; occupancy should never go negative.
10. Verify existing auth and role navigation still work.

## Not included

- POS
- receipts
- online payments
- dashboard KPI migration
- check-in hardware integration
- AI backend changes
- NFC active-session uniqueness
