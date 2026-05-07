# Phase 4D: Safe Member Deactivation / Archive Controls

## What was added

- Added an owner/admin-only member archive capability.
- Added a safe archive method on `MemberRepository`.
- Added an Archive Member action in Member Detail.
- Added a confirmation dialog that requires a reason and explains that history is preserved.
- Hid archived members from the default member stream.
- Added specific archived-account blocking for check-in validation.
- Updated Firestore rules so only owner/admin can write archive control fields.
- Added the minimum English and Arabic Egyptian localization keys for this phase.

## Files changed

- `lib/navigation/role_capabilities.dart`
- `lib/repositories/member_repository.dart`
- `lib/models/member_access_eligibility.dart`
- `lib/repositories/checkin_repository.dart`
- `lib/screens/members/member_detail_screen.dart`
- `lib/screens/member_app/member_app_screen.dart`
- `lib/screens/checkin/checkin_screen.dart`
- `lib/l10n/app_localizations.dart`
- `firestore.rules`
- `docs/phase_4d_safe_member_deactivation.md`

## Data fields

Archiving updates only `gyms/{gymId}/members/{memberId}`:

- `status = inactive`
- `accountStatus = archived`
- `deletedAt = FieldValue.serverTimestamp()`
- `deletedBy = current user uid`
- `deleteReason = trimmed reason`
- `updatedAt = FieldValue.serverTimestamp()`

No payments, subscriptions, check-ins, attendance sessions, transactions, receipts, finance records, or audit-related documents are deleted.

## Why soft delete was used

Soft archive preserves operational history and auditability. Member payment records, attendance history, receipts, and finance references can still exist for reporting and compliance while the member is blocked from normal access.

## Permissions and rules

- Owners and admins can archive members.
- Reception, coach, member, and self-service member users cannot archive members.
- Hard deletes remain denied.
- Firestore rules allow archive writes only for the archive fields listed above.
- Normal owner/admin/reception member profile edits cannot modify archive control fields unless using the safe owner/admin archive update.
- Cross-gym access and suspended-tenant restrictions remain unchanged.

## Access behavior

- Archived members are hidden from the default members list stream.
- Archived members cannot check in because `accountStatus = archived` is blocked by validation.
- Member App access uses the existing eligibility flow and shows an archived/blocked state instead of normal active access.

## Known limitations

- This phase does not add a full Archived Members list/filter. Archived members are hidden from the default list; they remain in Firestore for audit/history.
- This phase does not implement restore/unarchive.
- This phase does not backfill older deleted/archived records.

## Manual test checklist

1. Login as owner.
2. Open Members and then a Member Detail screen.
3. Confirm Archive Member is visible.
4. Open Archive Member and try submitting an empty reason.
5. Confirm validation blocks empty reason.
6. Enter a reason and confirm archive.
7. Confirm success SnackBar appears.
8. Confirm `gyms/{gymId}/members/{memberId}` has the archive fields.
9. Confirm payments, subscriptions, attendance, transactions, receipts, and finance data remain.
10. Confirm the archived member no longer appears in the default Members list.
11. Try check-in for the archived member and confirm it is blocked.
12. Login as the archived member and confirm Member App shows blocked/friendly state.
13. Login as admin and confirm archive is allowed.
14. Login as reception/coach/member and confirm archive is not available.
15. Confirm hard delete is still denied by Firestore rules.

## Flutter analyze result

`flutter analyze` completed. It reported the existing 22 unrelated warnings/infos:

- Existing `withOpacity` deprecation infos in `lib/screens/ai/ai_engine_screen.dart`.
- Existing deprecated `value` usage in `lib/screens/erp/erp_screen.dart`.
- Existing unused import/local variable warnings in `lib/widgets/line_chart_widget.dart`.
- Existing `withOpacity` deprecation infos in `lib/widgets/sparkline_widget.dart`.

No new Phase 4D compile errors were reported.
