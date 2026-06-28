# SPEC-003 — Workflow Step System

Version: 1.0
Sprint: 3
Status: Implemented

## Summary

This document records the Workflow Step Type System for the Game Helper
Platform. The sprint establishes concrete pure Dart workflow step domain models
without executing device operations, OCR, JSON parsing, delay logic, branching,
loops, plugins, storage, logging, or infrastructure behavior.

## Architecture

Workflow execution remains centered on the abstract `WorkflowStep` contract:

```text
Workflow
  ↓
WorkflowStep
  ↓
StepExecutor
  ↓
Device (future sprint)
```

The workflow engine only depends on `WorkflowStep`. It does not branch on
specific step types and does not contain step-specific dispatch logic.

## Step Domain Models

The following immutable step models are available under
`lib/domain/workflow/steps/`:

- `TapStep` with `x` and `y` coordinates.
- `SwipeStep` with `startX`, `startY`, `endX`, `endY`, and `duration`.
- `DelayStep` with `milliseconds`.
- `WaitStep` with `milliseconds`.
- `OCRStep` with `region` and `variable` identifiers.
- `IfStep` with `condition`.
- `LoopStep` with `count`.

Every step extends `WorkflowStep`, uses final fields, exposes a const
constructor, and keeps `execute()` as an empty implementation for this sprint.

## Registry

`WorkflowRegistry.registerDefaultSteps()` registers only the default type
identifiers:

- `tap`
- `swipe`
- `delay`
- `wait`
- `ocr`
- `if`
- `loop`

The registry stores identifiers only. It does not create step factories.

## Out of Scope

This sprint intentionally excludes:

- Device, ADB, OCR, OpenCV, and plugin execution.
- JSON parsing or workflow file loading.
- Delay, wait, conditional, or loop behavior.
- Logger, storage, and infrastructure dependencies.
- UI changes.
