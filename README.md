# 📸 Flutter Reels Clone

A minimalist Instagram Reels-style mobile app built with Flutter.

---

## 🚀 Features

- 🎞️ Vertical scrollable video feed (`PageView`)
- ❤️ Like button (visual only, based on filename)
- 💬 Comment and Share buttons (visual only)
- 🔇 Tap anywhere to mute/unmute
- 👤 Display username and Follow / Followed button (parsed from filename)
- 📂 Loads videos from `assets/videos/` and copies them to internal storage

---

## 📁 Filename Format

Each video file name should follow this pattern:
y_username_n.mp4
^ ^ ^
| | └── Follow state: y for Followed, n for Follow
| └────────── Username (can include underscores)
└──────────── Like state: y for Liked, n for Not Liked

**Examples:**
- `y_john_doe_y.mp4` → liked & followed
- `n_alice_n.mp4` → not liked & not followed
- `y_chef_mike_n.mp4` → liked & not followed

---

## 🛠 Requirements

- Flutter
- Android SDK (emulator or physical device)
- iOS not yet tested (should be possible)

---

## ⚠️ Important: Impeller Must Be Disabled

Flutter's Impeller rendering backend (used by default) can crash when playing videos on emulators.

**Use this command to run the app:**

```bash
flutter run --no-enable-impeller
```

## 📱 Preview
![](https://github.com/rdaze/solid-fiesta/blob/main/preview.gif)