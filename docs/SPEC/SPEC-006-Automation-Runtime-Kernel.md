# SPEC-006 — Automation Runtime Kernel

Version: 1.0  
Sprint: 6  
Status: Implemented

## Objective

Establish the platform runtime kernel without starting workflow execution, operating devices, or parsing plugin and workflow JSON.

Implemented domain components:

- `AutomationEngine`
- `AutomationSession`
- `AutomationContext`
- `AutomationState`

## Architecture Decision

`AutomationEngine` is the platform's only automation orchestrator.

The engine does not store plugins, workflows, or workflow runtime state. Runtime state belongs to `AutomationSession`.

```text
AutomationEngine
↓
AutomationSession
↓
AutomationContext
↓
AutomationState
```

## AutomationState

`AutomationState` defines the runtime lifecycle values:

- `idle`
- `running`
- `paused`
- `stopped`
- `completed`
- `failed`

## AutomationContext

`AutomationContext` is an immutable dependency bundle for domain services:

- `PluginManager`
- `WorkflowEngine`
- `DeviceManager`
- `LoggerService`
- `StorageService`

It is created through explicit constructor injection. It is not a singleton and does not use a service locator.

## AutomationSession

`AutomationSession` is immutable and stores all automation runtime state:

- Current `Plugin`
- Current `Workflow`
- `WorkflowRuntime`
- `AutomationState`
- Session `LoggerService`

`copyWith()` returns a new session instance with selected values replaced.

The session does not store UI objects.

## AutomationEngine

`AutomationEngine` exposes the runtime orchestration API:

- `createSession()`
- `start()`
- `pause()`
- `resume()`
- `stop()`

For this sprint, lifecycle methods only return updated session state. They do not execute workflows, operate devices, parse JSON, or reference infrastructure concerns.

## Runtime Rules

- `AutomationEngine` must not import Flutter.
- `AutomationEngine` must not reference ADB, OCR, plugin JSON, or workflow JSON.
- `AutomationEngine` must depend only on domain-layer types.
- Device operations remain behind `DeviceManager` and `DeviceService`.
- Workflow execution remains behind `WorkflowEngine` and is not invoked by this kernel.
