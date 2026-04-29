# Phase 2D Member Invites

## What changed

- Add Member still creates `gyms/{gymId}/members/{memberId}`.
- If a valid email is provided, the app creates a pending invite at
  `gyms/{gymId}/memberInvites/{inviteId}`.
- The existing invite signup form can now claim either a staff invite or a
  member invite.
- Member invite claim creates Firebase Auth, creates `users/{uid}`, links the
  existing member document, marks the invite claimed, signs out, and asks the
  user to sign in.

## Firestore paths

- Members: `gyms/{gymId}/members/{memberId}`
- Member invites: `gyms/{gymId}/memberInvites/{inviteId}`
- User profiles: `users/{uid}`

## Member invite fields

Expected invite shape:

- `gymId`
- `memberId`
- `email`
- `emailNormalized`
- `fullName`
- `phone`
- `role = "member"`
- `status = "pending"`
- `createdBy`
- `createdAt`
- `updatedAt`
- `expiresAt`
- `claimedAt`
- `claimedByUid`

## Signup resolution

The signup flow checks valid pending staff invites first, then member invites.
If both a staff invite and a member invite exist for the same email, signup
stops and no Firebase Auth user is created. Role always comes from the invite.

Member signup can only create `role = "member"`.

## Claim transaction

For member invites, the transaction:

1. Creates `users/{uid}` with `role = "member"`, `defaultGymId`, and
   `linkedMemberId`.
2. Updates `gyms/{gymId}/members/{memberId}` with `authUid`, `emailNormalized`,
   `accountStatus = "active"`, and `updatedAt`.
3. Updates `gyms/{gymId}/memberInvites/{inviteId}` to `status = "claimed"`.

If Auth creation succeeds but the claim fails, the app attempts to delete the
new Auth user, signs out, and shows a cleanup/support error if deletion fails.

## Duplicate prevention

Before creating a member invite, the app checks:

- no pending member invite exists for the same normalized email in the gym
- no linked member in the gym already uses the same normalized email

Duplicate pending invites are not created.

## Firestore index

Firestore may require a collection group index for:

- collection group: `memberInvites`
- fields: `emailNormalized`, `status`

Create the index from the Firebase Console prompt if needed.

## Manual tests

1. Add a member with `member@test.com`.
2. Verify `gyms/gym_001/members/{memberId}` exists.
3. Verify `gyms/gym_001/memberInvites/{inviteId}` exists with
   `emailNormalized = member@test.com` and `status = pending`.
4. Sign out and use "Have an invite? Create account" with `member@test.com`.
5. Verify Firebase Auth user exists.
6. Verify `users/{uid}.role = member`.
7. Verify `users/{uid}.defaultGymId = gym_001`.
8. Verify `users/{uid}.linkedMemberId = memberId`.
9. Verify `gyms/gym_001/members/{memberId}.authUid = uid`.
10. Verify invite status is `claimed`.
11. Sign in as the member and verify only member app access is available.

## Known limitations

- Email delivery is not implemented.
- Member app data is not fully migrated in this phase.
- NFC uniqueness and active session behavior are not part of this phase.
