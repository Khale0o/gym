# Phase 2L - Gym Settings / System Settings

## What changed

Added a production gym-scoped Settings screen at `/settings` for owner/admin users.

The screen manages:

- Gym Profile from `gyms/{gymId}`
- Occupancy Settings from `gyms/{gymId}/settings/occupancy`
- Business Settings from `gyms/{gymId}/settings/app`
- Enabled payment methods from `gyms/{gymId}/settings/app`

The screen uses the existing dark/gold app style, supports desktop and mobile layouts, and has separate save buttons per section.

## Firestore paths

- `gyms/{gymId}`
- `gyms/{gymId}/settings/occupancy`
- `gyms/{gymId}/settings/app`

No top-level legacy collections are used.

## Permission rules

Allowed:

- owner
- admin

Blocked:

- reception
- coach
- member
- inactive users
- unknown roles

The Settings nav item is only visible when the existing route access rules allow `/settings`.

## Fields managed

### Gym Profile

Stored on `gyms/{gymId}`:

- `name`
- `slug`
- `country`
- `currency`
- `timezone`
- `status`
- `phone`
- `email`
- `address`
- `logoUrl`
- `updatedAt`
- `updatedBy`

### Occupancy Settings

Stored on `gyms/{gymId}/settings/occupancy`:

- `capacity`
- `maxCapacity`
- `count`
- `updatedAt`
- `updatedBy`

`count` is displayed read-only. Saving capacity does not reset the current count.

### Business Settings

Stored on `gyms/{gymId}/settings/app`:

- `allowPartialPayments`
- `expiringSoonDays`
- `checkInRequiresPaidOrPartial`
- `defaultReceiptPrefix`
- `enabledPaymentMethods`
- `updatedAt`
- `updatedBy`

Supported payment methods:

- `cash`
- `instapay`
- `vodafone_cash`
- `card`
- `online`

## Validation rules

- Gym name is required.
- Currency is required.
- Capacity must be a non-negative integer.
- Expiring soon days must be zero or greater.
- Receipt prefix is required.
- At least one payment method must be enabled.
- Current gym and signed-in user are required for saves.

## Integration notes

Dashboard occupancy capacity already reads from `gyms/{gymId}/settings/occupancy`, preferring `capacity` when available. Payments still show all payment methods for now, with enabled-method filtering left as a future safe integration.

## Manual tests

1. Sign in as owner/admin and confirm Settings appears.
2. Sign in as reception/coach/member and confirm Settings is hidden or blocked.
3. Edit gym name and confirm `gyms/{gymId}.name` updates.
4. Edit capacity and confirm `gyms/{gymId}/settings/occupancy.capacity` updates without resetting `count`.
5. Open Dashboard and confirm capacity-aware occupancy still works.
6. Edit business settings and confirm `gyms/{gymId}/settings/app` updates.
7. Try invalid capacity and confirm save is blocked.
8. Test on mobile and confirm no RenderFlex overflow.
9. Confirm Members, Plans, Payments, Check-in, Staff, and Dashboard still work.

## Known limitations

- Payment method filtering is not enforced in Payments yet.
- Business settings are managed and stored, but not all downstream workflows consume every setting yet.
- Logo URL is stored as text only; no image upload flow is included in this phase.
