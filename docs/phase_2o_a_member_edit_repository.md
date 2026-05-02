# Phase 2O-A - Member Edit Repository Foundation

## Scope

Phase 2O-A prepares the backend/repository layer for editing existing member basic info and access identifiers from the app. It does not add or change member editing UI.

## What Changed

- Added role capabilities for future UI gating:
  - `RoleCapabilities.canEditMember`
  - `RoleCapabilities.canManageMemberAccess`
- Added `MemberRepository.updateMemberProfileAndAccess` for gym-scoped member updates.

Owners, admins, and reception staff can edit members and manage member access. Coaches and members cannot.

## Firestore Path

The update method writes only to:

- `gyms/{gymId}/members/{memberId}`

No top-level member, user, invite, subscription, payment, check-in, dashboard, or settings documents are updated.

## Supported Fields

Editable fields handled by the repository method:

- `fullName`
- `phone`
- `email`
- `emailNormalized`
- `status`
- `notes`
- `nfcTagId`
- `nfcTagIdNormalized`
- `qrCode`
- `qrCodeNormalized`
- `accessCode`
- `accessCodeNormalized`
- `accessStatus`
- `updatedAt`
- `accessUpdatedAt`
- `accessAssignedAt`

Existing non-edit fields such as `authUid`, plan/subscription/payment/check-in summaries, `createdAt`, and creator fields are preserved because the method updates only the fields listed above.

## Validation

- `gymId` is required.
- `memberId` is required.
- `fullName` is required.
- `phone` is required.
- Empty email is allowed.
- Non-empty email must look like an email address.
- Access identifiers are trimmed and lowercased into normalized fields.
- Empty access identifiers are allowed.
- If any access identifier exists and `accessStatus` is empty, access status defaults to `active`.
- Supported access statuses are `active`, `disabled`, `lost`, and `replaced`.

## Duplicate Prevention

Duplicate checks are scoped to the current gym only. The member currently being edited is excluded from duplicate detection.

The repository blocks:

- another member with the same normalized NFC tag
- another member with the same normalized QR code
- another member with the same normalized access code

Duplicate errors are field-specific:

- `This NFC tag is already assigned to another member.`
- `This QR code is already assigned to another member.`
- `This access code is already assigned to another member.`

## Timestamp Behavior

- `updatedAt` is always refreshed.
- `accessUpdatedAt` is refreshed only when an access identifier or `accessStatus` changes.
- `accessAssignedAt` is set only when the member previously had no access identifiers and the update assigns at least one identifier.

The method reads the existing member document first so it can decide `accessAssignedAt` correctly.

## Intentionally Not Changed

- No UI was added.
- Member Detail screen was not modified.
- Members screen was not modified.
- Auth, invites, plans, payments, dashboard, settings, subscriptions, and check-in logic were not changed.
- No data migration was run.
- No existing Firestore data was manually modified.
- Route access was not changed.

## Known Limitation

There is no UI yet for editing member basic info or access identifiers. This phase only adds the repository and capability foundation for a later UI phase.

## Manual Repository Tests

Suggested manual checks once UI or a repository harness is available:

1. Update a member's name and phone and confirm only the member document changes.
2. Clear email and confirm `email` and `emailNormalized` become empty/null values without touching auth users.
3. Set email with invalid format and confirm the repository throws a validation error.
4. Assign `NFC001` and confirm `nfcTagIdNormalized` is `nfc001`, `accessStatus` defaults to `active`, and access timestamps are set correctly.
5. Assign the same NFC tag to a different member in the same gym and confirm the field-specific duplicate error.
6. Assign the same NFC tag to a member in a different gym and confirm it is allowed.
7. Edit a member while keeping their own NFC tag unchanged and confirm it does not count as a duplicate.
8. Change only basic info and confirm `updatedAt` changes while `accessUpdatedAt` does not.
9. Start with no identifiers, add one identifier, and confirm `accessAssignedAt` is set.
10. Change an existing identifier and confirm `accessUpdatedAt` changes while `accessAssignedAt` is preserved.
