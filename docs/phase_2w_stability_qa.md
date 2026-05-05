# Phase 2W - Stability QA

## What Was Reviewed

This pass reviewed the main implemented production flows after Phase 2V Firestore rule hardening:

- Dashboard
- Members
- Member Detail
- Plans
- Payments
- Check-in
- Staff Management
- Settings
- Member App
- Staff invite signup/claim
- Member invite signup/claim

The review focused on loading/error/empty states, permission-denied behavior, missing gym/profile/member/settings data, invite signup failures, and check-in/check-out failure paths.

## What Was Fixed

- Check-in occupancy update errors now use the shared friendly Firestore error formatter.
- Check-out errors now use the shared friendly Firestore error formatter.
- Check-in access log, occupancy, and active-session stream errors now show readable messages instead of raw errors.
- Permission-denied check-in messages now explain that the account may be inactive or not linked to the gym.
- Invite signup validates full name, email, and password before creating a Firebase Auth account.
- Invite signup maps post-auth invite lookup/claim failures into clearer messages for missing indexes, permission-denied, expired invites, and no pending invite.
- Invite signup cleanup wording now applies to both staff and member invite flows.
- Shared permission-denied text now tells users to contact the gym owner/admin.

## Screens Checked

- Dashboard: loading, unavailable, missing gym, and permission/index message paths reviewed.
- Members: loading, empty, permission/index errors, and create-member failure SnackBars reviewed.
- Member Detail: missing member, coach read-only billing restriction, history card errors, and edit failure SnackBars reviewed.
- Plans: loading, empty, list errors, default creation errors, and plan save errors reviewed.
- Payments: missing gym/profile/member/plan, disabled payment method, transaction list errors, and save failure SnackBars reviewed.
- Check-in: duplicate check-in, no active checkout session, expired subscription, unpaid subscription, disabled/lost/replaced access, permission-denied, and stream errors reviewed.
- Staff Management: linked staff/invite stream errors, invite create errors, and invite cancellation errors reviewed.
- Settings: missing settings docs, occupancy doc fallback, and save errors reviewed.
- Member App: missing `defaultGymId`, missing `linkedMemberId`, missing member doc, own attendance, own receipts, and QR/access fallback states reviewed.

## Common Friendly Error Messages

- `You do not have permission to access this data. Your account may be inactive or not linked to this gym. Please contact the gym owner/admin.`
- `This data needs a Firestore index before it can load.`
- `Firestore is unavailable right now. Please try again.`
- `Network error. Check your connection and try again.`
- `No current gym is selected for this account.`
- `No pending invite was found for this email. Ask the gym owner/admin to send an invite first.`
- `This invite has expired. Ask the gym owner/admin to send a new invite.`

## Invite Flow Notes

The current secure client-side invite lookup requires a signed-in Firebase Auth user because Firestore rules intentionally do not allow signed-out invite reads. Local validation failures happen before Auth account creation. Firestore invite lookup failures happen after Auth creation, and the app attempts to delete the newly created Auth user before returning the error.

A Cloud Function invite-claim endpoint would be required to guarantee server-side invite validation before Auth account creation without allowing signed-out invite browsing.

## Manual QA Checklist

1. Sign in as owner and verify dashboard loads.
2. Sign in as admin and verify dashboard loads.
3. Sign in as reception and verify only route-allowed screens are reachable.
4. Sign in as inactive user and verify friendly permission/account messages.
5. Remove `defaultGymId` from a test profile and verify friendly missing-gym states.
6. Open Settings with missing `settings/occupancy` and `settings/app` docs.
7. Save occupancy settings as owner/admin.
8. Open Members with no members and with populated data.
9. Create a member with and without an invite email.
10. Open Member Detail as owner/admin/reception.
11. Open Member Detail as coach and verify read-only behavior.
12. Record a renewal payment as owner/admin/reception.
13. Attempt payment with missing member/plan and verify SnackBars.
14. Check in a valid active paid/partial member.
15. Attempt duplicate check-in and verify a safe message.
16. Attempt checkout when no active session exists and verify a safe message.
17. Attempt check-in with expired/unpaid subscription and blocked access identifiers.
18. Open Staff Management as owner/admin.
19. Attempt admin-to-admin invite and verify it is blocked.
20. Claim a valid staff invite.
21. Claim a valid member invite.
22. Try invite signup with no invite, expired invite, missing index, or permission-denied and verify clear messaging.
23. Open Member App with missing `linkedMemberId`.
24. Open Member App for a missing member document.
25. Verify QR card displays when a stored access identifier exists and shows a fallback when missing.

## Required Firestore Indexes

Confirm these collection group indexes exist:

- `staffInvites`: `emailNormalized` ascending, `status` ascending
- `memberInvites`: `emailNormalized` ascending, `status` ascending

Potential indexes if Firestore prompts:

- `gyms/{gymId}/attendanceSessions`: `memberId` ascending, `status` ascending
- `gyms/{gymId}/subscriptions`: `memberId` ascending, `status` ascending

## Remaining Warnings or Known Issues

- Existing analyzer warnings remain for unrelated deprecated `withOpacity` usage and unused imports/locals outside this Phase 2W QA patch.
- Client-side invite lookup cannot validate invites before Auth creation under the current no-signed-out-invite-read rules. Cleanup is attempted after lookup/claim failure.
- Firebase Emulator Suite/rules tests were not run in this pass.
