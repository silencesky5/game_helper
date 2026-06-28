# Changelog

## v0.7.0

### First Execution Pipeline

- Added the dashboard Start Automation action.
- Connected AutomationEngine to PluginManager and WorkflowEngine.
- Added the Mine Journey mock workflow with one tap at x = 300, y = 500.
- Routed TapStep execution through DeviceService and AdbDeviceService.
- Added SPEC-007 documentation.

## v0.6.0

### Automation Runtime Kernel

- Added the pure Dart Automation Runtime Kernel.
- Added AutomationEngine lifecycle orchestration stubs.
- Added immutable AutomationSession runtime state.
- Added immutable AutomationContext dependency bundle.
- Added AutomationState lifecycle enum.
- Added SPEC-006 and ADR-0002 documentation.

## v0.4.0

### Device Layer Foundation

- Added Device Layer Foundation.
- Added ADB Tap.
- Added ADB Swipe.
- Added ADB Input.
- Added ADB KeyEvent.

## v0.3.0

### Workflow Step System

- Added immutable pure Dart workflow step domain models.
- Added default workflow step type registration for tap, swipe, delay, wait, ocr, if, and loop.
- Added SPEC-003 Workflow Step System documentation.

## v0.2.0

### Workflow Core Foundation

- Added the pure Dart Workflow Core domain architecture.
- Added immutable workflow and abstract workflow step models.
- Added in-memory workflow runtime variable management.
- Added workflow step type registry skeleton.
- Added step executor and workflow engine execution foundation.
- Added SPEC-002 Workflow Core documentation.
