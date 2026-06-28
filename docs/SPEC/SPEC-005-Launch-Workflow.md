# SPEC-005 — GrowStone Launch Workflow

Version: 1.0  
Sprint: 5  
Status: Implemented

## Objective

Launch GrowStone from the Android desktop, wait through loading without input,
handle daily attendance when it appears, and finish when the home scene is
available.

## Scenes

- Android Desktop
- Loading Scene
- Attendance Scene
- Home Scene

## Runtime Rules

- The launch task detects the GrowStone icon and launches the GrowStone Android
  package through the centralized action controller.
- Loading is identified by both the loading logo and loading percentage
  templates. No tap, swipe, or close action is issued while loading is visible.
- Attendance is a global popup with five-star priority and is checked before
  every queued task.
- Attendance detection uses template matching only: attendance title,
  receive-all button, and close button must all be present.
- Tasks must use `ActionController.randomTap()`, `randomDelay()`,
  `waitSceneChange()`, and popup helpers instead of direct fixed-coordinate
  taps.
- Receive-all is retried at most three times. Failure returns a retry result and
  logs the condition for the engine.

## Success Criteria

The workflow succeeds when either the attendance window closes or the home scene
is detected.
