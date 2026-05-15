# Firebase Setup

## 1. Create Firebase project

Open Firebase Console and create a project.

## 2. Enable Authentication

Go to:

Authentication > Sign-in method > Email/Password > Enable

## 3. Enable Firestore

Go to:

Firestore Database > Create database

For coursework demo, use test mode if needed.

## 4. Connect Flutter to Firebase

Run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This creates a real:

```text
lib/firebase_options.dart
```

Replace the placeholder file included in this code pack.

## 5. Run app

```bash
flutter pub get
flutter run -d chrome
```
