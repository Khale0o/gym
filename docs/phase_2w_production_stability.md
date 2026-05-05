# Phase 2W - Production Stability Sweep

## Scope

Phase 2W focused on production stability and Firestore rules compatibility after Phase 2V hardening. No new product features, redesigns, or Phase 2X work were added.

## What Was Checked

- Owner/admin dashboard data reads.
- Settings reads/writes for gym profile, occupancy, and app settings.
- Plans read/create/default seeding.
- Members list/detail/add/edit for owner/admin/reception.
- Coach member read-only access.
- Staff management and staff invites for owner/admin.
- Payments and renewals for owner/admin/reception.
- Check-in/check-out occupancy/session/member writes.
- Member app own profile, attendance, receipts, and QR card reads.
- Staff and member invite signup/claim collection group lookups.
- Older providers that still referenced pre-gym-scoped top-level collections.

Reception dashboard was reviewed as not route-allowed by the current role routing.

## What Was Fixed

- Switched legacy `membersProvider` from top-level `members` to `gyms/{gymId}/members`.
- Switched ERP providers from top-level `plans`, `transactions`, and `staff` to gym-scoped collections.
- Changed `currentLinkedMemberProvider` to read the linked member document by `linkedMemberId` instead of querying by `authUid`, which is compatible with member-only document rules.
- Updated the legacy `updateOccupancy` helper to require `gymId` and write `gyms/{gymId}/settings/occupancy`.
- Updated the debug-only seed helper to write demo data under `gyms/{gymId}`.
- Allowed owner/admin occupancy settings updates to include the existing `maxCapacity` and `updatedBy` fields.
- Added a shared friendly Firestore error formatter for permission, index, network, and missing-gym failures.
- Replaced raw Firestore errors in members, member detail, payments, plans, staff management, and settings surfaces.
- Added guarded plan save error handling so plan creation failures show a SnackBar instead of escaping the dialog.

## Firestore Rules and Query Compatibility

- Rules were changed narrowly for `gyms/{gymId}/settings/occupancy` update compatibility.
- No signed-out reads were added.
- No cross-gym reads were added.
- Member access remains restricted to the profile's own `linkedMemberId`.
- Coach access remains read-only for members/attendance and does not include billing history.
- Existing invite lookup remains signed-in and email-matched through collection group queries.

## Missing Field Protections

- Gym plan parsing now tolerates missing/null `membersCount`, `name`, and numeric `price`.
- Existing settings models already default missing gym profile, occupancy, and app settings fields.
- Existing member app fallbacks continue to handle missing `currentPlanName`, `subscriptionEndDate`, `paymentStatus`, `accessStatus`, `linkedMemberId`, and QR/access identifiers.
- Receipt counter creation remains handled by the payment transaction path and the Phase 2V `settings/receiptCounter` rules.

## Required Firestore Indexes

Single-field ordering/filtering is used for most screens. Confirm these collection group indexes exist for invite signup:

- `staffInvites`: `emailNormalized` ascending, `status` ascending
- `memberInvites`: `emailNormalized` ascending, `status` ascending

Potential composite indexes if Firestore prompts for them:

- `gyms/{gymId}/attendanceSessions`: `memberId` ascending, `status` ascending
- `gyms/{gymId}/subscriptions`: `memberId` ascending, `status` ascending

No extra `orderBy` clauses were added in Phase 2W.

## Intentionally Not Changed

- No notifications.
- No AI changes.
- No PDF receipts.
- No online payment gateway.
- No camera QR scanner.
- No NFC hardware integration.
- No super admin.
- No new member app project.
- No new dashboard cards.
- No broad Firestore rule grants to make incompatible queries pass.
- No Firestore structure changes beyond moving legacy/debug helpers to the existing gym-scoped structure.

## Manual Test Checklist

1. Owner dashboard opens and loads KPIs.
2. Admin dashboard opens and loads KPIs.
3. Reception does not receive dashboard access unless routes are intentionally changed later.
4. Owner/admin settings can save gym profile, occupancy capacity, and app settings.
5. Owner/admin plans can load, create defaults, and add a plan.
6. Owner/admin/reception can list, add, and edit members.
7. Coach can open members and member detail without payment/subscription history writes or billing reads.
8. Owner/admin can manage staff and create/cancel allowed staff invites.
9. Admin cannot invite another admin.
10. Owner/admin/reception can record renewal payments and receive receipt numbers.
11. Owner/admin/reception can check members in and out.
12. Member app opens with only the linked member profile.
13. Member app attendance and receipts show only the member's own data.
14. Member QR card renders from the stored member access identifiers.
15. Staff invite signup/claim succeeds for a pending invite matching the signed-in email.
16. Member invite signup/claim succeeds for a pending invite matching the signed-in email.
17. Inactive users and cross-gym users receive friendly access errors.
