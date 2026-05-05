# Phase 2R - Attendance Sessions

## What Changed

Phase 2R upgrades attendance from simple check-in logs to active attendance sessions with check-in and check-out.

The existing `checkins` collection is still written so Dashboard and Member Detail history remain compatible.

## Firestore Paths

Existing check-in log path kept:

- `gyms/{gymId}/checkins/{checkinId}`

New attendance session path:

- `gyms/{gymId}/attendanceSessions/{sessionId}`

Occupancy remains:

- `gyms/{gymId}/settings/occupancy`

Member summary updates remain:

- `gyms/{gymId}/members/{memberId}`

## Attendance Session Fields

Session documents may include:

- `gymId`
- `memberId`
- `memberName`
- `memberPhone`
- `subscriptionId`
- `planId`
- `planName`
- `checkInAt`
- `checkOutAt`
- `durationMinutes`
- `status`: `active`, `completed`, or `cancelled`
- `checkInMethod`: `access_code`, `nfc`, `qr`, or `manual`
- `checkOutMethod`: `manual`, `auto`, or `system`
- `createdBy`
- `checkedOutBy`
- `createdAt`
- `updatedAt`
- `notes`

The member document also stores `activeAttendanceSessionId` while the member is checked in.

## Check-In Behavior

`CheckInRepository.checkInMemberWithSession` preserves the existing subscription-aware validation:

- gym/member context must be valid
- member must exist
- member status must be active
- account status must be active, missing, or empty
- access status must be active, missing, or empty
- active subscription must exist
- subscription must not be expired
- payment status must be paid or partial

On successful check-in, one transaction:

- creates the legacy `checkins` log
- creates an `attendanceSessions` document with `status: active`
- increments occupancy
- updates `member.lastCheckInAt`
- sets `member.activeAttendanceSessionId`

## Check-Out Behavior

`CheckInRepository.checkOutMember` finds the active session for the member.

If none exists, it throws:

- `Member is not currently checked in.`

On successful check-out, one transaction:

- sets `checkOutAt`
- calculates `durationMinutes`
- sets `status: completed`
- stores `checkOutMethod`
- stores `checkedOutBy`
- decrements occupancy safely
- updates `member.lastCheckOutAt`
- clears `member.activeAttendanceSessionId`

## Duplicate Active Session Prevention

Duplicate check-in is blocked before creating a new session.

The repository checks:

- existing active `attendanceSessions` for the member
- `member.activeAttendanceSessionId`

If the member is already checked in, it throws:

- `Member is already checked in.`

The member document is read and written in the transaction so concurrent duplicate check-ins retry against the updated member state.

## Occupancy Behavior

Check-in increments occupancy by one.

Check-out decrements occupancy by one and clamps the value so it never goes below zero.

Manual occupancy controls remain unchanged.

## Role And Security Expectations

Firestore rules keep sessions gym-scoped:

- owner/admin/reception can create and update attendance sessions
- coach can read sessions through existing staff read rules but cannot write
- member users can read only their own sessions
- inactive users are blocked
- cross-gym access is blocked
- deletes are blocked

## Providers And UI

Added gym-scoped providers for:

- active attendance sessions
- a member's active attendance session
- recent attendance sessions

The Check-in screen now shows an Active Sessions section with member name, check-in time, duration so far, and a Check Out button.

## Known Limitations

- Duration shown in the Active Sessions list updates when the widget rebuilds or session stream changes; it is not a live timer.
- Auto check-out is not implemented.
- Session history was not added to Member Detail in this phase.
- Dashboard KPIs still use the existing check-in logs for compatibility.

## Manual Tests

1. Check in an active paid member.
2. Confirm an active document is created under `gyms/{gymId}/attendanceSessions`.
3. Confirm a legacy `gyms/{gymId}/checkins` log still exists.
4. Confirm occupancy increments.
5. Scan the same member again and confirm `Member is already checked in.`
6. Check out the member and confirm the session becomes `completed`.
7. Confirm occupancy decrements and never goes below zero.
8. Try checking out a member with no active session and confirm blocked.
9. Try expired or unpaid member check-in and confirm it is still blocked.
10. Confirm Dashboard still opens.
11. Confirm Member Detail still opens and check-in history still loads.
