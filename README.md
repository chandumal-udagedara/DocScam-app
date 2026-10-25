# DocScam

A Flutter app that teaches people to recognise scams through short, realistic quizzes based on Australian scam alerts.

- **Google Play:** [DocScam on Google Play](https://play.google.com/store/apps/details?id=com.udm.scamslayers)
- **Website:** [docscam-61eab.web.app](https://docscam-61eab.web.app/)

---

## Background

DocScam started as my final-year Applied Project (CSG3101) at Edith Cowan University, built in 2025 by our team of five, **ScamSlayers**. I was the **Project Manager and one of the core developers and researchers**.

This `main` branch holds the full released app (v2.x). My later work after graduating is on the [`json-content-packs`](../../tree/json-content-packs) branch. It moves the questions into versioned JSON content packs and adds a rule-based scam red-flag checker with tests (see below).

---

## Features

- **183 scenario questions across 8 categories:** Seasons, Delivery, Job Offers, Banking & Finance, Investment & Crypto, Romance Scams, Social Media and Tech Support.
- Realistic SMS, email and web examples, with single-answer and multiple-answer questions, instant feedback and explanations.
- **Sources shown for each category,** such as ACCC Scamwatch, the ATO, Australia Post, ASIC MoneySmart and the AFP.
- **Progress tracking,** quiz history and a shareable completion certificate.
- **Optional account:** users can sign in or **continue without an account**.
- **Anonymised leaderboard:** only an alias is shown.
- **Report a Scam screen:** links to official reporting sites (Scamwatch, ReportCyber, AFP).
- Onboarding, settings, reminder notifications and an in-app privacy policy.

---

## Tech stack

Flutter · Dart · Firebase (Authentication, Cloud Firestore, Analytics, Crashlytics, Cloud Messaging) · SharedPreferences · Google Fonts

| Folder | What it contains |
|---|---|
| `lib/*_screen.dart` | App screens (home, quiz, results, progress, leaderboard, certificate, report a scam, settings, onboarding) |
| `lib/services/` | Auth, progress, quiz state, leaderboard, analytics and notification services |
| `lib/question_bank.dart` | Questions, answers, explanations and sources |
| `test/` | Unit and widget tests |

---

## Running it

```bash
flutter pub get
flutter run          # run on a connected Android device or emulator
flutter test         # run the tests
```

---

## Later work: content packs and scam checker (`json-content-packs` branch)

After graduating, I continued the project on the earlier three-category version:

- **Content packs:** moved 147 questions out of code into versioned JSON packs, with a JSON Schema, a validator script and a loader that rejects unsupported pack versions.
- **Scam red-flag checker:** a rule engine that reports **which warning signs a message contains**, instead of a yes/no verdict, using 19 rules based on common Australian scam types.
- **Evaluation tool:** measures precision, recall and false positives against labelled messages.

Bringing these into this full version is a planned next step.

---

## Security notes

- No signing keys or passwords are stored in this repository. Release signing reads them from a local, git-ignored `android/keystore.properties`. Without that file, the project still builds with debug signing.
- The Firebase config files (`google-services.json`, `firebase_options.dart`) identify the Firebase project and are normally included in mobile apps. Access to data is controlled by Firebase security rules.
