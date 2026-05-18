# Smart Parking Finder — Group 6D

[![Tests](https://github.com/fardean08/Group6DAPPCW/actions/workflows/test.yml/badge.svg)](https://github.com/fardean08/Group6DAPPCW/actions/workflows/test.yml)

**API Docs:** https://fardean08.github.io/Group6DAPPCW/

**Test Plan:** [docs/Team 6D - Test Plan.xlsx](https://github.com/fardean08/Group6DAPPCW/blob/main/docs/Team%206D%20-%20Test%20Plan.xlsx)

Flutter app with Firebase Authentication and Firestore. Built for the SETaP coursework (Iteration 2).

Features:
- sign up and login via Firebase Auth
- search a destination using OpenStreetMap
- map with parking markers (`flutter_map`)
- filter by price, distance, type and lighting
- parking details bottom sheet
- availability refresh
- availability alerts when spaces free up
- Google Maps navigation
- 162 automated tests, CI via GitHub Actions

---

## Setup

**1. Create the Flutter project**

```bash
flutter create smart_parking_finder_flutter
```

Copy the files into the project folder, then:

```bash
flutter pub get
```

**2. Connect Firebase**

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart`. The repo includes a placeholder — replace it after running the above.

Also enable **Email/Password** under Authentication and create a Firestore database in the Firebase console.

---

## Run

```bash
flutter run -d chrome   # web
flutter run             # Android
```

## Test

```bash
flutter test --coverage
```

---

## Architecture

Firebase Authentication handles auth. Firestore stores parking spaces keyed by destination. Service classes hold the business logic, screens handle the UI. There's a local fallback so the app still runs if Firebase isn't set up.
