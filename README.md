
# Deen+ 
<img width="500" height="500" alt="Deen+ App Icon for iOS" src="https://github.com/user-attachments/assets/85c9367e-31cd-449f-ac7c-42296bd8af83" />


A iOS Islamic prayer app built with SwiftUI.

---

## Features

- **Offline Prayer Times**: Mathematical & astronomical calculations locally on-device.
- 13 worldwide calculation authorities (ISNA, MWL, Makkah, Egypt, Karachi, Singapore, Dubai, etc.), multiple Asr schools (Standard / Hanafi), and high-latitude adjustment rules.
- **Adhan & Notifications**: Local prayer notifications with customizable reminder and custom adhan audio.
- **Complete Holy Quran**:
  - Offline surah reading with Uthmanic Hafs script.
  - Surah audio recitation and background audio playback.
  - Download surahs for full offline access.
  - Verse bookmarks and reading progress tracking.
- **Qibla Finder**
- **Digital Tasbih**: Haptic-feedback dhikr counter

---

## Architecture

- **Platform**: iOS 26.0+
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
**Method 1**

1. clone this repository:
   ```bash
   git clone https://github.com/<your-username>/<your-repo-name>.git
   cd <your-repo-name>
   ```
2. open `Deen+.xcodeproj` in Xcode 15 or later:
   ```bash
   open Deen+.xcodeproj
   ```
3. select an iOS Simulator or connected device and hit **Run** (`Cmd + R`).

**Method 2** (need a PC if on iOS 26-26.6.1)
1. download ipa from [releases](https://github.com/reyyanbereka2010-dotcom/DeenPlus/releases)
2. sideload using [this](https://docs.sidestore.io/docs/installation/install) guide
---

## License

This project is licensed under the MIT License.
