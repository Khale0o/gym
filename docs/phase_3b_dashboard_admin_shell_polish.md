# Phase 3B Dashboard and Admin Shell Polish

## Files changed

- `lib/models/dashboard_summary.dart`
- `lib/repositories/dashboard_repository.dart`
- `lib/navigation/admin_shell.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `docs/phase_3b_dashboard_admin_shell_polish.md`

## What UI/UX improved

The dashboard now uses the Phase 3A design tokens for a calmer, more spacious layout. The page has a clearer heading area, a dedicated KPI group, and an operations group for occupancy, recent payments, and recent check-ins.

The KPI grid is less crowded on laptop and desktop screens. Cards have more breathing room, stronger typography, clearer icons, and a simpler detail affordance.

Recent payments, recent check-ins, empty states, loading states, and occupancy cards were polished to reduce low-contrast text and visual clutter.

The admin shell sidebar now has a more stable desktop width, clearer active navigation state, better spacing, section hierarchy, consistent icon treatment, and a quieter dark surface.

## Dashboard card interactions

Each KPI card is now an actionable entry point:

- Total Members: opens a large detail view with member counts and the member list, plus a Members navigation action.
- Active Members: opens a filtered active-member detail list, plus a Members navigation action.
- Active Subscriptions: opens subscription breakdown metrics and active subscription records.
- Expired Subscriptions: opens expired subscription records and affected members.
- Expiring Soon: opens expiring subscription records and a Payments/Renew navigation action.
- Today Check-ins: opens today’s check-in records.
- Today Revenue: opens today’s paid/partial transaction records.
- Month Revenue: opens current-month paid/partial transaction records.
- Occupancy: opens occupancy metrics and active attendance sessions when available.

On desktop and laptop widths, KPI details open in a large centered dialog. On smaller screens, they open in a large draggable bottom sheet.

## How clutter was reduced

The outer dashboard now favors concise summaries and larger spacing. Detailed records moved behind KPI interactions instead of crowding the first view. Supporting copy is short, low-priority text uses readable contrast, and decorative highlights were reduced.

## Laptop and desktop priority

The dashboard content is constrained to a comfortable maximum width and centered on wide screens. Desktop spacing is larger, the KPI grid uses fewer columns with more readable card sizing, and the admin sidebar uses clearer active states and more stable proportions.

## Logic and data behavior preserved

No Firebase queries, auth behavior, routes, permissions, Firestore rules, payment calculations, finance calculations, check-in logic, settings logic, invites, subscriptions, or member business workflows were changed.

The dashboard repository already loaded members and subscriptions for existing summary calculations. Phase 3B only carries those already-loaded records into `DashboardSummary` so the dashboard can show richer drill-down lists.

Role-based navigation visibility remains controlled by the existing `canAccessRoute` logic.

## Validation result

`dart format` was not run for Phase 3B because it previously hung and the request explicitly said not to run it if it hangs.

`flutter analyze` was run after changes. The first run found one Phase 3B compile issue in `lib/screens/dashboard/dashboard_screen.dart`, caused by a const widget tree wrapping a non-const constructor. That was fixed.

`flutter analyze` was rerun once and completed with no errors. It still reports existing warnings/infos outside Phase 3B, mostly deprecated `withOpacity` usage in AI/check-in/sparkline files plus existing `line_chart_widget.dart` warnings. Those were intentionally not changed.

## Manual test checklist

- Open the dashboard on laptop/desktop width and verify the header, KPI group, and operations group have comfortable spacing.
- Click every KPI card and verify each opens a useful detail view with records or breakdown data.
- Verify Total Members and Active Members show member lists.
- Verify subscription KPI cards show subscription records.
- Verify revenue KPI cards show transaction records.
- Verify Today Check-ins shows today attendance records.
- Verify Occupancy shows active sessions when available.
- Resize to tablet/mobile and verify KPI detail views become bottom sheets without overflow.
- Confirm sidebar active state is clear on desktop.
- Confirm route visibility still matches the signed-in user role.
