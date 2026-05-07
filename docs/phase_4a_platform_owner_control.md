# Phase 4A: Platform Owner Control

## What changed

- Added a platform-level role foundation for `platformOwner`.
- Added a central tenant access check for the signed-in user's `defaultGymId`.
- Added a minimal `/platform` Platform Admin screen.
- Added platform admin repository/provider support for listing gyms and changing tenant status.
- Updated Firestore rules so tenant-control fields are managed only by `platformOwner`.

## New role and capability

- `platformOwner` is a platform-level role stored on `users/{uid}.role`.
- It is not treated as normal gym staff.
- It can access `/platform`.
- It is not blocked by suspended or cancelled gym tenant status.
- Existing roles remain `owner`, `admin`, `reception`, `coach`, and `member`.
- Invite-based user creation still only allows normal gym roles, so normal users cannot create themselves as `platformOwner` through the app flow.

## Firestore fields

Tenant control fields live on the existing gym document:

- `gyms/{gymId}.tenantStatus`: `active`, `suspended`, or `cancelled`
- `suspendedAt`
- `suspendedBy`
- `suspensionReason`
- `resumedAt`
- `resumedBy`
- `cancellationReason`
- `updatedAt`
- `updatedBy`

Missing `tenantStatus` is treated as `active` for backward compatibility.

## Tenant status behavior

- `active`: existing gym app flows work normally.
- `suspended`: normal gym users are routed to a full-page blocked message.
- `cancelled`: normal gym users are routed to a full-page blocked message.
- `platformOwner`: can still access Platform Admin regardless of tenant status.
- Inactive user profiles remain blocked before tenant status is considered.

Blocked messages:

- Suspended: `Gym access is temporarily suspended. Please contact platform support.`
- Cancelled: `Gym access is no longer active. Please contact platform support.`

## Platform Admin screen behavior

The `/platform` screen is only available to `platformOwner`.

It lists documents from `gyms` and shows:

- name
- slug
- status and tenantStatus
- country
- currency
- phone and email
- createdAt and updatedAt when present

Actions:

- Suspend gym: requires confirmation and a reason.
- Resume gym: requires confirmation and sets `tenantStatus` back to `active`.
- Mark as cancelled: requires confirmation and a reason.

Writes include `updatedAt` and `updatedBy`. Resume preserves existing reasons and writes `resumedAt` and `resumedBy`.

## Firestore rules summary

- Signed-out access remains denied.
- `platformOwner` can read the `gyms` collection and individual gym documents.
- `platformOwner` can update only tenant-control fields plus `updatedAt` and `updatedBy`.
- Normal gym owners/admins can still update regular gym profile fields only when the gym is active.
- Normal gym owners/admins cannot update `tenantStatus`, suspension fields, resume fields, or cancellation reason.
- Normal gym users can still read their own `gyms/{gymId}` document so the app can show the tenant blocked message.
- Normal gym users cannot read or write gym subcollections when the gym is suspended or cancelled.
- Cross-gym access remains tied to `users/{uid}.defaultGymId`.
- Existing deletion restrictions remain unchanged.

## Intentionally not changed

- Arabic localization was not implemented.
- Member deletion was not implemented.
- Staff deletion was not implemented.
- Existing Dashboard, Members, Payments, Check-in, Finance, Settings, Member App, and AI UI was not redesigned.
- Existing gym-scoped collection paths were not changed.
- Existing normal role permissions were not broadened.
- Phase 4B was not started.

## Manual tests

- Sign in as a `platformOwner` and open `/platform`.
- Sign in as a normal owner and verify `/platform` redirects away.
- As `platformOwner`, suspend a gym with a reason.
- Sign in as that gym's owner, admin, reception, coach, and member and verify the suspended message is shown.
- As `platformOwner`, resume the gym.
- Verify resumed gym users can access their allowed pages again.
- As `platformOwner`, mark the gym cancelled with a reason.
- Verify cancelled gym users are blocked.
- Verify inactive users are still blocked.
- Verify cross-gym access remains blocked by trying to read another gym's data.
- Verify normal owner/admin users cannot directly update tenant-control fields.
- Verify Dashboard, Members, Payments, Check-in, Finance, and Settings still work for active gyms.

## Known limitations

- This phase assumes `platformOwner` user profiles are provisioned securely outside the normal invite/signup flow.
- Suspended or cancelled users can still read their own top-level `gyms/{gymId}` document only so the app can show a friendly tenant-status message.
- Existing pending invites are not deleted or cancelled when a tenant is suspended or cancelled.
