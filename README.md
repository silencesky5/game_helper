# Game Helper Desktop Console

Game Helper is a **Windows Desktop-first Flutter application** for controlling Mine Journey running in LDPlayer Android emulators.

The Flutter UI is the desktop operations console. Android emulators are target devices only and are controlled through ADB. The automation dashboard must never be hosted by LDPlayer or any Android runtime.

## Official Runtime Architecture

```text
Game Helper Desktop Console (Windows Flutter app)
        ↓
Automation Engine
        ↓
ADB Device Detection
        ↓
Device Session Creation
        ↓
Plugin Loading
        ↓
Decision Engine
        ↓
Desktop Dashboard
        ↓
ADB
        ↓
LDPlayer
        ↓
Mine Journey
```

## Desktop Console Responsibilities

The Windows desktop window is the primary interface and displays:

- Connected LDPlayer / ADB devices
- One Device Session per detected emulator
- Screenshot previews captured through ADB
- Session state
- Current goal
- Current decision
- Current workflow
- Runtime
- Runtime logs

Screenshots and controls are surfaced only in the desktop app. The Android emulator does not render the Game Helper dashboard.

## Android Target Policy

Android project files remain in the repository only for future debugging needs. Android is not the primary runtime and should not be used to operate Game Helper.

The Android manifest intentionally does not expose a launcher entry for the dashboard, so LDPlayer is treated as a controlled device instead of a host for the Flutter UI.

## Running the Console

Start LDPlayer instances, ensure ADB can see them, and launch the Windows desktop target:

```bash
adb devices -l
flutter run -d windows
```

Expected behavior:

1. A Windows desktop window opens as **Game Helper Desktop Console**.
2. The console detects connected LDPlayer instances through ADB.
3. Each emulator appears as a Device Session.
4. Screenshot previews are captured through ADB and displayed in the desktop dashboard.
5. Mine Journey automation controls Android exclusively through ADB.
6. No Game Helper automation dashboard is installed or displayed inside the Android emulator.

## Development Notes

- Keep domain architecture independent from platform migration work.
- Do not move Automation Engine, Decision Engine, Vision, Perception, Plugin, or Mine Journey goal responsibilities into platform UI code.
- Use `flutter run -d windows` as the validation command for the supported runtime.
