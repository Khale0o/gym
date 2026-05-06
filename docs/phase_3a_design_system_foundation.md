# Phase 3A Design System Foundation

## What changed

Phase 3A adds a centralized UI/UX foundation for the Flutter app without changing product behavior or screen flows. The work focuses on reusable design tokens, global theme defaults, and the existing shared primitives that upcoming UI polish phases can build on safely.

## Files changed

- `lib/core/theme.dart`
- `lib/widgets/apex_badge.dart`
- `lib/widgets/apex_card.dart`
- `lib/widgets/apex_text.dart`
- `docs/phase_3a_design_system_foundation.md`

## Design tokens added

`lib/core/theme.dart` now defines structured design-system classes:

- `ApexColors`
- `ApexSpacing`
- `ApexRadius`
- `ApexShadows`
- `ApexTextStyles`
- `ApexDecorations`
- `ApexIcons`

## Color token summary

The palette keeps gold as the brand accent while moving the app toward a softer, production-grade dark theme:

- Background and surfaces: `background`, `surface`, `surfaceAlt`, `card`, `border`
- Brand colors: `primary`, `primaryLight`, `primaryDark`, `secondary`, `accent`
- Semantic colors: `success`, `warning`, `error`, `info`
- Text colors: `textPrimary`, `textSecondary`, `textMuted`, `textDisabled`

## Typography token summary

Reusable hierarchy tokens were added for:

- `display`
- `pageTitle`
- `sectionTitle`
- `cardTitle`
- `body`
- `bodySmall`
- `caption`
- `label`
- `button`

The typography keeps the existing DM Sans base and Cinzel for higher-level brand headings, while improving readability through stronger text contrast.

## Spacing, radius, and shadow helpers

Reusable layout primitives were added for standard page padding, card padding, compact padding, form field gaps, empty-state padding, common radii, card shadows, and brand glow treatment.

Decoration helpers were added for:

- standard cards
- badges
- input borders

## ThemeData updates

The global `apexTheme` now applies design-system defaults for:

- scaffold background
- color scheme
- text theme
- app bars
- cards
- input decorations
- elevated, filled, outlined, and text buttons
- chips
- dividers
- snack bars
- dialogs
- bottom sheets
- progress indicators
- tabs

These are foundation-level defaults only and do not redesign individual screens.

## Shared widgets updated

`ApexCard` now uses `ApexDecorations.card`.

`ApexBadge` now uses `ApexDecorations.badge`.

`ApexText` now defaults to `ApexColors.textSecondary`.

## Backwards-compatible aliases kept

Existing constants were preserved as aliases so current screens keep compiling and behavior remains stable:

- `gold`, `goldLight`, `goldDark`
- `bgDark`, `cardDark`, `card2Dark`, `borderDark`
- `redAlert`, `greenSuccess`, `blueInfo`, `orangeWarning`
- `gymCapacity`
- `ocColor`
- `ocLabel`

## What was intentionally not changed

Phase 3A did not change business logic, Firebase logic, authentication, roles, permissions, routes, repositories, models, providers, payments, check-in, invites, subscriptions, dashboard calculations, finance calculations, settings logic, Firestore rules, or screen-level workflows.

No broad screen redesign or mass widget refactor was done. Existing magic colors across individual screens were intentionally left for later targeted polish phases.

## Validation result

`dart format` was attempted twice during Phase 3A cleanup and timed out both times, so formatting was skipped as requested.

`flutter analyze` was run directly. The first run found three compile errors in `lib/core/theme.dart` caused by SDK theme type names. These were fixed by using `CardThemeData`, `DialogThemeData`, and `TabBarThemeData`.

The follow-up `flutter analyze` run completed with no errors. It still reports existing warnings and infos outside the Phase 3A files, primarily deprecated `withOpacity` usage and two warnings in `lib/widgets/line_chart_widget.dart`. Those were intentionally not changed because they are unrelated to Phase 3A.

## How this prepares Phase 3B

Phase 3B can now polish screens incrementally by replacing local styling with shared tokens, using consistent spacing and card treatments, and leaning on global component themes. The app has a safer visual foundation while keeping all existing production logic intact.
