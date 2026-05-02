# Phase 2N - Access Identifiers Check-in

## Scope

Phase 2N adds production data fields for member access credentials and lets staff check in a member by typing or scanner-wedge input. It does not add camera scanning, NFC hardware integration, QR image generation, Cloud Functions, or payment changes.

## Firestore Paths

Member access data is stored on member documents only:

- `gyms/{gymId}/members/{memberId}`

Check-ins continue to be written by the existing subscription-aware flow:

- `gyms/{gymId}/checkins/{checkinId}`
- `gyms/{gymId}/settings/occupancy`

## Fields Added

Optional member fields:

- `nfcTagId`
- `nfcTagIdNormalized`
- `qrCode`
- `qrCodeNormalized`
- `accessCode`
- `accessCodeNormalized`
- `accessStatus`
- `accessAssignedAt`
- `accessUpdatedAt`

Recommended `accessStatus` values:

- `active`
- `disabled`
- `lost`
- `replaced`

Existing member documents without these fields still deserialize and render safely. Missing `accessStatus` is treated as allowed during scan check-in, so legacy members are not blocked by absent access metadata.

## Duplicate Prevention

Before creating a member, the app checks duplicates inside the current gym only:

- no two members in `gyms/{gymId}/members` can share the same normalized `nfcTagId`
- no two members in `gyms/{gymId}/members` can share the same normalized `qrCode` or `accessCode`

Values are trimmed and lowercased before comparison. The duplicate check does not use a global collection and does not check across gyms.

## Scan / Check-in Flow

The Check-in screen has a `Scan NFC / QR / Access Code` field and a `Check In` button. Hardware scanners that type into a focused field can use this without special integration.

On submit:

1. The entered code is trimmed.
2. Empty input is blocked.
3. `MemberRepository.findMemberByAccessCode` searches the current gym's members for matching `nfcTagId`, `qrCode`, or `accessCode`.
4. Unknown codes show `Access code not found`.
5. If more than one member matches, the lookup throws a clear duplicate-match error instead of guessing.
6. `accessStatus` values `disabled`, `lost`, and `replaced` are blocked.
7. Missing or `active` access status proceeds to `CheckInRepository.checkInMember`.
8. The repository keeps enforcing member status, active subscription, expiry, paid-or-partial payment status, check-in write, and occupancy increment.

## Manual Tests

1. Add member with `NFC001` and Basic paid plan.
2. Confirm member doc has `nfcTagId`, `nfcTagIdNormalized`, and `accessStatus`.
3. Open Check-in and enter `NFC001`.
4. Confirm check-in succeeds and occupancy increments.
5. Try unknown code and confirm blocked.
6. Try duplicate `NFC001` for another member and confirm blocked.
7. Set member `accessStatus = "disabled"` and confirm scan is blocked.
8. Set subscription `endDate` to yesterday and confirm scan finds member but check-in is blocked as expired.
9. Add member with `QR001` and confirm QR/access code lookup works.
10. Confirm existing members without NFC/QR still render safely.

## Known Limitations

- Lookup is implemented in app code against the current gym's member collection so it can compare normalized values and tolerate legacy documents. Very large gyms may later need indexed lookup fields or a dedicated gym-scoped access identifier collection.
- There is no actual camera, NFC hardware, QR image generation, or Cloud Function in this phase.
- Access identifiers are read-only after creation in this phase.
