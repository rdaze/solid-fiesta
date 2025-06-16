# 📸 Flutter Reels Clone

A minimalist Instagram Reels-style mobile app built with Flutter.

---

## 🚀 Features

- 🎞️ Vertical scrollable video feed (`PageView`)
- ❤️ Like button (visual only, parsed from json)
- 💬 Comments (visual only, parsed from json) 
- 🔗 Share buttons (visual only)
- 🔇 Tap anywhere to mute/unmute
- 👤 Display username and Follow / Followed button (parsed from json)
- 📂 Loads videos from `assets/videos/` and copies them to internal storage

---

## 📁 Video Metadata

Each video now uses a structured metadata JSON file `(assets video_metadata.json)` instead of encoding metadata in the filename.

```json
{
  "videos": [
    {
      "filename": "video1.mp4",
      "creator": "john_doe",
      "liked": true,
      "follow": false,
      "comments": [
        { "user": "alice", "comment": "Great video!" },
        { "user": "bob", "comment": "Cool!" }
      ]
    }
  ]
}
```

**Metadata Fields:**
- `filename` – Name of the associated video file in assets/videos/
- `creator` – Username of the video poster
- `liked` – Whether the video is liked (true or false)
- `follow` – Whether the creator is followed (true or false)
- `comments` – List of comments (each with user and comment)

---

## 🛠 Requirements

- Flutter
- Android SDK (emulator or physical device)
- iOS (emulator or physical device)

---

## ⚠️ Important: Impeller Must Be Disabled (Android only)

Flutter's Impeller rendering backend (used by default) can crash when playing videos on emulators.

**Use this command to run the app:**

```bash
flutter run --no-enable-impeller
```

## 📱 Preview
![](https://github.com/rdaze/solid-fiesta/blob/main/preview.gif)