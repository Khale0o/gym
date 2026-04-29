# Phase 2C.2 Sign Up and Claim Staff Invite

## What changed

The login screen now includes a staff invite signup mode:

- "Have an invite? Create account"
- validates full name, email, password, and confirm password
- looks up a pending staff invite for the normalized email
- creates a Firebase Auth account only after a valid invite is found
- claims the invite in a Firestore transaction

This phase does not create owner accounts, member accounts, POS, payments,
subscriptions, email delivery, or Cloud Functions.

## Invite lookup

The invited user does not have `users/{uid}.defaultGymId` yet, so signup uses a
collection group query:

`collectionGroup('staffInvites')`

Filters:

- `emailNormalized == normalizedEmail`
- `status == "pending"`

The app then validates:

- invite email still matches
- role is `admin`, `reception`, or `coach`
- `gymId` exists
- `expiresAt` is missing or in the future

If no valid invite exists, signup shows:

`No pending staff invite found for this email. Ask your gym owner/admin to invite you first.`

If multiple valid pending invites exist for the same email across gyms, signup
stops and asks the user to contact the gym owner.

## Firestore writes

After Firebase Auth account creation, the claim transaction writes:

### `users/{uid}`

- `displayName`
- `email`
- `phone`
- `role` from invite only
- `status = "active"`
- `defaultGymId` from invite only
- `createdAt`
- `updatedAt`
- `inviteId`
- `createdFromInvite = true`

### `gyms/{gymId}/staff/{uid}`

- `authUid = uid`
- `gymId`
- `fullName`
- `name`
- `email`
- `emailNormalized`
- `phone`
- `role` from invite only
- `status = "active"`
- `notes`
- `inviteId`
- `createdAt`
- `updatedAt`
- `createdBy`
- `onDuty = false`
- `permissions = []`

### `gyms/{gymId}/staffInvites/{inviteId}`

- `status = "claimed"`
- `claimedAt`
- `claimedByUid = uid`
- `updatedAt`

The transaction aborts if the invite is no longer pending or if `users/{uid}`
already exists.

## Role security

The signup form does not contain role selection. The role always comes from the
pending invite document. Supported staff signup roles are:

- `admin`
- `reception`
- `coach`

`owner` cannot be created through staff invite signup.

## Required Firestore index

This phase uses a collection group query on `staffInvites` with:

- `emailNormalized` equality
- `status` equality

Firestore may prompt for a collection group composite index for
`staffInvites(emailNormalized, status)`. Create the index from the Firebase
Console link if the query returns a missing-index error.

## Auth cleanup limitation

If the Firestore claim fails after Firebase Auth account creation, the app signs
out the user and attempts `createdUser.delete()`. Because this is client-side
Firebase Auth, deletion can fail in some edge cases. If that happens, the app
shows a clear support/cleanup message. A future Cloud Function can make this
cleanup fully authoritative.

## Manual tests

### Coach invite

1. Owner/admin creates invite for `coach@test.com`.
2. Sign out.
3. Open "Have an invite? Create account".
4. Sign up with `coach@test.com`.
5. Verify Firebase Auth user exists.
6. Verify `users/{uid}.role = coach`.
7. Verify `users/{uid}.defaultGymId = gym_001`.
8. Verify `gyms/gym_001/staff/{uid}.authUid = uid`.
9. Verify invite status is `claimed`.
10. Verify only coach routes appear.

### No invite

1. Try signup with a random email.
2. Verify the no-invite error.
3. Verify no `users/{uid}` profile is created.

### Duplicate or claimed invite

1. Try signup again with an already claimed invite email.
2. Verify signup fails with a clear error.

### Reception guard

1. Invite a reception user.
2. Sign up from invite.
3. Verify only reception routes appear.
