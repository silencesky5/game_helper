import '../automation/automation_session.dart';
import '../control/device_control_service.dart';
import '../core/result.dart';
import '../logger/logger.dart';
import '../logger/logger_service.dart';

/// Executable command abstraction used by workflows instead of direct services.
abstract class DeviceAction {
  const DeviceAction();
  String get label;
  Future<Result<void>> execute(ActionContext context);
}

/// Dependencies available while executing an action.
class ActionContext {
  const ActionContext({required this.session, required this.deviceControlService, required this.logger});
  final AutomationSession session;
  final DeviceControlService deviceControlService;
  final LoggerService logger;
}

class TapAction extends DeviceAction {
  const TapAction(this.x, this.y);
  final int x;
  final int y;
  @override
  String get label => 'Tap';
  @override
  Future<Result<void>> execute(ActionContext context) => context.deviceControlService.tap(context.session.device, x, y);
}

class SwipeAction extends DeviceAction {
  const SwipeAction(this.startX, this.startY, this.endX, this.endY, {this.duration = const Duration(milliseconds: 300)});
  final int startX;
  final int startY;
  final int endX;
  final int endY;
  final Duration duration;
  @override
  String get label => 'Swipe';
  @override
  Future<Result<void>> execute(ActionContext context) => context.deviceControlService.swipe(context.session.device, startX, startY, endX, endY, duration: duration);
}

class DelayAction extends DeviceAction {
  const DelayAction(this.duration);
  final Duration duration;
  @override
  String get label => 'Delay';
  @override
  Future<Result<void>> execute(ActionContext context) async {
    await Future<void>.delayed(duration);
    return const Success<void>(null);
  }
}

class LogAction extends DeviceAction {
  const LogAction(this.message);
  final String message;
  @override
  String get label => 'Log';
  @override
  Future<Result<void>> execute(ActionContext context) async {
    context.logger.log(LogLevel.info, message);
    return const Success<void>(null);
  }
}
