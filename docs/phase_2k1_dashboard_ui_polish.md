# Phase 2K.1 - Dashboard UI Polish

## What changed

This pass improves Dashboard usability without changing Firestore sources or KPI calculation rules from Phase 2K.

Changes include:

- improved mobile KPI card layout and spacing
- clearer KPI labels and helper text
- tappable KPI cards with ripple feedback
- detail bottom sheets for every KPI
- safer chip wrapping to reduce clipping on narrow screens
- preserved dark luxury / gold visual style

## Files touched

- `lib/models/dashboard_summary.dart`
- `lib/repositories/dashboard_repository.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `docs/phase_2k1_dashboard_ui_polish.md`

The model/repository changes only expose already-computed, already-read dashboard detail rows for UI sheets. They do not change data sources, write behavior, or KPI rules.

## Interaction behavior

Each KPI card is tappable. Tapping opens a modal bottom sheet with details for that metric. Cards show a subtle arrow and “Tap for details” helper text.

No KPI card writes data. Some sheets include navigation buttons:

- Total Members: `View Members`
- Expiring Soon: `Open Payments / Renew`

## KPI detail sheets

- Total Members: total, active, inactive, and a View Members button.
- Active Subscriptions: active, partial, expiring soon, expired.
- Expiring Soon: expiring subscriptions list with member name, plan, end date, and payment status.
- Today Check-ins: today count and recent check-ins today.
- Today Revenue: today amount and recent paid/partial transactions today.
- Month Revenue: current month amount, transaction count, and recent month transactions.
- Expired Subscriptions: expired count and recent expired subscription list.
- Current Occupancy: count, capacity, usage percentage, status label, and recent check-ins.

## Manual tests

1. Open Dashboard on a mobile-sized layout around 412x915.
2. Confirm KPI cards remain in a clean 2-column grid.
3. Confirm labels and helper text are readable.
4. Confirm chips/pills wrap cleanly and do not clip.
5. Tap each KPI card and confirm the correct bottom sheet opens.
6. Confirm empty sheets show friendly empty states.
7. Confirm `View Members` opens Members.
8. Confirm `Open Payments / Renew` opens Payments.
9. Confirm no RenderFlex overflow appears.
10. Confirm dashboard values still match Phase 2K data.
11. Confirm unrelated screens and flows still behave as before.

## Notes

This is UI/UX only. It does not change auth, routing permissions, payments logic, subscription logic, check-in validation, or Firestore write behavior.
