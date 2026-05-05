# Phase 2R Duplicate Check-in Bugfix

## What Caused The Crash

After Phase 2R, duplicate active sessions were correctly blocked in the repository with:

- `StateError('Member is already checked in.')`

The Check-in screen still handled check-in errors through a broad raw `toString()` path and reset submit state inside individual branches. That made duplicate scan failures brittle and could surface as an app crash instead of a clean user-facing error.

## What Was Fixed

The Check-in screen now catches check-in failures by type:

- `StateError`
- `FirebaseException`
- generic `Object`

For `StateError`, the UI strips framework prefixes such as `Bad state: ` and shows the exact message:

- `Member is already checked in.`

For `FirebaseException`, the UI shows a friendly Firestore message.

For unexpected errors, the UI shows:

- `Check-in failed. Please try again.`

Unexpected errors are logged with `debugPrint` only in debug mode.

## Expected Duplicate Scan Behavior

1. First valid scan/check-in succeeds.
2. Second scan/check-in for the same active member is blocked.
3. A red SnackBar shows `Member is already checked in.`
4. No duplicate `attendanceSessions` document is created.
5. No duplicate `checkins` log is created.
6. Occupancy does not increment for the failed duplicate attempt.
7. The Check-in screen remains usable.

## Transaction Safety

Duplicate active sessions are blocked before any transaction writes.

The repository checks:

- active `gyms/{gymId}/attendanceSessions` docs for the member
- `member.activeAttendanceSessionId`

If either indicates the member is already checked in, the transaction throws before writing check-in logs, attendance sessions, occupancy, or member fields.

## Manual Tests

1. Check in a valid active paid member.
2. Immediately scan/check in the same member again.
3. Confirm no crash.
4. Confirm SnackBar says `Member is already checked in.`
5. Confirm only one active attendance session exists.
6. Confirm occupancy did not increment the second time.
7. Check out the member.
8. Scan/check in the member again and confirm it succeeds after checkout.
9. Rapidly double tap the Check In button and confirm no crash or duplicate session.

## Not Changed

- No new features.
- No UI redesign.
- No auth, invite, plan, payment, dashboard, settings, subscription, member edit, or member app logic changes.
