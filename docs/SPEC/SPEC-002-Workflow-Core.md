# SPEC-002 — Workflow Core Foundation

Version: 1.0  
Sprint: 2  
Status: Implemented

## Summary

This document records the Workflow Core foundation for the Game Helper Platform.
The sprint establishes the pure Dart workflow domain architecture without running
workflows from JSON, connecting devices, calling ADB, OCR, OpenCV, image search,
or plugin infrastructure.

## Architecture

The Workflow Core follows this structure:

```text
Workflow
  ↓
WorkflowEngine
  ↓
WorkflowRuntime
  ↓
StepExecutor
  ↓
WorkflowStep
```

## Domain Components

- `Workflow` is an immutable workflow model with `id`, `name`, `description`,
  `version`, and ordered `steps`.
- `WorkflowStep` defines the abstract step contract with `id`, `type`, and an
  `execute()` method that only receives `WorkflowRuntime`.
- `WorkflowRuntime` stores in-memory workflow variables and execution memory.
- `WorkflowRegistry` manages registered workflow step type identifiers.
- `StepExecutor` delegates step execution to `WorkflowStep.execute()`.
- `WorkflowEngine` owns a runtime and executor, exposes lifecycle stubs, and
  executes workflow steps in order.

## Known Limitations

- Workflow is not connected to Device.
- Workflow does not parse JSON.
- Workflow does not execute plugin-provided workflow files.
- Workflow does not include delay, retry, branching, loops, or logging.
