# Phase 2A Firestore Scope Inventory

## Target gym-scoped structure

- `gyms/{gymId}`
- `gyms/{gymId}/members/{memberId}`
- `gyms/{gymId}/staff/{staffId}`
- `gyms/{gymId}/plans/{planId}`
- `gyms/{gymId}/subscriptions/{subscriptionId}`
- `gyms/{gymId}/checkins/{checkinId}`
- `gyms/{gymId}/transactions/{transactionId}`
- `gyms/{gymId}/products/{productId}`
- `gyms/{gymId}/shifts/{shiftId}`
- `gyms/{gymId}/settings/{settingId}`

`GymFirestorePaths` centralizes these paths. `occupancyDoc(gymId)` points to
`gyms/{gymId}/settings/occupancy`.

## Gym selection

The signed-in Firebase Auth user is resolved to `users/{uid}` by
`currentUserProfileProvider`. `currentGymIdProvider` reads
`users/{uid}.defaultGymId`; for the current production seed that value is
`gym_001`, which connects the user profile to `gyms/gym_001`.

## Migrated or prepared in Phase 2A

- `MemberRepository` supports `streamMembers`, `getMember`, `createMember`, and
  `updateMember` using `gyms/{gymId}/members`.
- `StaffRepository` supports `streamStaff`, `getStaff`, `createStaff`, and
  `updateStaff` using `gyms/{gymId}/staff`.
- `gymMembersProvider`, `gymMemberByIdProvider`, `gymStaffProvider`, and
  `gymStaffByIdProvider` use `currentGymIdProvider` and return an error state
  when `users/{uid}.defaultGymId` is missing or empty.
- `Member` and `Staff` now carry production SaaS fields while preserving legacy
  UI fields used by the current screens.
- `RoleCapabilities` and `AppRoles` define future role/capability checks only;
  no routes or screens were changed.

## Still legacy/global after Phase 2A

The current screens remain wired to existing providers so the app keeps its
current behavior while Phase 2A lays the foundation:

- `membersProvider` and `memberByIdProvider`: top-level `members`.
- `plansProvider`: top-level `plans`.
- `transactionsProvider`: top-level `transactions`.
- `staffProvider`: top-level `staff`.
- `recentCheckinsProvider` and `addCheckIn`: top-level `checkins` plus
  `occupancy/current`.
- `occupancyStreamProvider` and `updateOccupancy`: top-level
  `occupancy/current`.
- `seedFirestore`: debug-only manual seed writes top-level demo collections.

These will be migrated screen-by-screen in later phases when the related UI and
KPIs are rebuilt around production records.

## Phase 2B readiness

Add Member can call `memberRepositoryProvider`, resolve the gym from
`currentGymIdProvider`, and write a production member under
`gyms/{gymId}/members` with identity, contact, health, coach assignment, and
audit fields.

## Phase 2C readiness

Staff and role management can call `staffRepositoryProvider` to read/write
`gyms/{gymId}/staff`, then use `RoleCapabilities` for owner/admin/reception/
coach/member capability decisions before building management UI.
