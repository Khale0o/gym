# Phase 2S - Member Attendance History

## What Changed

Phase 2S upgrades Member Detail with read-only attendance session visibility.

Added:

- member-scoped attendance session stream
- Attendance Status card
- Attendance Sessions history section
- Legacy Check-in Logs label for the existing `checkins` history

No check-out action was added to Member Detail.

## Firestore Paths Used

Attendance sessions are read only from:

- `gyms/{gymId}/attendanceSessions`

Filtered by:

- `memberId == selected member id`

Legacy logs remain read from:

- `gyms/{gymId}/checkins`

No top-level collections are used.

## Session Fields Displayed

The Member Detail UI displays:

- `status`
- `checkInAt`
- `checkOutAt`
- `durationMinutes`
- `checkInMethod`
- `checkOutMethod`
- `planName`
- `notes`

Missing values are shown with friendly fallbacks such as `Unknown`, `Still inside`, or `-`.

## Active Session Display

If the member has an active session, the Attendance Status card shows:

- `Currently Checked In`
- check-in time
- duration so far
- check-in method
- plan name

If the member has no active session, it shows:

- `Not currently checked in`
- last completed checkout time if available
- otherwise a friendly empty state

## Duration Rules

- If `checkOutAt` and `durationMinutes` exist, `durationMinutes` is displayed.
- If `checkOutAt` exists but `durationMinutes` is missing, duration is computed from `checkInAt` to `checkOutAt`.
- If the session is active, duration is computed from `checkInAt` to `DateTime.now()`.
- Missing or malformed values fall back to `Unknown` instead of crashing.

## Legacy Check-in Compatibility

The existing Member Detail check-in history was not removed. It remains below Attendance Sessions as:

- `Legacy Check-in Logs`

The old `gyms/{gymId}/checkins` providers and logic remain intact.

## Firestore Index Notes

The member attendance session provider queries by `memberId` only and sorts by `checkInAt` in app code. This avoids requiring a composite Firestore index for `memberId + checkInAt`.

If this is later changed to `where(memberId) + orderBy(checkInAt)`, Firestore may require a composite index.

## Known Limitations

- The active-session duration updates when the widget rebuilds or stream changes; it is not a live timer.
- Session history is read-only in Member Detail.
- No migration was run for old `checkins`.
- Very large session histories may later need server-side ordering/pagination with indexes.

## Manual Tests

1. Check in a member and open Member Detail.
2. Confirm `Currently Checked In` appears.
3. Confirm Attendance Sessions shows the active session.
4. Check out the member.
5. Reopen Member Detail and confirm the session becomes completed with checkout time/duration.
6. Check in/out the same member multiple times and confirm newest session appears first.
7. Open a member with no sessions and confirm empty state.
8. Open a member with malformed/missing timestamps and confirm no crash.
9. Sign in as coach and confirm read-only member detail still works if allowed.
10. Sign in as member and confirm they cannot see other members.
