# MelodyMind 🎵

**An interactive, gamified ear-training app** built with Flutter and Firebase as an EEE Final Year Project.

MelodyMind helps beginners build core musical skills (recognising notes, remembering melodies and keeping a steady beat) through three short games with Easy, Medium and Hard levels, scores, streaks and a leaderboard.

## Games

### 🎼 Note Identification
Listen to a note and find it on the treble staff, then tap the matching note.
- **Easy (Learn):** note letter shown on the staff
- **Medium (Practise):** read the staff and listen, 2 tries per note
- **Hard (Test):** note hidden, ear only, 1 replay and 3 lives
- Includes a 4-page **"How to read the staff"** tutorial (treble clef, lines E G B D F, spaces F A C E, Middle C and sharps)

### 🧠 Sequence Memory
Watch and listen as coloured note tiles light up, then repeat the sequence. Each round adds one more note.

### 🥁 Rhythm Challenge
Play melodies on an on-screen piano.
- **Easy:** random notes with key labels, no timing
- **Medium (Practice):** familiar songs with a metronome and count-in; timing feedback only
- **Hard (Tempo Challenge):** songs with sharps at their real tempo, a tight timing window, and a metronome that fades out after the first bar; includes a pre-game briefing and end-of-song feedback with a learning tip

---

## Tech stack

- **Flutter** (Dart, SDK ≥ 3.2): Android, iOS and web from one codebase
- **Firebase Authentication:** email sign-in and guest play
- **Cloud Firestore:** user profiles, scores, streaks and leaderboard
- **Firebase Hosting:** web version at `melodymindfyp.web.app`
- **Riverpod:** state management
- **audioplayers:** low-latency note, metronome and music playback

## Getting started

**Requirements:** Flutter SDK (stable), Android Studio or VS Code, and an Android phone or emulator.

```bash
flutter pub get          # install packages
flutter run              # run on a connected device
flutter test             # run all tests
```

**Build the Android APK**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Build and publish the web version** (requires the Firebase CLI and access to the project)
```bash
flutter build web --release
firebase deploy --only hosting
```

## Credits

- **Piano note recordings:** [Salamander Grand Piano](https://archive.org/details/SalamanderGrandPianoV3) by Alexander Holm, licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)
- **Treble clef shape:** from the [Noto Music](https://fonts.google.com/noto/specimen/Noto+Music) font, © The Noto Project Authors, licensed under the [SIL Open Font License 1.1](https://openfontlicense.org)

---

## Author

**Inez Tan**, EEE Final Year Project

## License

This project is licensed under the [Apache License 2.0](LICENSE).
