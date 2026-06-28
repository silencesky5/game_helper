# ADR-0002 — Automation Orchestrator

## Status

Accepted

## Context

The platform needs one runtime orchestration boundary for automation lifecycle operations. Previous domain foundations introduced plugins, workflows, logging, storage, and devices independently. Sprint 6 introduces the runtime kernel that composes those domain services without starting workflow execution.

## Decision

`AutomationEngine` is the only automation orchestrator.

`AutomationEngine` does not own plugin, workflow, or runtime state. It only creates and transitions `AutomationSession` values. `AutomationSession` stores current plugin, current workflow, workflow runtime, logger, and lifecycle state.

`AutomationContext` provides explicitly injected domain services to the runtime kernel:

- `PluginManager`
- `WorkflowEngine`
- `DeviceManager`
- `LoggerService`
- `StorageService`

## Consequences

- Runtime state is isolated in immutable sessions.
- The orchestrator remains pure Dart and Flutter-free.
- The orchestrator does not know about ADB, OCR, JSON formats, or infrastructure implementations.
- Workflow execution can be connected in a later sprint without changing the ownership model.
