# AIschedule

A macOS app that turns text or screenshots into calendar events and reminders.

## Features

- Parse natural-language schedules with DeepSeek
- Extract text from images using on-device OCR
- Review results before adding them to Calendar or Reminders
- Store the user's API key in the macOS Keychain

## Requirements

- macOS 15.0 or later
- A personal [DeepSeek API key](https://platform.deepseek.com/)

The app and its release packages do not include an API key. Each user must enter their own key in Settings.

## Build

Open `SunMoonSchedule.xcodeproj` in Xcode 16 or later, or run:

```sh
xcodebuild \
  -project SunMoonSchedule.xcodeproj \
  -scheme SunMoonSchedule \
  -configuration Release \
  -derivedDataPath DerivedData \
  build
```

## Create a Release Package

```sh
./scripts/package-release.sh
```

The ZIP file will be written to `dist/`.
