# Deen+ 🌙

A modern, offline-first iOS Islamic companion app built natively with SwiftUI.

---

## Features

- **Offline Prayer Times**: Pure mathematical & astronomical calculations performed locally on-device. Supports 13 worldwide calculation authorities (ISNA, MWL, Makkah, Egypt, Karachi, Singapore, Dubai, etc.), multiple Asr schools (Standard / Hanafi), and high-latitude adjustment rules.
- **Auto-Settings**: Automatically chooses optimal calculation parameters and Asr schools based on device location and locale.
- **Adhan & Notifications**: Local prayer notifications with customizable reminder timings and custom adhan audio.
- **Complete Holy Quran**:
  - Offline surah reading with Uthmanic Hafs script.
  - Surah audio recitation and background audio playback.
  - Download surahs for full offline access.
  - Verse bookmarks and reading progress tracking.
- **Qibla Compass**: Real-time compass heading directly to the Kaaba in Makkah.
- **Digital Tasbih**: Haptic-feedback dhikr counter with custom targets and preset supplications.

---

## Tech Stack & Architecture

- **Platform**: iOS 17.0+
- **Language**: Swift 5.9+
- **Framework**: SwiftUI, CoreLocation, UserNotifications, AVFoundation, Combine
- **Architecture**: MVVM with ObservableObject managers
- **Project Structure**: Xcode Synchronized File Groups

---

## Project Structure

```text
Deen+/
├── Deen+/
│   ├── Data/              # Surah models, names, and metadata
│   ├── Managers/          # Business logic (Prayer, Quran, Location, Qibla, Notifications)
│   │   ├── PrayerManager.swift
│   │   ├── PrayTimes.swift
│   │   ├── PrayerAutoSettings.swift
│   │   ├── LocationManager.swift
│   │   └── ...
│   ├── Models/            # Data models
│   ├── Views/             # SwiftUI views (Home, Quran, PrayerTimes, Qibla, Tasbih, Settings)
│   └── Assets.xcassets    # App icons, colors, and graphics
├── Deen+.xcodeproj        # Xcode project configuration
├── adhan.caf              # Adhan audio asset
├── KFGQPC Uthmanic...otf  # Uthmanic Arabic font
└── README.md
```

---

## Getting Started

1. Clone this repository:
   ```bash
   git clone https://github.com/<your-username>/<your-repo-name>.git
   cd <your-repo-name>
   ```
2. Open `Deen+.xcodeproj` in Xcode 15 or later:
   ```bash
   open Deen+.xcodeproj
   ```
3. Select an iOS Simulator or connected device and hit **Run** (`Cmd + R`).

---

## License

This project is licensed under the MIT License.
