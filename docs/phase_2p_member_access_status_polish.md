# Phase 2P - Member Access Status Polish

## What Changed

Phase 2P adds shared member access eligibility logic and uses it to improve status visibility in the Members list, Member Detail, and Check-in.

Changes are UI/enforcement polish only. No Firestore structure, collections, auth, invites, plans, payments, dashboard architecture, settings architecture, or AI flows were changed.

## Status Rules

Member access eligibility requires:

- `member.status == active`
- `member.accountStatus` is missing, empty, or `active`
- `member.accessStatus` is missing, empty, or `active`
- effective subscription status allows check-in

Access status handling:

- missing/empty: treated as active
- `active`: allowed
- `disabled`: blocked
- `lost`: blocked
- `replaced`: blocked

Subscription status handling uses the existing effective subscription resolver:

- `active`: allowed
- `expiringSoon`: allowed with warning
- `partial`: allowed with warning
- `expired`: blocked
- `unpaid`: blocked
- `none`: blocked
- `cancelled`: blocked

## Where The Helper Is Used

Shared helper:

- `lib/models/member_access_eligibility.dart`

Used by:

- Members list compact badges
- Member Detail access eligibility panel
- Check-in access credential blocked-message mapping

The Check-in repository also enforces member/account/access blocks before subscription validation.

## UI Updates

Members list now shows compact badges for:

- member status: `Active` / `Inactive`
- access status: `Access Active` / `Disabled` / `Lost` / `Replaced` / `Not Assigned`
- effective subscription status: `Active` / `Expiring Soon` / `Partial` / `Expired` / `Unpaid` / `No Subscription`

Member Detail now shows an access eligibility summary near the top:

- allowed
- allowed with warning
- blocked

## Check-in Blocked Cases

Check-in now surfaces clearer messages for:

- `Member is inactive.`
- `Member account is inactive.`
- `Access credential is disabled.`
- `Access credential was reported lost.`
- `Access credential was replaced.`
- `No active subscription found.`
- `Subscription expired.`
- `Subscription is unpaid.`

Expired or unpaid members are still blocked.

## Dashboard Consistency

Dashboard active member counting already excludes inactive members and account-inactive members:

- `status == active`
- `accountStatus` missing, empty, or `active`

No dashboard code change was needed.

## Known Limitations

- Eligibility display uses member summary fields, so it reflects the current member document summary.
- Check-in still relies on the existing subscription repository flow for final subscription/payment enforcement.
- No new dashboard cards or redesign were added.

## Manual Tests

1. Active member + active subscription + active access => allowed.
2. Member status inactive => blocked in detail/check-in.
3. `accountStatus` inactive => blocked.
4. `accessStatus` disabled => blocked.
5. `accessStatus` lost => blocked.
6. `accessStatus` replaced => blocked.
7. Expired subscription => blocked.
8. Unpaid subscription => blocked.
9. Expiring soon subscription => allowed with warning.
10. Partial payment => allowed with warning.
11. Old member with no `accessStatus` => treated as active access.
12. Dashboard active members count should not include inactive members.
