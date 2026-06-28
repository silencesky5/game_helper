# SPEC-005 — Plugin System Foundation

Version: 1.0  
Sprint: 5  
Status: Implemented

## Objective

Establish the first plugin system foundation so the platform can manage installed plugin metadata before workflow parsing exists.

## Architecture Decision

Plugins are data, not code. A plugin may provide only data files and static resources:

- `manifest.json`
- `workflow.json`
- assets
- templates
- `config.json`

Plugins must not contain Dart code and must not depend on Flutter, ADB, OCR, OpenCV, or any platform execution capability. Execution belongs to the workflow engine, not the plugin package.

## Implemented Scope

- Added pure Dart plugin domain models.
- Added a plugin manifest model with handwritten JSON conversion.
- Added a plugin repository abstraction.
- Added a plugin manager backed by repository-provided mock data.
- Added infrastructure stubs for plugin scanning and loading.
- Added a manifest parser that parses only already-decoded `manifest.json` data.
- Updated the Plugins Page to read from `PluginManager`.

## Out of Scope

The foundation does not implement workflow JSON parsing, ADB, OCR, OpenCV, marketplace features, plugin install, plugin update, plugin remove, plugin download, or plugin execution.

## Validation

The plugin page displays the repository-provided `Mine Journey` plugin as enabled with version `1.0`.
