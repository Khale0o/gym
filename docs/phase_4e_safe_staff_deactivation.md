# Phase 4E: Safe Staff Deactivation / Archive Controls

## What was added

- Added an owner/admin staff archive capability.
- Added a safe archive method on `StaffRepository`.
- Added a low-prominence Archive Staff action on linked staff cards.
- Added a confirmation dialog that requires a reason and explains that history/audit records are preserved.
- Hid archived staff from the default linked staff stream.
- Updated linked staff `users/{uid}` status only when the staff profile has an `authUid`, so archived staff cannot keep entering staff areas through the existing active-user guard.
- Updated Firestore rules narrowly for staff archive fields and linked user archive status updates.
- Added the minimum English and Arabic Egyptian localization keys for this phase.

## Files changed

- `lib/navigation/role_capabilities.dart`
- `lib/repositories/staff_repository.dart`
- `lib/screens/staff/staff_management_screen.dart`
- `lib/l10n/app_localizations.dart`
- `firestore.rules`
- `docs/phase_4e_safe_staff_deactivation.md`

## Data fields

Archiving updates `gyms/{gymId}/staff/{staffId}`:

- `status = inactive`
- `accountStatus = archived`
- `deletedAt = FieldValue.serverTimestamp()`
- `deletedBy = current user uid`
- `deleteReason = trimmed reason`
- `updatedAt = FieldValue.serverTimestamp()`

When the staff record has a linked `authUid`, the repository also updates `users/{authUid}` with:

- `status = inactive`
- `accountStatus = archived`
- `updatedAt = FieldValue.serverTimestamp()`

No Auth user, staff profile, attendance, payment, finance, payroll, invite, or audit/history documents are deleted.

## Why soft archive was used

Soft archive disables staff access while preserving historical references for payroll, audit, finance, attendance, and operational reporting. Hard deletes remain denied.

## Permissions

- Owners and admins can archive staff through the existing `canManageStaff` permission path.
- Reception, coach, and member roles cannot archive staff.
- A signed-in user cannot archive their own staff profile.
- The repository prevents archiving the last active owner staff profile.
- Firestore rules keep archive writes gym-scoped and deny hard deletes.

## Manual test checklist

1. Login as owner.
2. Open Staff Management.
3. Confirm Archive Staff appears on another linked staff card.
4. Confirm Archive Staff does not appear for your own linked staff profile.
5. Open Archive Staff and submit an empty reason.
6. Confirm the required reason validation appears.
7. Enter a reason and confirm archive.
8. Confirm the success SnackBar appears.
9. Confirm `gyms/{gymId}/staff/{staffId}` has the archive fields.
10. If the staff had `authUid`, confirm `users/{authUid}.status = inactive` and `accountStatus = archived`.
11. Confirm historical payroll, finance, attendance, and audit records remain.
12. Confirm the archived staff no longer appears in the default linked staff list.
13. Confirm the archived staff user can no longer access manager/admin/staff areas through the existing active-user guard.
14. Login as admin and confirm archive is allowed for manageable staff.
15. Login as reception/coach/member and confirm archive is not available.
16. Try archiving the last owner and confirm it is blocked.
17. Confirm hard delete is still denied by Firestore rules.

## Known limitations

- This phase does not add an Archived Staff list/filter.
- This phase does not implement restore/unarchive.
- Last-owner protection is enforced in the client repository; Firestore rules keep the archive write narrow but do not aggregate-count owner records.
- Existing user sessions may need to refresh or re-read `users/{uid}` before the active-user guard fully blocks access.

## Flutter analyze result

`flutter analyze` completed. It reported the existing 22 unrelated warnings/infos:

- Existing `withOpacity` deprecation infos in `lib/screens/ai/ai_engine_screen.dart`.
- Existing deprecated `value` usage in `lib/screens/erp/erp_screen.dart`.
- Existing unused import/local variable warnings in `lib/widgets/line_chart_widget.dart`.
- Existing `withOpacity` deprecation infos in `lib/widgets/sparkline_widget.dart`.

No new Phase 4E compile errors were reported.
