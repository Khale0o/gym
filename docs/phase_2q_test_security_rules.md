# Phase 2Q-Test - Firestore Security Rules Review

## What Was Reviewed

Reviewed `firestore.rules` against the current implemented app flows:

- owner/admin login and dashboard reads
- owner/admin/reception member creation
- staff invite signup and claim from Flutter
- member invite signup and claim from Flutter
- owner/admin plan management
- reception plan read without plan management
- owner/admin/reception payments, renewals, and check-ins
- coach read-only member/check-in access
- linked member self-read access
- settings read/write boundaries
- cross-gym blocking
- inactive-user blocking

## Rules Fixes Made

`firestore.rules` was updated narrowly for compatibility and hardening:

- Added collection-group-compatible invite rules for `staffInvites` and `memberInvites`.
- Required self-created invite user profiles to match a real pending invite.
- Required staff self-doc creation to match a pending staff invite.
- Required member first-link updates to match the pending member invite and resulting `users/{uid}` profile via `getAfter`.
- Kept signed-out Firestore access blocked.

One Flutter compatibility fix was required:

- Invite signup now creates/signs in the Auth user before Firestore invite lookup, because rules cannot safely allow signed-out invite lookup.

## Supported Role Summary

- Owner/admin: same-gym management for core SaaS data.
- Reception: same-gym member, member invite, subscription, transaction, check-in, and occupancy count workflows.
- Coach: same-gym read access for members/check-ins only where intended.
- Member: own linked member profile, subscriptions, transactions, and check-ins only.
- Inactive users: blocked from gym data.
- Cross-gym users: blocked.

Deletes remain blocked for audit-sensitive collections.

## Invite Claim Compatibility

Staff invite claim should allow:

- signed-in invited user reads only matching pending staff invite
- self-create `users/{uid}` with invite role `admin`, `reception`, or `coach`
- no client-created owner profile
- self-create `gyms/{gymId}/staff/{uid}` only for matching pending invite
- update invite from `pending` to `claimed`
- preserve invite `role`, `gymId`, and `emailNormalized`
- require `claimedByUid == request.auth.uid`

Member invite claim should allow:

- signed-in invited user reads only matching pending member invite
- self-create `users/{uid}` with role `member`
- first-link only the invited `gyms/{gymId}/members/{memberId}` doc
- update only `authUid`, `email`, `emailNormalized`, `accountStatus`, and `updatedAt` on the linked member
- update invite from `pending` to `claimed`
- preserve invite `role`, `gymId`, `emailNormalized`, and `memberId`
- require `claimedByUid == request.auth.uid`

## Manual App Test Checklist

1. Sign in as owner/admin and confirm dashboard loads.
2. Owner/admin creates a plan successfully.
3. Reception can view active plans.
4. Reception cannot create/update plans.
5. Owner/admin/reception can add a member.
6. Coach can open Members and Member Detail but cannot write member data.
7. Owner/admin/reception can create a payment or renewal.
8. Owner/admin/reception can check in a valid member.
9. Member account can read only its linked profile.
10. Member account cannot read another member detail route.
11. Member account can read only its own subscriptions, transactions, and check-ins.
12. Staff invite signup succeeds for admin/reception/coach invite.
13. Staff invite signup fails for any attempted owner role.
14. Member invite signup succeeds and links only the invited member.
15. A user from another `defaultGymId` cannot read this gym's data.
16. A user with `status != active` cannot read gym data.
17. Client delete attempts fail for members, staff, subscriptions, transactions, check-ins, settings, and plans.

## Emulator Test Checklist

Run these in Firebase Emulator Suite or staging before production:

1. Query `collectionGroup('staffInvites')` as signed-in invited user with matching pending email.
2. Query `collectionGroup('staffInvites')` as another email and confirm denied.
3. Query `collectionGroup('memberInvites')` as signed-in invited user with matching pending email.
4. Query `collectionGroup('memberInvites')` as another email and confirm denied.
5. Staff invite transaction: create `users/{uid}`, create `staff/{uid}`, update invite claimed.
6. Staff invite transaction fails if role changes to `owner`.
7. Staff invite transaction fails if `claimedByUid` is not auth UID.
8. Member invite transaction: create `users/{uid}`, link invited member, update invite claimed.
9. Member invite transaction fails when linking a different member ID.
10. Member invite transaction fails if `emailNormalized` changes.
11. Owner/admin same-gym reads/writes pass.
12. Reception staff/plan writes fail.
13. Coach payment/subscription/member writes fail.
14. Member cross-member reads fail.
15. Cross-gym reads and writes fail for all roles.

## Deployment

Firebase CLI was not available in this environment, so rules deploy/emulator commands were not run here.

Deploy after emulator or staging validation:

```bash
firebase deploy --only firestore:rules
```

Do not deploy directly to production without testing invite claim transactions in Emulator Suite or a staging Firebase project.

## Remaining Risks

- Client-side invite claiming is still less robust than a Cloud Function with Admin SDK validation.
- Rules cannot lowercase `request.auth.token.email`; invite signup uses normalized lowercase Auth emails to stay compatible.
- Rules validate role/gym boundaries and invite claim shape, but do not fully schema-validate every owner/admin write.
