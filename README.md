# Smart Parking Finder - Flutter + Firebase

[![Tests](https://github.com/fardean08/Group6DAPPCW/actions/workflows/test.yml/badge.svg)](https://github.com/fardean08/Group6DAPPCW/actions/workflows/test.yml)

**API Documentation:** https://fardean08.github.io/Group6DAPPCW/

**Test Plan:** [docs/Team 6D - Test Plan.xlsx](https://github.com/fardean08/Group6DAPPCW/blob/main/docs/Team%206D%20-%20Test%20Plan.xlsx)

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

## Architecture

The app is built in Flutter. Firebase Authentication handles login and sign-up, and Firestore stores parking spaces per searched destination. The service classes handle business logic, the screens handle presentation, and Firebase handles data. A local fallback mode keeps the app usable without a Firebase connection.
