# Phase 4B: Arabic Egyptian Localization Foundation

## What was added

- Added a central localization helper in `lib/l10n/app_localizations.dart`.
- Added two supported app languages:
  - `en` for English
  - `ar_EG` for Arabic Egyptian
- Added app-level language state in `lib/providers/language_provider.dart`.
- Added app-level locale switching and RTL support in `lib/main.dart`.
- Added a Language section to Settings.
- Localized the highest-impact static labels in the app shell and common page headers.

## Where language preference is stored

The selected language is stored locally on the device with `SharedPreferences` using:

- key: `app_language_code`
- values: `en` or `ar_EG`

The default is English if no local preference exists. The preference is not stored in Firestore.

## How to add new translation keys

1. Add a key constant to `L10nKeys` in `lib/l10n/app_localizations.dart`.
2. Add the English value under `AppLanguage.english`.
3. Add the Egyptian Arabic value under `AppLanguage.arabicEgyptian`.
4. Use it in widgets with:

```dart
context.t(L10nKeys.yourKey)
```

Do not pass Firestore data values through translation keys. Member names, plan names, product names, notes, reasons, and receipt descriptions should remain as stored.

## Localized screens and labels

Localized first-pass areas:

- Admin sidebar/navigation labels
- Settings page title and subtitle
- Settings Language selector
- Dashboard main header/subtitle
- Members main title/subtitle, search hint, add member labels, active/inactive badge text
- Payments & Renewals main title/subtitle and selected common labels
- Check-in & Attendance main title/subtitle and active label
- Finance & Operations main title/subtitle
- Member App selected bottom-nav/header labels
- Platform Admin main title/subtitle and tenant status display

Common keys added include:

- Save
- Cancel
- Close
- Delete
- Edit
- Add
- Search
- Loading
- Retry
- Details
- Active
- Inactive
- Suspended
- Cancelled
- Error
- Success

## RTL behavior notes

- Selecting Arabic Egyptian sets the app locale to `ar_EG`.
- Flutter localizations are enabled with Material, Cupertino, and Widgets delegates.
- App-level direction becomes RTL through Flutter's localization direction handling.
- This phase does not redesign layouts for RTL; it only fixes the foundation and obvious first-pass static labels.

## Intentionally not changed

- Firebase logic was not changed.
- Firestore structure was not changed.
- Firestore rules were not changed.
- Repositories, providers, auth, roles, permissions, routes, payments, finance calculations, check-in logic, member logic, platform owner logic, and SaaS tenant control were not changed.
- Firestore data values are not translated.
- Phase 4C was not started.
- No broad UI redesign was done.

## Manual tests

1. Open app in English and confirm normal labels.
2. Change language to Arabic Egyptian from Settings.
3. Confirm sidebar/navigation labels change.
4. Confirm main page titles change.
5. Confirm common buttons change where applied.
6. Confirm RTL direction works without major overflow.
7. Refresh/restart app and confirm language persists.
8. Change back to English and confirm UI returns to English.
9. Confirm Firestore data values are not translated.
10. Confirm Dashboard, Members, Payments, Check-in, Finance, Settings, Member App, and Platform Admin still open.

## Flutter analyze result

`flutter analyze` completed after the Phase 4B changes. No new Phase 4B compile errors remain.

The analyzer still reports 22 existing unrelated warnings/infos, mainly `withOpacity` deprecations and existing `line_chart_widget` warnings.
