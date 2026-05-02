# Phase 2O-B - Member Edit UI

## What Changed

Phase 2O-B adds an edit action to the Member Detail screen and opens a mobile-safe edit sheet for updating an existing member through `MemberRepository.updateMemberProfileAndAccess`.

The UI updates only the existing gym-scoped member document:

- `gyms/{gymId}/members/{memberId}`

No Firestore structure was changed.

## Who Can Edit

The Edit Member action is visible only when the signed-in profile is active and the role has the relevant capability:

- owner
- admin
- reception

The action is hidden for coach, member, inactive, unknown, and missing profiles.

The UI separates capabilities so future roles can edit basic profile fields without managing access identifiers:

- `RoleCapabilities.canEditMember`
- `RoleCapabilities.canManageMemberAccess`

## Fields Shown

The edit sheet prefills and submits:

- `fullName`
- `phone`
- `email`
- `status`
- `notes`
- `nfcTagId`
- `qrCode`
- `accessCode`
- `accessStatus`

Access fields are disabled if the user cannot manage member access.

## Validation Rules

Before saving:

- full name is required
- phone is required
- email may be empty
- non-empty email must look like an email address
- access status is selected from `active`, `disabled`, `lost`, and `replaced`

Repository validation still runs after UI validation.

## Save Behavior

On Save:

- the modal remains open
- the Save button is disabled and shows a saving state
- the repository is called with the current `gymId` and `memberId`
- on success, the modal closes and a success SnackBar is shown
- the member detail provider is invalidated so the page reloads the updated member

On `StateError`, the modal remains open and the exact repository message is shown.

On `FirebaseException`, the modal remains open and a friendly Firestore error is shown.

## Duplicate Error Behavior

Duplicate prevention is handled by the Phase 2O-A repository method. The UI preserves the exact duplicate messages:

- `This NFC tag is already assigned to another member.`
- `This QR code is already assigned to another member.`
- `This access code is already assigned to another member.`

## Known Limitations

- No image upload.
- No Firebase Auth email update.
- No bulk edit.
- No changes to invites, plans, payments, dashboard, settings, subscriptions, or check-in logic.
