# Phase 2K - Real Gym-Scoped Dashboard

## What changed

The Dashboard now reads real gym-scoped production data instead of static demo KPIs. A focused `DashboardRepository` and `dashboardSummaryProvider` aggregate:

- total members
- active members
- active subscriptions
- expired subscriptions
- expiring soon subscriptions
- today check-ins
- today revenue
- month revenue
- current occupancy count
- occupancy capacity when stored
- recent payments / receipts
- recent check-ins

The dashboard is read-only in this phase. Demo seeding and occupancy simulation controls were removed from the Dashboard screen.

## Firestore paths used

Only gym-scoped paths are read:

- `gyms/{gymId}/members`
- `gyms/{gymId}/subscriptions`
- `gyms/{gymId}/transactions`
- `gyms/{gymId}/checkins`
- `gyms/{gymId}/settings/occupancy`

No top-level legacy collections are used for Dashboard KPIs.

## KPI calculation rules

- Total Members: number of docs in `gyms/{gymId}/members`
- Active Members: member `status == active` and `accountStatus` is empty or `active`
- Active Subscriptions: subscription effective status is `active`, `expiringSoon`, or `partial`
- Expired Subscriptions: subscription effective status is `expired`
- Expiring Soon: subscription effective status is `expiringSoon`
- Today Check-ins: check-in `time` is today
- Today Revenue: paid or partial transactions whose date is today
- Month Revenue: paid or partial transactions from the current month
- Current Occupancy: `gyms/{gymId}/settings/occupancy.count`
- Occupancy Capacity: first available positive value from `capacity`, `maxCapacity`, or `gymCapacity`

Subscription status uses the Phase 2I effective status resolver. A subscription ending today is still valid today.

## Date logic

- Today starts at local midnight.
- Tomorrow starts at the next local midnight.
- Current month starts on the first day of the current local month.
- Expiring soon means not expired and within the next 7 days, including today.

## Possible index requirements

The Phase 2K summary stream intentionally listens to gym-scoped collections and sorts recent lists client-side. This avoids introducing new `where + orderBy` composite index requirements in this phase.

If future work moves more sorting/filtering server-side, likely indexes include:

- `transactions`: `createdAt DESC`
- `checkins`: `time DESC`
- `subscriptions`: `endDate DESC` or `startDate DESC`

The Dashboard displays a friendly error if Firestore reports a missing index.

## Performance limitations

This phase computes exact dashboard counts client-side from streamed gym-scoped collections. That is acceptable for the current phase, but larger gyms should eventually use aggregate counters or Cloud Functions for scalable totals and revenue metrics.

Recent payments and check-ins are displayed with sensible limits, but source collections are currently streamed for exact KPI calculations.

## Manual tests

1. Open Dashboard as owner/admin.
2. Confirm no top-level legacy collections are used for KPI data.
3. Add a member and confirm Total Members and Active Members update.
4. Add a paid/partial subscription payment and confirm Active Subscriptions and revenue update.
5. Set a subscription `endDate` to yesterday and confirm Expired Subscriptions updates.
6. Set a subscription `endDate` within 7 days and confirm Expiring Soon updates.
7. Check in a valid member and confirm Today Check-ins and Current Occupancy update.
8. Open an empty gym and confirm zero/empty states render.
9. Remove `defaultGymId` from the user profile and confirm a clear Dashboard error.
10. Confirm Members, Plans, Payments, Check-in, Member Detail, Staff Invites, and Signup Invite flows still work.

## Known future improvements

- Add server-side aggregate counters for large gyms.
- Add per-currency revenue grouping if gyms accept multiple currencies.
- Store an explicit occupancy capacity setting if not already present.
- Add trend comparisons once historical aggregate snapshots exist.
