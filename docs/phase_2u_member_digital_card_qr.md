# Phase 2U - Member Digital Membership Card QR

## What Changed

Phase 2U adds a production Digital Membership Card to the real-data Member App.

The card renders a local QR code from the member's existing stored access identifier. It does not create, mutate, or backfill Firestore data.

Added dependency:

- `qr_flutter`

## QR Payload Priority

The Member App chooses the QR payload in this order:

1. `member.qrCode`
2. `member.accessCode`
3. `member.nfcTagId`
4. no QR available

If no identifier exists, the card shows:

- `No access credential assigned yet. Please contact the gym.`

No random QR values are generated.

## Card Usability Rules

The card reuses the existing member access eligibility helper.

The card is usable only when:

- `member.status == active`
- `member.accountStatus` is missing, empty, or `active`
- `member.accessStatus` is missing, empty, or `active`
- effective subscription status is `active`, `expiringSoon`, or `partial`

Allowed state:

- `Access Allowed`

Warnings:

- `Subscription expiring soon`
- `Partial payment`

Blocked state:

- `Access Blocked`

Blocked reasons include:

- Member inactive
- Member account inactive
- Access disabled
- Access lost
- Access replaced
- Subscription expired
- Subscription unpaid
- No active subscription

## Firestore Paths Read

The Member App still derives identity only from:

- `users/{uid}.defaultGymId`
- `users/{uid}.linkedMemberId`

It reads:

- `users/{uid}`
- `gyms/{gymId}`
- `gyms/{gymId}/members/{linkedMemberId}`
- `gyms/{gymId}/attendanceSessions`
- `gyms/{gymId}/transactions`

No top-level legacy collections are used.

## QR Is Not The Security Layer

The QR code is only a visual representation of an existing access identifier.

Security still depends on server/client validation already used by check-in:

- member status
- account status
- access status
- active subscription
- subscription expiry
- payment status
- duplicate active attendance session prevention

Scanning the QR value should go through the existing check-in validation flow.

## Known Limitations

- No QR image is stored in Firestore.
- No QR image generation API is called.
- No NFC hardware integration was added.
- No credential rotation or reassignment was added.
- Gym logo display is not added in this phase; gym name falls back to `Your Gym`.

## Manual Tests

1. Sign in as member with `qrCode` and active subscription.
2. Confirm QR renders and is scannable.
3. Type/scan the QR value in Check-in and confirm check-in succeeds.
4. Set subscription end date to yesterday and confirm card shows blocked.
5. Set `accessStatus` to `disabled`, `lost`, or `replaced` and confirm card shows blocked.
6. Remove `qrCode` but keep `accessCode` and confirm QR renders from `accessCode`.
7. Remove all identifiers and confirm no QR available message.
8. Confirm member cannot see another member's card.
9. Confirm no RenderFlex overflow on mobile.
10. Confirm owner/admin/reception flows still work.
