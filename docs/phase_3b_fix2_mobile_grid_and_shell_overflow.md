# Phase 3B-Fix2 Mobile Grid and Shell Overflow

## What was fixed

Phase 3B-Fix2 addresses the remaining responsive layout issues in the dashboard KPI area and admin shell header/sidebar area.

The admin shell header is now more resilient on tight sidebar widths, and the dashboard KPI cards use a compact two-column mobile grid for normal phone widths without clipping.

## What caused the remaining overflow

The admin shell header still had a tight horizontal row with logo, brand text, role text, and two default `IconButton` controls. Default icon button sizing can consume more width than the sidebar header can safely provide, especially around collapsed/expanded transitions and narrow web widths.

The dashboard mobile KPI layout had been changed to a vertical list to avoid overflow, which solved clipping but made the page too long. A safe two-column mobile grid needed more compact card internals and a less fragile metadata row.

## Admin shell changes

- Replaced default header icon buttons with compact fixed-size shell header buttons.
- Kept collapsed sidebar header minimal with a centered expand action.
- Made expanded branding use flexible/ellipsis behavior.
- Hid the lower-priority role text when the header width is too tight.
- Preserved logo, logout, collapse/expand actions, sidebar behavior, routes, and permissions.

## Dashboard mobile KPI layout changes

- Restored mobile KPI cards to a two-column grid for normal phone widths.
- Kept a one-column fallback only for extremely narrow content widths.
- Added compact KPI card sizing for mobile.
- Reduced mobile card padding, icon size, typography size, and spacing.
- Kept the badge/detail metadata in a safe `Wrap`.
- Kept the arrow affordance and all KPI tap/drill-down behavior intact.

## Viewport intent

- Small mobile: falls back to one column only if two columns would be unsafe.
- Normal mobile around `390x844`: two KPI cards per row.
- Large mobile around `430x932`: two KPI cards per row.
- Tablet around `768x1024`: keeps the Phase 3B spacious grid.
- Laptop around `1366x768`: keeps the Phase 3B spacious grid and polished shell.
- Desktop around `1440x900`: keeps the Phase 3B spacious grid and polished shell.

## What was intentionally not changed

No business logic, Firebase logic, repositories, providers, models, routes, permissions, calculations, Firestore rules, KPI actions, dialogs, bottom sheets, navigation destinations, dashboard data sources, member logic, payment logic, subscription logic, check-in logic, settings logic, or auth logic were changed.

This phase only changed responsive layout behavior in:

- `lib/navigation/admin_shell.dart`
- `lib/screens/dashboard/dashboard_screen.dart`

## Flutter analyze result

`flutter analyze` was run after the Phase 3B-Fix2 changes. It completed with no new compile errors related to this phase.

The analyzer still reports existing unrelated warnings and infos outside this fix scope, mostly deprecated `withOpacity` usage and existing `line_chart_widget.dart` warnings. Those were intentionally not changed.

`dart format` was not run during this fix pass.
