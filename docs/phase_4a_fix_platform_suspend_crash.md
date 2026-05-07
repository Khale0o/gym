# Phase 4A-Fix: Platform Suspend/Resume/Cancel Crash

## Likely crash cause

The original Platform Admin actions collected a dialog result first, then ran the async Firestore write from the tenant card after the dialog closed. That made the action depend on a different widget context and left less protection around async errors, duplicate submits, and context use after awaits.

During this fix, a compile issue was also introduced by calling `showDialog` with a positional context argument. Flutter requires `context:` as a named argument.

## What was fixed

- Moved Suspend, Resume, and Cancel writes into stateful dialogs.
- Added dialog-local loading state.
- Disabled dialog buttons while saving.
- Prevented duplicate submits with `_saving` guards.
- Added empty reason validation for Suspend and Cancel.
- Called `FocusScope.of(context).unfocus()` before starting each async action.
- Wrapped each action in `try/catch/finally`.
- Caught `FirebaseException`, `StateError`, and generic errors.
- Kept dialogs open when a write fails.
- Closed dialogs only after the repository update succeeds.
- Shows a success SnackBar after a successful action.
- Debug logs technical failures only in debug mode.
- Fixed `showDialog` calls to use named `context:` arguments.

## Dialog safety behavior

- Empty Suspend/Cancel reasons show inline validation and do not write.
- While saving, Close and action buttons are disabled.
- Rapid double taps are ignored by `_saving` checks.
- Permission and Firestore availability errors are converted to friendly messages.
- No exception from the tenant action is intentionally allowed to escape to the widget tree.

## Firestore tenant-control fields written

Suspend writes only:

- `tenantStatus = suspended`
- `suspendedAt = FieldValue.serverTimestamp()`
- `suspendedBy = current uid`
- `suspensionReason = trimmed reason`
- `updatedAt = FieldValue.serverTimestamp()`
- `updatedBy = current uid`

Resume writes only:

- `tenantStatus = active`
- `resumedAt = FieldValue.serverTimestamp()`
- `resumedBy = current uid`
- `updatedAt = FieldValue.serverTimestamp()`
- `updatedBy = current uid`

Cancel writes only:

- `tenantStatus = cancelled`
- `cancellationReason = trimmed reason`
- `updatedAt = FieldValue.serverTimestamp()`
- `updatedBy = current uid`

## Firestore rules compatibility notes

- The app writes only fields allowed by the Phase 4A `tenantUpdateFields()` rule.
- Normal owner/admin gym profile updates remain blocked from tenant-control fields by `doesNotAffectTenantControl()`.
- No broad gym update permission was added.
- Tenant fields remain on `gyms/{gymId}`.

## Manual tests

1. Login as `platformOwner`.
2. Open `/platform`.
3. Suspend a gym with reason.
4. Confirm no crash.
5. Confirm dialog closes on success.
6. Confirm success SnackBar appears.
7. Confirm `gyms/{gymId}.tenantStatus` becomes `suspended`.
8. Confirm normal gym users are blocked.
9. Resume gym and confirm access returns.
10. Cancel gym with reason and confirm no crash.
11. Try empty reason and confirm validation.
12. Rapid double tap action and confirm no duplicate unsafe behavior.

## Known limitations

- This fix does not add Phase 4B localization.
- This fix does not add new tenant lifecycle features.
- Firestore rule deployment and real-device verification still need to be done in the Firebase environment.
