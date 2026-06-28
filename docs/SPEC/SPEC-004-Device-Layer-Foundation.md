# SPEC-004 — Device Layer Foundation

Version: 1.0  
Sprint: 4  
Status: Implemented

## Objective

Establish the first device layer foundation so platform code can control Android devices through a domain-level contract.

Supported capabilities for this sprint:

- Detect device API surface with discovery returning an empty list for now.
- Tap through ADB.
- Swipe through ADB.
- Input text through ADB.
- Key event through ADB.
- Screenshot placeholder returning an empty string.
- Screen size placeholder returning zero dimensions.

## Architecture

Workflow code must not know that ADB exists. Device operations flow through the service boundary:

```text
Workflow
↓
StepExecutor
↓
DeviceService
↓
AdbDeviceService
↓
ADB
```

## Domain Device Layer

The domain device layer contains pure Dart abstractions only:

- `Device` immutable model.
- `DeviceService` interface for all device actions.
- `DeviceManager` for current-device state and service initialization.

`DeviceManager` owns selection state only. It does not execute commands, import infrastructure code, or depend on workflow, plugin, or OCR concepts.

## ADB Infrastructure Layer

The ADB implementation contains infrastructure-only concerns:

- `AdbCommandRunner` is the only class responsible for invoking the `adb` executable.
- `AdbDevice` adapts the domain `Device` model for ADB-specific discovery results.
- `AdbDeviceService` translates domain operations into ADB command arguments.

Implemented command mappings:

- `tap(x, y)` → `adb shell input tap x y`
- `swipe(startX, startY, endX, endY, duration)` → `adb shell input swipe startX startY endX endY duration`
- `input(text)` → `adb shell input text text`
- `keyEvent(keyCode)` → `adb shell input keyevent keyCode`

## Deferred Capabilities

The following service methods are intentionally placeholder implementations in this sprint:

- `getDevices()` returns an empty device list.
- `screenshot()` returns an empty string.
- `getScreenSize()` returns `ScreenSize(width: 0, height: 0)`.

## Device Layer Rules

- Workflow must not import `infrastructure/`.
- Workflow must not reference ADB, process execution, or shell commands.
- Device operations must go through `DeviceService`.
- `DeviceManager` must not depend on workflow, plugin, or OCR concepts.
- UI surfaces are unchanged for this sprint.
