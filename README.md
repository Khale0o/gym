# APEX GymSaaS

A Flutter-based gym management dashboard and member experience prototype for a premium fitness brand. The project presents a polished admin panel for operations, member management, check-ins, finance snapshots, and AI-assisted coaching concepts.

This repository is currently a prototype/demo, not a production-ready SaaS application.

## Project Overview

APEX GymSaaS is designed as a luxury gym operations interface with a dark premium visual style and multi-module navigation. It showcases how a gym business could manage:

- Dashboard KPIs and occupancy
- Member profiles and training progress
- Check-in station activity
- Finance and operations summaries
- AI-generated coaching and retention insights
- Member mobile app preview

The current implementation is best understood as a concept product or interactive prototype that demonstrates product direction, UI quality, and feature scope.

## Features

- Premium branded admin dashboard
- Member listing with search and profile details
- Live occupancy display and simulation controls
- Check-in station with NFC/QR/manual activity simulation
- ERP-style finance and staff overview
- AI engine with coaching, churn, nutrition, and chat modes
- Member app preview in a mobile device frame
- Firebase Firestore-backed demo data streams
- Riverpod-based application state
- `go_router` navigation with admin shell layout

## Tech Stack

- Flutter
- Dart
- Firebase Core
- Cloud Firestore
- Cloud Functions (planned/integrated at endpoint level)
- Riverpod
- go_router
- google_fonts
- fl_chart
- shimmer
- http
- intl

## Folder Structure

```text
lib/
  core/          Theme, helpers, shared constants
  data/          Demo/mock Firestore seed data
  models/        Member, check-in, plan, transaction, and staff models
  navigation/    Router and admin shell layout
  providers/     Riverpod state and Firestore stream providers
  screens/       Feature screens by module
  services/      AI service and prompt builders
  widgets/       Reusable UI components and charts

test/
  widget_test.dart
```

## Screens and Modules

- `Login`
  Demo login screen with branded animation and mocked credential flow
- `Dashboard`
  KPI summary, occupancy, weekly sessions, hourly crowd, and live check-ins
- `Members`
  Member list, search, churn hints, and detailed member profile view
- `Check-in`
  Simulated check-in station with occupancy adjustments and access log
- `Finance & Operations`
  Membership plans, transactions, and staff status
- `Member App Preview`
  Mock mobile-facing experience for workouts, nutrition, and progress
- `AI Engine`
  Simulated coaching, churn, nutrition, and chat interactions

## Setup Instructions

### Prerequisites

- Flutter SDK 3.x+
- Dart SDK compatible with the Flutter version in use
- Firebase project access if you want real backend connectivity
- Android Studio, VS Code, or another Flutter-capable IDE

### Install Dependencies

```bash
flutter pub get
```

### Run the App

```bash
flutter run
```

You can also target specific platforms such as:

```bash
flutter run -d chrome
flutter run -d windows
flutter run -d android
```

## Firebase Configuration Notes

Firebase is already referenced in the project through:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `firebase.json`
- `.firebaserc`

Important notes:

- The app initializes Firebase on startup in `lib/main.dart`.
- Firestore is used directly from Riverpod providers and utility functions.
- The AI module points to a Cloud Function URL but falls back to mock output if the endpoint is unavailable.
- Non-Android Firebase targets appear only partially configured and should be verified before real deployment.
- Because this is a prototype, review all Firebase credentials, app IDs, and environment setup before sharing the project publicly.

## How the Current Prototype Works

- Authentication is mocked through a local Riverpod notifier.
- Core app data is read from Firestore collections such as `members`, `checkins`, `plans`, `transactions`, `staff`, and `occupancy/current`.
- If the members collection is empty, the dashboard currently triggers demo seeding logic.
- Several KPI values and analytics panels remain hardcoded for presentation purposes.
- The AI feature may display locally generated mock responses when backend connectivity fails.

## Known Limitations

- The project is currently a prototype/demo, not a production application.
- Authentication is not backed by Firebase Auth or any secure identity system.
- Demo credentials are hardcoded in the app.
- Demo data can be seeded from the dashboard flow.
- Some modules mix real Firestore data with hardcoded UI values.
- Error handling is limited in key flows.
- Test coverage is minimal and currently not aligned with app behavior.
- There is no repository/service abstraction between UI state and Firestore access.
- Sensitive production concerns such as role-based access, auditing, secure secrets management, and observability are not implemented.

## Known Production Risks

- Hardcoded login credentials
- Automatic demo data writes to Firestore
- Non-transactional check-in and occupancy updates
- Mock AI fallback that can look like a real backend result
- Partial platform configuration for Firebase
- Lack of meaningful automated test coverage

## Future Improvements

- Replace mocked auth with secure backend authentication
- Add role-based access control and session persistence
- Move Firestore access behind repositories/services
- Remove automatic demo seeding from runtime user flows
- Make check-in and occupancy writes transactional
- Add structured loading, error, and empty states across modules
- Replace hardcoded KPIs with live computed metrics
- Implement environment-based configuration for endpoints and Firebase setup
- Add unit, widget, and integration tests
- Add logging, crash reporting, analytics, and monitoring
- Harden AI integration with explicit backend availability and fallback messaging

## Developer Notes

- UI consistency is one of the strongest parts of this codebase.
- The architecture is understandable and easy to navigate for a small team.
- The current implementation is suitable for demos, investor previews, internal concept validation, or a foundation for a more serious rebuild.
- Before shipping, the app should go through a production hardening phase focused on authentication, data integrity, backend boundaries, testing, and operational safeguards.

## Status

Prototype / Demo

Recommended usage today:

- UI showcase
- Product concept demo
- Internal experimentation
- Foundation for future production refactor
