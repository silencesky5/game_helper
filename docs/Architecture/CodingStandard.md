# Coding Standard

## Rule-001: Public Domain APIs use Value Objects

Public Domain APIs must use explicit Value Objects instead of Dart Records.

Dart Records must not be exposed from public Domain API contracts because they are difficult to extend, reduce readability, and do not self-document future fields such as rotation, density, or orientation.

Use immutable Value Objects for Domain API return types and data transfer concepts. Examples include:

- `ScreenSize`
- `DeviceInfo`
- `ScreenshotInfo`
- `TemplateMatchResult`
- `OCRResult`
- `ColorMatchResult`

Future platform APIs must follow this rule.
