# Phase 2C Staff Invites

## What changed

Phase 2C adds a gym-scoped Staff Management foundation:

- owners and admins can open Staff Management from the sidebar
- linked staff are streamed from `gyms/{gymId}/staff`
- pending staff invites are streamed from `gyms/{gymId}/staffInvites`
- owners/admins can create pending staff invites
- owners/admins can cancel pending invites they are allowed to manage

This phase does not create Firebase Auth users, does not create `users/{uid}`,
and does not claim invites.

## Firestore paths

- linked staff: `gyms/{gymId}/staff/{staffId}`
- staff invites: `gyms/{gymId}/staffInvites/{inviteId}`

No top-level staff or invite collections are written by this phase.

## Role permissions

Staff Management route access:

- allowed: active `owner`, active `admin`
- hidden/blocked: `reception`, `coach`, `member`, inactive users, unknown roles

Invite permissions:

- `owner` can invite `admin`, `reception`, `coach`
- `admin` can invite `reception`, `coach`
- nobody can invite `owner`
- `admin` cannot invite `admin`

Cancel permissions match invite permissions. Only `pending` invites can be
cancelled, and cancellation updates `status` to `cancelled` instead of deleting
the document.

## Why invites instead of Firebase Auth users

Flutter clients must not hold Firebase Admin credentials and should not create
arbitrary Auth users or assign roles directly. Phase 2C therefore creates only a
gym-scoped pending invite. In Phase 2C.2, the invited person will sign up using
the same normalized email and then claim the matching invite through a secure
flow.

## Duplicate prevention

Before creating an invite, the app checks:

- whether the normalized email already exists in `gyms/{gymId}/staff`
- whether the normalized email already has a `pending` invite in
  `gyms/{gymId}/staffInvites`

If either exists, no new invite is created.

## Manual testing

1. Confirm the signed-in user's `users/{uid}.defaultGymId` is `gym_001`.
2. Set the signed-in user's `status` to `active`.
3. As `owner`, verify Staff appears in the sidebar and invite roles are
   `admin`, `reception`, and `coach`.
4. As `admin`, verify Staff appears in the sidebar and invite roles are
   `reception` and `coach`.
5. As `reception`, `coach`, or `member`, verify Staff is hidden and `/staff`
   redirects to the first allowed route.
6. Create an invite and verify a document appears under
   `gyms/gym_001/staffInvites`.
7. Try inviting the same email again while pending and verify the duplicate
   error.
8. Cancel a pending invite and verify its status changes to `cancelled`.

## Known limitations

- Invite claiming is not implemented yet.
- Firebase Auth users are not created by this phase.
- Linked staff profiles are displayed if they already exist, but this phase does
  not create `gyms/{gymId}/staff` documents.
- No email delivery is implemented yet; the invite document is the foundation
  for a later secure signup/claim flow.
