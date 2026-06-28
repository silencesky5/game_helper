# SPEC-007 — First Execution Pipeline

## Version

1.0

## Sprint

7

## Status

Implemented

## Objective

Connect the existing application layers into the first end-to-end execution pipeline:

UI → AutomationEngine → PluginManager → WorkflowEngine → StepExecutor → DeviceService → AdbDeviceService → ADB → LDPlayer.

Pressing **Start Automation** starts the Mine Journey mock plugin workflow and sends one tap command to the configured ADB device at `x = 300`, `y = 500`.

## Implementation Notes

- `AutomationEngine.start(pluginId)` coordinates plugin lookup and workflow execution.
- `PluginManager.getPlugin(id)` returns the loaded Mine Journey plugin from the mock repository.
- The mock repository returns a workflow containing one `TapStep`.
- `WorkflowEngine.execute(workflow)` iterates workflow steps in order.
- `StepExecutor.execute(step, runtime)` delegates directly to polymorphic step execution.
- `TapStep.execute(runtime)` calls the injected device service through `AutomationContext`.
- `AdbDeviceService.tap(x, y)` sends `adb shell input tap x y`.
- The dashboard exposes a single **Start Automation** button and displays **Running...** after start.

## Logging

The first pipeline logs these messages through `ConsoleLogger`:

- Automation Started
- Workflow Loaded
- Executing TapStep
- Automation Finished

## Out of Scope

OCR, image search, template matching, workflow JSON parsing, plugin scanning, plugin installation, scheduling, loop execution semantics, conditional execution semantics, delay execution semantics, and vision features remain out of scope for this sprint.
