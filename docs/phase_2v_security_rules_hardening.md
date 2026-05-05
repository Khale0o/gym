# Phase 2V - Security Rules Hardening

## Scope

Phase 2V reviewed Firestore rules and query compatibility for the current implemented Flutter + Firebase gym SaaS flows only. No Phase 2W work, product features, or UI redesign were added.

## Rules Reviewed and Fixed

- Restricted `users/{uid}` reads to the signed-in user's own profile only.
- Kept client profile creation limited to safe staff/member invite claims.
- Kept all gym data under `gyms/{gymId}` guarded by signed-in auth, active profile status, and matching `defaultGymId`.
- Blocked client updates/deletes to user profiles so users cannot change `role`, `defaultGymId`, or `linkedMemberId`.
- Tightened staff invite creation so owners may invite `admin`, `reception`, or `coach`, while admins may invite only `reception` or `coach`.
- Tightened invite cancellation updates to status-only cancellation fields.
- Kept member invite creation fixed to `role == member`.
- Added guarded `settings/receiptCounter` access for owner/admin/reception payment flows.
- Allowed reception to create count-only occupancy docs when check-in/check-out creates the document for the first time.

## Role Access Matrix

| Path | Owner | Admin | Reception | Coach | Member |
| --- | --- | --- | --- | --- | --- |
| `users/{uid}` | Own read only | Own read only | Own read only | Own read only | Own read only |
| `gyms/{gymId}` | Read/update | Read/update | Read | Read | Read |
| `members` | Read/write | Read/write | Read/write | Read | Own read |
| `staff` | Read/write | Read/write | Own read | Own read | No |
| `staffInvites` | Read/create/cancel allowed roles | Read/create/cancel reception/coach | No | No | Claim only if invited email |
| `memberInvites` | Read/create/cancel | Read/create/cancel | Read/create/cancel | No | Claim only if invited email |
| `plans` | Read/write | Read/write | Read | Read | Read |
| `subscriptions` | Read/write | Read/write | Read/write | No | Own read |
| `transactions` | Read/write | Read/write | Read/create | No | Own read |
| `checkins` | Read/create | Read/create | Read/create | Read | Own read |
| `attendanceSessions` | Read/write | Read/write | Read/write | Read | Own read |
| `settings/occupancy` | Read/write | Read/write | Read/count update | Read | Read |
| `settings/app` | Read/write | Read/write | Read | Read | Read |
| `settings/receiptCounter` | Read/write | Read/write | Read/write | No | No |

## Invite Claim Security Notes

Staff and member signup creates Firebase Auth first, then performs signed-in invite lookup and claim. Collection group lookup is allowed only for pending invites whose `emailNormalized` equals `request.auth.token.email`.

Staff invite claims:

- Cannot create owner users.
- Role must be one of `admin`, `reception`, or `coach`.
- Role must match the pending invite.
- Claim update can only move a matching pending invite to `claimed`.
- `claimedByUid` must match the signed-in user.

Member invite claims:

- Role is fixed to `member`.
- Invite must be pending and email-matched.
- The invite `memberId` must match `users/{uid}.linkedMemberId`.
- Member linking is limited to the first auth link fields.

Implication: invite lookup requires the new Auth account to exist before lookup. The rules intentionally do not allow broad signed-out invite reads. A Cloud Function claim endpoint would be the safer long-term approach if pre-auth invite discovery is required.

## Protected Collection Paths

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
- `gyms/{gymId}/attendanceSessions/{sessionId}`
- `gyms/{gymId}/settings/occupancy`
- `gyms/{gymId}/settings/app`
- `gyms/{gymId}/settings/receiptCounter`

Unknown paths remain denied by default.

## Delete and Audit Policy

Client deletes remain blocked for audit-sensitive collections:

- `transactions`
- `subscriptions`
- `checkins`
- `attendanceSessions`
- `staffInvites`
- `memberInvites`
- `members`
- `staff`
- `plans`
- `settings`

Operational changes should use status updates, cancellation, or deactivation instead of deletion.

## Query and Index Notes

- Member app reads the linked member document directly by `linkedMemberId`, which is compatible with own-member rules.
- Member attendance, transaction, and subscription streams are filtered by `memberId`.
- Coach member detail no longer starts billing-history streams because the rules do not grant coach access to transaction/subscription history.
- Staff and member invite signup use collection group queries on `emailNormalized` and `status`.
- Required collection group indexes:
  - `staffInvites`: `emailNormalized` ascending, `status` ascending
  - `memberInvites`: `emailNormalized` ascending, `status` ascending

## Flows Reviewed

- Owner/admin dashboard reads gym-scoped members, subscriptions, transactions, check-ins, and occupancy.
- Settings reads/writes gym profile, occupancy settings, and app payment settings.
- Plans read/create/update remains owner/admin write only.
- Members list/detail/add/edit remains owner/admin/reception write, coach read.
- Staff invites remain owner/admin only with admin-to-admin invite blocked.
- Payments and renewals remain owner/admin/reception, including receipt counter writes.
- Check-in/check-out remains owner/admin/reception and updates occupancy/session/member data.
- Member app reads own member profile, own attendance sessions, own receipts, and own subscription-compatible member summary data.

## Emulator, Tests, and Deploy Status

Firestore emulator/rules tests were not added in this phase. Run them before production deployment if the Firebase Emulator Suite is available.

Deploy command:

```bash
firebase deploy --only firestore:rules
```
