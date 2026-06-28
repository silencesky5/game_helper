import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_helper/automation/engine/action_controller.dart';
import 'package:game_helper/automation/engine/image_detector.dart';
import 'package:game_helper/automation/engine/popup_manager.dart';
import 'package:game_helper/automation/engine/state_manager.dart';
import 'package:game_helper/automation/models/game_state.dart';
import 'package:game_helper/automation/models/task_context.dart';
import 'package:game_helper/automation/models/task_result.dart';
import 'package:game_helper/automation/tasks/login/login_task.dart';
import 'package:game_helper/emulator/emulator.dart';

void main() {
  const emulator = Emulator(id: 'emu-1', name: 'LDPlayer', adbPort: 5555);

  test('attendance popup receives reward and closes with random taps', () async {
    final detector = _FakeImageDetector(
      templates: <String>{
        VisionTemplates.attendanceTitle,
        VisionTemplates.attendanceReceiveAll,
        VisionTemplates.attendanceCloseButton,
      },
      brightTemplates: <String>{VisionTemplates.attendanceReceiveAll},
    );
    var tapCount = 0;
    final actions = _FakeActionController(
      onTap: () {
        tapCount += 1;
        if (tapCount == 1) {
          detector.markReceived();
        } else {
          detector.markClosed();
        }
      },
    );
    final context = TaskContext(
      emulator: emulator,
      stateManager: StateManager(imageDetector: detector),
      actionController: actions,
      log: (_) {},
    );

    final result = await const AttendancePopupHandler().handle(context);

    expect(result.status, TaskResultStatus.success);
    expect(actions.tapRects, <Rectangle<int>>[
      detector.receiveAllRect,
      detector.closeRect,
    ]);
    expect(detector.templates, isNot(contains(VisionTemplates.attendanceTitle)));
  });

  test(
    'minimum vision system detects home only when all fixed buttons exist',
    () async {
      final detector = _FakeImageDetector(
        templates: <String>{
          VisionTemplates.homeBag,
          VisionTemplates.homeShop,
          VisionTemplates.homeMail,
          VisionTemplates.homeCraft,
        },
      );

      expect(await detector.detectScene(), Scene.home);

      detector.templates.remove(VisionTemplates.homeCraft);

      expect(await detector.detectScene(), Scene.unknown);
    },
  );

  test('launch task starts GrowStone and waits for home scene', () async {
    final detector = _FakeImageDetector(
      templates: <String>{VisionTemplates.androidGrowstoneIcon},
    );
    final stateManager = StateManager(imageDetector: detector);
    final actions = _FakeActionController(
      onWaitSceneChange: () => stateManager.update(
        const GameState(currentScene: 'home'),
      ),
    );
    final context = TaskContext(
      emulator: emulator,
      stateManager: stateManager,
      actionController: actions,
      log: (_) {},
    );

    final result = await const LoginTask().execute(context);

    expect(result.status, TaskResultStatus.success);
    expect(actions.launchedPackage, LoginTask.growStonePackageName);
  });
}

class _FakeImageDetector extends ImageDetector {
  _FakeImageDetector({required this.templates, Set<String>? brightTemplates})
      : brightTemplates = brightTemplates ?? <String>{};

  final Set<String> templates;
  final Set<String> brightTemplates;
  final Rectangle<int> receiveAllRect = const Rectangle<int>(420, 332, 100, 33);
  final Rectangle<int> closeRect = const Rectangle<int>(590, 110, 30, 30);

  @override
  Future<bool> findTemplate(String templateId) async =>
      templates.contains(templateId);

  @override
  Future<Rectangle<int>?> findTemplateRect(String templateId) async {
    return switch (templateId) {
      VisionTemplates.attendanceReceiveAll => receiveAllRect,
      VisionTemplates.attendanceCloseButton => closeRect,
      _ => null,
    };
  }

  @override
  Future<bool> isTemplateBright(String templateId) async =>
      brightTemplates.contains(templateId);

  void markReceived() {
    brightTemplates.remove(VisionTemplates.attendanceReceiveAll);
  }

  void markClosed() {
    templates
      ..remove(VisionTemplates.attendanceTitle)
      ..remove(VisionTemplates.attendanceReceiveAll)
      ..remove(VisionTemplates.attendanceCloseButton);
  }
}

class _FakeActionController extends ActionController {
  _FakeActionController({this.onTap, this.onWaitSceneChange});

  final void Function()? onTap;
  final void Function()? onWaitSceneChange;
  final List<Rectangle<int>> tapRects = <Rectangle<int>>[];
  String? launchedPackage;

  @override
  Future<void> randomTap(Emulator emulator, Rectangle<int> rect) async {
    tapRects.add(rect);
    onTap?.call();
  }

  @override
  Future<void> launchGame(Emulator emulator, String packageName) async {
    launchedPackage = packageName;
  }

  @override
  Future<void> randomDelay({
    required Duration min,
    required Duration max,
  }) async {}

  @override
  Future<bool> waitSceneChange(
    Future<bool> Function() changed, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 250),
  }) async {
    onWaitSceneChange?.call();
    return changed();
  }
}
