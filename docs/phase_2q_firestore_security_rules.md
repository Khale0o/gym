# Phase 2Q - Firestore Security Rules Foundation

## What Changed

Phase 2Q adds a production-oriented Firestore rules foundation for the gym-scoped SaaS data model.

Changed:

- Created `firestore.rules`
- Added the Firestore rules file to `firebase.json`

No Flutter UI, Dart logic, Firebase structure, or Firestore collections were changed.

## Core Access Rule

Gym data access requires:

- signed-in Firebase Auth user
- `users/{uid}.status == "active"`
- `users/{uid}.defaultGymId == gymId`

The rules define helpers for role and gym checks, including:

- `signedIn()`
- `userProfile()`
- `userRole()`
- `userStatus()`
- `isActiveUser()`
- `userGymId()`
- `isGymUser(gymId)`
- `isOwner()`
- `isAdmin()`
- `isReception()`
- `isCoach()`
- `isMember()`
- `isOwnerOrAdmin()`
- `isOwnerAdminReception()`
- `isStaffRole()`
- `isLinkedMember(gymId, memberId)`

## Role Access Matrix

| Path | Owner | Admin | Reception | Coach | Member |
| --- | --- | --- | --- | --- | --- |
| `users/{uid}` self | Read | Read | Read | Read | Read |
| same-gym users | Read | Read | No | No | No |
| `gyms/{gymId}` | Read/update | Read/update | Read | Read | Read |
| members | Read/write | Read/write | Read/write | Read | Own read |
| staff | Read/write | Read/write | Own read | Own read | No |
| staff invites | Read/write | Read/write | No | No | No |
| member invites | Read/write | Read/write | Read/write | No | Claim only |
| plans | Read/write | Read/write | Read | Read | Read |
| subscriptions | Read/write | Read/write | Read/write | No | Own read |
| transactions | Read/write | Read/write | Read/create | No | Own read |
| check-ins | Read/create | Read/create | Read/create | Read | Own read |
| occupancy settings | Read/write | Read/write | Read/count update | Read | Read |
| app settings | Read/write | Read/write | Read | Read | Read |

Deletes are blocked for members, staff, invites, plans, subscriptions, transactions, check-ins, and settings. Prefer status changes/deactivation over destructive deletes.

## Supported Paths

- `users/{uid}`
- `gyms/{gymId}`
- `gyms/{gymId}/members/{memberId}`
- `gyms/{gymId}/staff/{staffId}`
- `gyms/{gymId}/staffInvites/{inviteId}`
- `gyms/{gymId}/memberInvites/{inviteId}`
- `gyms/{gymId}/plans/{planId}`
- `gyms/{gymId}/subscriptions/{subscriptionId}`
- `gyms/{gymId}/transactions/{transactionId}`
- `gyms/{gymId}/checkins/{checkinId}`
- `gyms/{gymId}/settings/occupancy`
- `gyms/{gymId}/settings/app`

Unknown paths are denied.

## What Is Protected

- Cross-gym reads and writes are blocked by `defaultGymId`.
- Inactive user profiles cannot access gym data.
- Members can only read their linked member data, subscriptions, transactions, and check-ins.
- Coaches can read member/check-in context but cannot write member, subscription, transaction, or invite data.
- Client deletes are blocked for audit-sensitive data.
- Check-in logs are immutable from the client after creation.
- Transactions can be created by owner/admin/reception and corrected by owner/admin only.

## Invite Claiming Limitation

The current app claims staff and member invites from Flutter. To avoid breaking that flow, the rules include temporary client-side invite-claim allowances:

- signed-in invited users may read pending invite docs matching `request.auth.token.email`
- self-created `users/{uid}` profiles are allowed only with restricted fields
- self-created invite users cannot choose `owner`
- self-created invite users must set `status` to `active`
- invite claim updates may only move `pending` to `claimed`
- `claimedByUid` must equal `request.auth.uid`
- invite `role`, `gymId`, and `emailNormalized` must not change

For member invite claims, the current client transaction also links the member document to the new auth user. The rules allow only a narrow first-link update to `authUid`, `email`, `emailNormalized`, `accountStatus`, and `updatedAt`.

For staff invite claims, the rules allow a narrow self-create of `gyms/{gymId}/staff/{uid}` for invited staff roles.

This is still weaker than a server-side claim. A Cloud Function should eventually own invite validation, profile creation, staff/member linking, and invite claiming atomically with Admin SDK privileges.

## Known Limitations

- Rules cannot lowercase `request.auth.token.email`, so invite claim reads expect Firebase Auth email casing to match stored normalized email. The app already normalizes emails before writing invites.
- Rules do not validate every field schema for every owner/admin write. They establish role/gym boundaries first.
- Owner/admin bootstrap still needs a trusted admin path, seed script, console setup, or Cloud Function because clients cannot freely create owner profiles.
- Collection group invite lookup is allowed only for matching pending invites and requires the existing Firestore indexes used by the app.

## Manual Emulator / Console Test Checklist

1. Signed-out user cannot read `users/{uid}` or any `gyms/{gymId}` data.
2. Active owner can read/update own gym and manage members, staff, invites, plans, subscriptions, and transactions.
3. Active admin has owner-like management except owner bootstrap/deletes.
4. Reception can create/update members, member invites, subscriptions, transactions, and check-ins, but cannot manage staff/plans/app settings.
5. Coach can read members and check-ins, but cannot write members, payments, plans, or settings.
6. Member can read only their linked member document.
7. Member can read only their own subscriptions, transactions, and check-ins.
8. User with `status != active` cannot read gym data.
9. User with another `defaultGymId` cannot read or write this gym.
10. Client delete attempts fail for members, staff, plans, subscriptions, transactions, check-ins, and settings.
11. Staff invite claim can create `users/{uid}`, create own staff doc, and mark only matching pending invite as claimed.
12. Member invite claim can create `users/{uid}`, link only the first unlinked member account, and mark only matching pending invite as claimed.
13. Invite claim fails if trying to change `role`, `gymId`, `emailNormalized`, or `claimedByUid`.
14. Occupancy count update works for owner/admin/reception.
15. Reception cannot update app settings.

## Deployment Notes

Deploy rules with:

```bash
firebase deploy --only firestore:rules
```

Test in the Firebase Emulator Suite before production deployment, especially the invite claim transactions.
