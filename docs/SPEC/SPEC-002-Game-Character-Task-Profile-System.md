# SPEC-002: Game / Character / Task Profile System

Version: 2.0  
Status: Planning

## Purpose

The platform manages Android devices and automation runtime only. Each device can independently select a game plugin, let that plugin detect the active character, choose a task profile, and run its own workflow queue.

The platform must not encode game rules. Game-specific actions, workflows, character detection, image/OCR logic, and game-state interpretation belong to plugins.

## Runtime Flow

```text
Device → Game → Character → Task Profile → Task Queue → Automation Runtime
```

## Core Responsibilities

### Platform

- Dashboard
- Device and ADB management
- Screenshot capture and preview
- Scheduler and per-device runtime
- Plugin manager
- Statistics and logs

### Plugin

- Actions
- Workflows
- Character detection
- Image/OCR logic
- Game state interpretation

## Dashboard Requirements

Each device card should show:

- Selected game/plugin
- Detected character
- Selected task profile
- Current task
- Next action
- Color-coded runtime status
- Clickable screenshot preview for fullscreen zoom
- Plugin Settings entry for version, author, logs, debug, reload, OCR test, and image test workflows

## Status Colors

```text
🟢 Running
🟡 Waiting
🔵 Working
🔴 Error
⚫ Offline
```

## Design Principle

Plugins provide capabilities through actions. Workflows decide execution order. Task profiles decide what the character should do today. The platform coordinates devices, sessions, runtime state, dashboard display, and plugin boundaries without knowing the content of any specific game.
