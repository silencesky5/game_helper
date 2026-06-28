import '../models/task_context.dart';
import '../models/task_result.dart';

/// Priority order for global popups that must preempt regular tasks.
enum PopupPriority {
  /// Daily attendance reward popup.
  attendance(5),

  /// Network error popup.
  networkError(5),

  /// Disconnect popup.
  disconnect(5),

  /// Announcement popup.
  announcement(4),

  /// Reward popup.
  reward(4);

  const PopupPriority(this.stars);

  /// Human-readable priority stars from the launch workflow spec.
  final int stars;
}

/// Handles global popup checks before regular task execution.
class PopupManager {
  /// Creates a popup manager.
  const PopupManager({this.attendanceHandler = const AttendancePopupHandler()});

  /// Attendance has the highest popup priority and must be checked globally.
  final AttendancePopupHandler attendanceHandler;

  /// Executes all known popup checks in priority order.
  Future<TaskResult> checkAndHandle(TaskContext context) async {
    if (await attendanceHandler.detect(context)) {
      return attendanceHandler.handle(context);
    }
    return const TaskResult.skipped('No global popup detected');
  }
}

/// Detector and workflow handler for the GrowStone daily attendance popup.
class AttendancePopupHandler {
  /// Creates an attendance popup handler.
  const AttendancePopupHandler({this.maxReceiveRetries = 3});

  /// Maximum retry count after clicking an enabled receive-all button.
  final int maxReceiveRetries;

  /// Attendance requires title, receive-all button, and close button templates.
  Future<bool> detect(TaskContext context) async {
    final detector = context.stateManager.imageDetector;
    final hasTitle = await detector.findTemplate('attendance_check_title');
    final hasReceiveAll = await detector.findTemplate(
      'attendance_receive_all_button',
    );
    final hasClose = await detector.findTemplate('attendance_close_button');
    return hasTitle && hasReceiveAll && hasClose;
  }

  /// Receives rewards when available, otherwise closes the attendance popup.
  Future<TaskResult> handle(TaskContext context) async {
    for (var attempt = 1; attempt <= maxReceiveRetries; attempt += 1) {
      if (!await detect(context)) {
        return const TaskResult.success('Attendance window closed');
      }

      final receiveRect = await context.stateManager.imageDetector
          .findTemplateRect('attendance_receive_all_button');
      if (receiveRect == null) {
        return const TaskResult.retry('Attendance receive-all button disappeared');
      }

      final enabled = await context.stateManager.imageDetector.isTemplateBright(
        'attendance_receive_all_button',
      );
      if (enabled) {
        context.log(
          'Attendance receive-all available; attempt $attempt/$maxReceiveRetries',
        );
        await context.actionController.randomTap(context.emulator, receiveRect);
        await context.actionController.randomDelay(
          min: const Duration(milliseconds: 500),
          max: const Duration(milliseconds: 1000),
        );
        continue;
      }

      await _close(context);
      return const TaskResult.success('Attendance already received and closed');
    }

    context.log('Attendance receive-all failed after $maxReceiveRetries retries');
    return const TaskResult.retry('Attendance receive-all failed');
  }

  Future<void> _close(TaskContext context) async {
    final closeRect = await context.stateManager.imageDetector.findTemplateRect(
      'attendance_close_button',
    );
    if (closeRect != null) {
      await context.actionController.randomTap(context.emulator, closeRect);
      await context.actionController.randomDelay(
        min: const Duration(milliseconds: 250),
        max: const Duration(milliseconds: 450),
      );
      await context.actionController.waitSceneChange(
        () async =>
            !await detect(context) || context.stateManager.currentScene() == 'home',
      );
    }
  }
}
