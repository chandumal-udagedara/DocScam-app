# DocScam

A Flutter app that teaches people to recognise scams through short, realistic quizzes, plus a rule-based scam "red-flag" checker. It runs fully offline and collects no personal data.

- **Google Play:** [DocScam on Google Play](https://play.google.com/store/apps/details?id=com.udm.scamslayers)
- **Website:** [docscam-61eab.web.app](https://docscam-61eab.web.app/)

---

## Background

DocScam started as my final-year Applied Project (CSG3101) at Edith Cowan University, built in 2025 by our team of five, **ScamSlayers**. I was the **Project Manager and one of the core developers and researchers**.

After graduating, I continued the project on my own. This repository holds that later version. It adds:

- **Content packs:** the questions moved out of the code into versioned JSON files.
- **A scam checker:** explains which warning signs a message contains.
- **Tests and tools:** these keep both parts reliable.

---

## Features

**Quiz app**

- 147 scenario questions across three themes: **Seasons**, **Delivery** and **Job Offers**.
- Realistic SMS, email and web examples, with single-answer and multiple-answer questions.
- Randomised 5-question rounds, with an explanation of each answer at the end.
- Progress tracking saved on the device. No login is needed and no personal data is collected.

**Scam red-flag checker** (`lib/checker/`)

- Matches a message against 19 rules based on common Australian scam types. Examples are pretending to be myGov, the ATO, Australia Post or a bank, payment redirection, and remote-access scams.
- **Reports which warning signs matched. It never says "this is a scam."** A missed scam is bad, but a real message wrongly flagged erodes trust. The goal is to help the user decide, not to decide for them.
- Rules live in a versioned JSON file, so new scam patterns can be added without changing code.

---

## How it is built

| Part | What it does |
|---|---|
| `assets/content/*.json` | Versioned question packs and the checker's rule pack |
| `lib/content/content_loader.dart` | Loads packs at runtime and rejects any pack whose schema version this build doesn't support |
| `lib/checker/` | Text normaliser and rule engine |
| `tool/pack.schema.json`, `tool/validate_packs.py` | Schema and validator. Fails if a pack is broken or an image is missing, so a bad pack can't ship. |
| `tool/evaluate.dart` | Evaluation tool. Runs the real engine over labelled messages and reports precision, recall and false positives. |
| `tool/corpus-labeller.html` | Simple browser tool for labelling test messages |
| `test/` | Unit tests for content packs, rule engine and progress tracking |

---

## Running it

```bash
flutter pub get
flutter run                 # run the app
flutter test                # run the tests

# Check the content packs
python3 tool/validate_packs.py assets/content --assets . --rules assets/content/scam-patterns.json

# Evaluate the checker against a labelled set of messages
dart run tool/evaluate.dart assets/content/scam-patterns.json assets/content/corpus-seed.jsonl
```

> **Note on accuracy:** `corpus-seed.jsonl` contains made-up example messages for development only. It was written alongside the rules, so scores against it are not a real measure of accuracy. A real test needs a separate, labelled set of genuine scam and legitimate messages.

---

## Security notes

- No signing keys or passwords are stored in this repository. Release signing reads them from a local, git-ignored `android/keystore.properties`. Without that file, the project still builds with debug signing.
- The app works offline and sends no message content anywhere.

---

## Tech stack

Flutter · Dart · JSON Schema · Python (validation tooling) · SharedPreferences · Google Fonts
