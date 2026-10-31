# DailyRise — Habit Tracker

**Rise a Little Every Day.**

DailyRise is a Flutter habit-tracking application designed to help people build consistent daily routines, record habit completion, and review their progress. The current project uses Firebase Authentication for accounts and Cloud Firestore for user profiles, habits, completion history, and preferences.

> This README documents the code currently present in the repository's `main` branch. It does not claim that features such as push notifications, AdMob, or a premium subscription are implemented unless they are present in the source.

## Table of contents

- [Overview](#overview)
- [Current features](#current-features)
- [Technology stack](#technology-stack)
- [Project structure](#project-structure)
- [Application flow](#application-flow)
- [Firebase and data model](#firebase-and-data-model)
- [Design system](#design-system)
- [Getting started](#getting-started)
- [Run and build](#run-and-build)
- [Important implementation notes](#important-implementation-notes)
- [Security checklist](#security-checklist)
- [Troubleshooting](#troubleshooting)
- [Future development](#future-development)

## Overview

| Item | Current repository configuration |
|---|---|
| Application name | DailyRise |
| Flutter package name | `daily_rise` |
| Android application ID | `com.example.daily_rise` |
| Main language | Dart |
| UI framework | Flutter |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Version | `1.0.0+1` (from `pubspec.yaml`) |
| Default Git branch | `main` |

## Current features

### Account and authentication
- Email/password account registration.
- User profile document creation in Firestore during registration.
- Email verification link sent after registration.
- Verification status is refreshed before allowing access.
- Login blocks accounts whose email address is not verified.
- Resend verification email.
- Forgot-password email request.
- Logout through Firebase Authentication.
- Friendly handling for common Firebase Authentication errors.

### Habit tracking
- Create a habit with a name.
- View the signed-in user's habit list.
- Mark a habit complete for the current date.
- Undo today's completion.
- Store completion dates with each habit.
- Delete a habit after confirmation.
- Home screen displays habit totals, today's completion information, and streak-related information.

### Progress
- Reads the user's habits and completion history from Firestore.
- Calculates today's completion percentage.
- Builds a seven-day activity summary.
- Calculates a streak from recorded completion dates.
- Shows recent completion activity.
- Provides empty, loading, and error states.

### Profile and preferences
- Displays account information.
- Edit the display name.
- Save a dark-mode preference.
- Enable or disable the daily-reminder preference.
- Select and save a preferred reminder time.
- Export habit records from the profile screen.
- Account deletion flow is available in the profile UI.

**Reminder note:** the current code stores reminder preferences in Firestore. A saved reminder preference/time does not, by itself, schedule an operating-system notification. A notification scheduler and permission flow would need to be implemented separately.

## Technology stack

- **Flutter / Dart** — cross-platform application UI and application logic.
- **Firebase Core** — initializes Firebase for the current platform.
- **Firebase Authentication** — email/password account management and email verification.
- **Cloud Firestore** — user profiles, habits, completion dates, and settings.
- **Cupertino Icons** — iOS-style icon package.
- **Flutter Lints** — static analysis and code-quality rules.

Main dependencies are declared in `pubspec.yaml`. Run `flutter pub get` after changing dependencies.

## Project structure

```text
daily_rise/
├── android/
│   └── app/
│       ├── build.gradle.kts
│       ├── google-services.json
│       └── src/
├── lib/
│   ├── auth/
│   │   ├── authrepo.dart
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── screens/
│   │   ├── Bottom_sheet_screen.dart
│   │   ├── home_screen.dart
│   │   ├── my_habit.dart
│   │   ├── profile_screen.dart
│   │   ├── progress_screen.dart
│   │   ├── splash_screen.dart
│   │   └── verify_link.dart
│   ├── firebase_options.dart
│   └── main.dart
├── test/
│   └── widget_test.dart
├── web/
├── windows/
├── analysis_options.yaml
├── firebase.json
├── pubspec.lock
├── pubspec.yaml
└── README.md
```

### Main source files

| File | Responsibility |
|---|---|
| `lib/main.dart` | Firebase initialization, app entry point, global theme and colors |
| `lib/auth/authrepo.dart` | Authentication and account-related Firebase operations |
| `lib/auth/login_screen.dart` | Login and forgot-password interface |
| `lib/auth/signup_screen.dart` | Registration interface and terms acceptance |
| `lib/screens/verify_link.dart` | Email verification status check and resend action |
| `lib/screens/splash_screen.dart` | Animated splash and signed-in-user routing |
| `lib/screens/Bottom_sheet_screen.dart` | Main bottom-navigation shell |
| `lib/screens/home_screen.dart` | Home dashboard and primary habit actions |
| `lib/screens/my_habit.dart` | Dedicated habit-list management screen |
| `lib/screens/progress_screen.dart` | Completion statistics and activity history |
| `lib/screens/profile_screen.dart` | Profile, preferences, export, and account actions |
| `lib/firebase_options.dart` | Generated Firebase platform configuration |

## Application flow

1. `main()` initializes Flutter and Firebase.
2. `DailyRiseApp` loads the application theme and opens `SplashScreen`.
3. The splash screen waits briefly and checks the current Firebase user.
4. A verified signed-in user is routed to the main navigation screen.
5. A signed-out or unverified user is routed to the login screen.
6. A new user registers, a Firestore user profile is created, and a verification email is sent.
7. The user opens the verification link and returns to the app to check verification.
8. Once verified, the user can access the habit-tracking experience.

## Firebase and data model

The app currently uses the following Firestore structure:

```text
users (collection)
└── {uid} (document)
    ├── uid: string
    ├── name: string
    ├── displayName: string
    ├── email: string
    ├── createdAt: timestamp
    ├── settings (map)
    │   ├── darkMode: boolean
    │   ├── remindersEnabled: boolean
    │   └── reminderTime: string
    └── habits (subcollection)
        └── {habitId} (document)
            ├── title: string
            └── completedDates: array<string>
```

### Habit completion date format

Completion dates are stored as strings in:

```text
YYYY-MM-DD
```

For example, `2026-10-31`. The home and progress screens use these date keys to determine whether a habit was completed on a given day.

### Firebase setup

1. Create or select a Firebase project.
2. Register the Android app using the Android application ID from `android/app/build.gradle.kts`.
3. Enable **Authentication → Sign-in method → Email/Password**.
4. Create a **Cloud Firestore** database.
5. Configure Firebase for each platform you intend to run.
6. Place the Android Firebase configuration file at `android/app/google-services.json`.
7. Regenerate or verify `lib/firebase_options.dart` using FlutterFire CLI if the Firebase project or platform configuration changes.
8. Deploy Firestore security rules that restrict each user to their own profile and habits.

The repository currently contains Firebase configuration for the project used by this codebase. Do not reuse it for a different Firebase project; generate a matching configuration instead.

### Recommended Firestore security rules

The following is a secure starting point for the data paths used by this app. Review it against any future collections before deploying:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, create, update, delete:
        if request.auth != null && request.auth.uid == userId;

      match /habits/{habitId} {
        allow read, create, update, delete:
          if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

Test rules in the Firebase Emulator or Rules Playground before production deployment. Do not use open rules such as `allow read, write: if true`.

## Design system

The app uses a dark, nature-inspired visual direction with forest-green surfaces and warm cream text. The main theme is defined in `lib/main.dart`.

| Token | Hex value | Purpose |
|---|---|---|
| Forest background | `#10251D` | Main app background |
| Forest green | `#245C45` | Secondary green |
| Botanical green | `#63B88A` | Primary accent and actions |
| Warm cream | `#F5F0E6` | Main text |
| Soft sage | `#A8C5B2` | Supporting text |
| Dark surface | `#183328` | Inputs and surfaces |
| Card surface | `#1E3A2D` | Cards |

Some individual screens define their own closely related palette constants. Keep those coordinated when updating the design.

## Getting started

### Requirements

Install the Flutter SDK and a supported development environment (Android Studio or VS Code). Android development also requires the Android SDK and an emulator or physical device. For iOS builds, use macOS with Xcode.

Check your environment:

```bash
flutter doctor
```

### Clone the repository

```bash
git clone https://github.com/sheikhabdullaa/daily_rise.git
cd daily_rise
```

### Install dependencies

```bash
flutter pub get
```

### Configure Firebase

Make sure the Firebase configuration files and generated options match the Firebase project you control. See [Firebase setup](#firebase-setup).

### Run the app

```bash
flutter run
```

## Run and build

### Static analysis

```bash
flutter analyze
```

### Tests

```bash
flutter test
```

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

For Play Store distribution, configure a production upload keystore and release signing in the Android Gradle configuration. The current checked-in Gradle file uses the debug signing configuration for release builds; replace this before publishing.

## Important implementation notes

- Authentication logic is centralized in `AuthRepo`; use it instead of duplicating sign-in and verification logic across screens.
- The app requires email verification before the user can enter the main experience.
- Habit documents are scoped under the authenticated user's UID.
- Completion dates are stored as an array of date strings, with Firestore array operations used to add or remove today's date.
- The dedicated `MyHabitsScreen` and the home screen both contain habit-management logic. If the project grows, consider extracting shared habit operations into a repository/service to avoid duplicated code.
- Profile preferences are persisted in the user's Firestore document.
- The reminder settings are preferences only until a local notification or push-notification implementation is added.
- The current Android package/application ID is `com.example.daily_rise`; change it consistently before a public release if a production identifier is required.

## Security checklist

Before publishing or sharing a production build:

- [ ] Confirm Firestore rules enforce per-user access.
- [ ] Confirm Firebase Authentication email/password is configured.
- [ ] Never commit service-account private keys or admin credentials.
- [ ] Review Firebase configuration and API-key restrictions for the intended platforms.
- [ ] Configure production release signing; do not publish with debug signing.
- [ ] Verify account deletion behavior and decide whether related Firestore data must also be deleted.
- [ ] Test signup, email verification, login, password reset, logout, and session restoration.
- [ ] Test habit creation, completion, undo, deletion, and progress calculations.
- [ ] Test Firestore permissions with more than one user account.
- [ ] Review privacy policy and data handling disclosures before store submission.

## Troubleshooting

**Firebase initialization error**
- Verify that the platform configuration files match the Firebase project.
- Confirm the generated `firebase_options.dart` contains the intended platform configuration.
- Run `flutter clean`, then `flutter pub get`, and rebuild.

**Email/password login does not work**
- Confirm Email/Password is enabled in Firebase Authentication.
- Check the entered email and password.
- Confirm the account's email address has been verified.

**Verification email is not received**
- Check spam/junk folders.
- Confirm the email action is configured in Firebase Authentication.
- Use the resend action in the verification screen and avoid repeated rapid requests.

**Habits or progress fail to load**
- Check internet connectivity and Firebase project selection.
- Review Firestore security rules and the signed-in user's UID.
- Inspect the Flutter debug console for the underlying Firestore error.

**Android build or Gradle issue**
- Run `flutter doctor -v`.
- Confirm Android SDK and Java/Gradle compatibility for the installed Flutter version.
- Try `flutter clean` followed by `flutter pub get`.

## Future development

Potential next steps (not represented as completed features in the current source):

- Scheduled local reminders and notification permissions.
- Habit categories, frequency schedules, and custom goals.
- More detailed weekly/monthly reports.
- Cloud backup/export improvements.
- Premium subscription and ad integration, if required by the product roadmap.
- Automated tests for authentication, habit CRUD, and progress calculations.
- Shared habit repository/service to reduce duplicated Firestore logic.

## Repository

- GitHub: https://github.com/sheikhabdullaa/daily_rise
- Default branch: `main`

---

**DailyRise — Rise a Little Every Day.**
