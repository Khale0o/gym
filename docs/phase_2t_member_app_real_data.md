# Phase 2T - Member App Real Data

## What Changed

Phase 2T upgrades the Member App screen from static preview data to real gym-scoped data for the signed-in member.

The screen now derives access from `users/{uid}`:

- `defaultGymId`
- `linkedMemberId`

Then it reads the linked member document and member-scoped attendance/payment data.

## Firestore Paths Used

User profile:

- `users/{uid}`

Linked member profile:

- `gyms/{gymId}/members/{linkedMemberId}`

Attendance sessions:

- `gyms/{gymId}/attendanceSessions`
- filtered by `memberId == linkedMemberId`

Payment history:

- `gyms/{gymId}/transactions`
- filtered by `memberId == linkedMemberId`

No top-level legacy collections are used.

## Data Shown

Member profile:

- full name
- phone
- email
- member status
- account status
- access status

Current subscription summary:

- current plan name
- subscription status
- subscription end date
- payment status
- effective status label from the existing resolver

Attendance:

- currently inside / not currently inside
- active check-in time
- duration so far
- latest completed checkout
- latest attendance sessions

Receipts/payment history:

- receipt number
- amount and currency
- payment method
- payment status
- created date
- notes

Access credentials:

- access code
- QR code value
- NFC tag ID
- access status

No QR image generation or NFC hardware integration was added.

## Member Safety Rules

The Member App does not accept a route member ID and does not let the member choose another member.

It always derives `gymId` and `linkedMemberId` from `users/{uid}`. If `linkedMemberId` is missing, the screen shows:

- `Your member profile is not linked yet. Please contact the gym.`

If the member document is missing, it shows:

- `Member profile not found. Please contact the gym.`

Permission and index errors are shown as friendly UI messages instead of crashing.

## Attendance Behavior

Attendance sessions are queried by `memberId` and sorted in app code by `checkInAt` descending to avoid requiring a composite Firestore index.

The screen shows active sessions as `Currently inside` and completed sessions in compact history rows.

## Receipts Behavior

Transactions are queried by `memberId` and sorted by the existing transaction repository in app code. The UI shows the latest 10 receipts.

If no transactions exist, it shows:

- `No payments yet.`

## Known Limitations

- Attendance duration updates when the screen rebuilds or streams update; it is not a live timer.
- The Access tab displays credential values only; it does not generate QR images.
- The screen remains a compact mobile-style member view.
- Very large histories may later need pagination/indexed server-side ordering.

## Manual Tests

1. Sign in as a member created from invite.
2. Confirm Member App opens automatically.
3. Confirm member name/phone/email are real.
4. Confirm current subscription card matches Firestore.
5. Renew member from Payments as reception/admin, then sign in as member and confirm updated plan/end date.
6. Check in the member and confirm Member App shows currently inside.
7. Check out the member and confirm latest attendance updates.
8. Confirm attendance history shows latest sessions.
9. Confirm payment history shows latest receipts.
10. Remove `linkedMemberId` from `users/{uid}` and confirm friendly error.
11. Delete or block the member document and confirm no crash.
12. Confirm member cannot view another member's data.
