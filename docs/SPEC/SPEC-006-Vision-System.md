# SPEC-006 Vision System v1.0

## Minimum Vision Set

Automation does not inspect dynamic game-world information. It asks the Vision
System for the current scene, then makes decisions and executes device actions.

```text
ADB Screenshot -> Vision System -> Current Scene -> Automation Engine -> Task -> ADB Action
```

## Scene List v1

- Android Desktop
- Loading
- Attendance
- Home
- Bag
- Mail
- Shop
- Unknown

## Template Library

All detector templates are addressed relative to `assets/vision/`:

- `android/growstone_icon.png`
- `loading/loading_logo.png`
- `attendance/attendance_title.png`
- `attendance/receive_all.png`
- `attendance/receive_all_disabled.png`
- `attendance/close_button.png`
- `home/bag.png`
- `home/shop.png`
- `home/mail.png`
- `home/craft.png`
- `bag/title.png`
- `mail/title.png`
- `shop/title.png`

## Detection Rules

- Android Desktop: GrowStone icon exists.
- Loading: loading logo exists. Automation must not act during Loading.
- Attendance: attendance title, receive-all button, and close button exist.
- Home: bag, shop, mail, and craft buttons all exist.
- Bag: bag window title exists.
- Mail: mail window title exists.
- Shop: shop window title exists.

## Automation Contract

Automation calls `vision.detectScene()` and receives one scene enum value. Task
logic must not call OpenCV directly and must not identify characters, maps,
monsters, HP, or other dynamic world information.

## Attendance Workflow

1. Detect the attendance popup before regular task execution.
2. If receive-all is enabled, tap a random point inside the receive-all button.
3. Wait a random 300-700 ms delay.
4. Re-detect the popup.
5. When receive-all is disabled, tap a random point inside the close button.
6. Return control to the task flow after the popup closes or Home is detected.
