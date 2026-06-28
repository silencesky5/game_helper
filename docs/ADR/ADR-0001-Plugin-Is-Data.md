# ADR-0001 — Plugin Is Data

## Status

Accepted

## Context

The platform needs plugin support without allowing plugins to become executable application extensions. Early plugin support should remain safe, inspectable, and independent from app runtime dependencies.

## Decision

A plugin is data, not code. Plugin packages must not include Dart code and must not depend on Flutter, ADB, OCR, OpenCV, or other execution mechanisms.

A plugin may contain only data and static resources such as:

- `manifest.json`
- `workflow.json`
- assets
- templates
- `config.json`

The workflow engine is responsible for execution. Plugin packages only describe metadata, resources, configuration, and future workflow data.

## Consequences

- Plugin domain objects stay pure Dart and independent from infrastructure.
- The UI can display plugin metadata without executing plugin-provided code.
- Future workflow support can validate and execute data through platform-owned engines.
- Plugin install, update, removal, download, and execution remain separate capabilities.
