# Smart Parking Finder - Flutter + Firebase

[![Tests](https://github.com/fardean08/Group6DAPPCW/actions/workflows/test.yml/badge.svg)](https://github.com/fardean08/Group6DAPPCW/actions/workflows/test.yml)

**API Documentation:** https://fardean08.github.io/Group6DAPPCW/

**Test Plan:** [docs/test-plan.pdf](https://github.com/fardean08/Group6DAPPCW/blob/main/docs/test-plan.pdf) *(download to view correctly — GitHub's PDF viewer may show formatting issues)*

This is a Flutter/Firebase version of the Smart Parking Finder prototype.

It includes:

- Firebase Authentication login
- Firebase Authentication sign up
- Firestore parking-space storage
- destination search
- real map using OpenStreetMap through `flutter_map`
- parking markers on the map
- price, distance, type, and lighting filters
- parking details screen
- availability refresh every 5 seconds
- availability alerts
- Google Maps navigation link
- automated Flutter unit tests
- GitHub Actions workflow

The app also has a local fallback mode, so it can still open if Firebase is not configured yet. For the real coursework demo, configure Firebase and enable Email/Password Authentication.

---

## How to create the Flutter project

Run:

```bash
flutter create smart_parking_finder_flutter
```

Then copy the files from this pack into the project folder, replacing existing files when asked.

Then run:

```bash
cd smart_parking_finder_flutter
flutter pub get
```

---

## Firebase setup

1. Go to Firebase Console and create a project.
2. Enable **Authentication > Sign-in method > Email/Password**.
3. Enable **Firestore Database**.
4. Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

5. Configure Firebase:

```bash
flutterfire configure
```

This will generate a real `lib/firebase_options.dart`.

This code pack includes a placeholder `firebase_options.dart` so the code is complete, but you should replace it using `flutterfire configure`.

---

## Run the app

For Chrome:

```bash
flutter run -d chrome
```

For Android emulator:

```bash
flutter run
```

---

## Run tests

```bash
flutter test --coverage
```

---

## Push to GitHub

```bash
git init
git add .
git commit -m "Initial Flutter Firebase Smart Parking Finder"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/smart-parking-finder-flutter.git
git push -u origin main
```

---

## Coursework report wording

You can write:

> The final system was implemented in Flutter with Firebase Authentication and Firestore. Firebase Authentication supports login and sign-up, while Firestore stores the generated parking-space data for each searched destination. The Flutter app provides the presentation layer, the service classes provide the application logic layer, and Firebase/Firestore provide the data layer. A local fallback mode was also kept to make development and testing easier if Firebase configuration is unavailable.
