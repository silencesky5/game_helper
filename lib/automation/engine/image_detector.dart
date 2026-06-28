import 'dart:math';

/// Scenes supported by the minimum fixed-UI vision system.
enum Scene {
  /// Android launcher desktop where the GrowStone icon is visible.
  android,

  /// GrowStone loading screen. Automation must not act in this scene.
  loading,

  /// Daily attendance popup.
  attendance,

  /// Main GrowStone home scene.
  home,

  /// Bag window.
  bag,

  /// Mail window.
  mail,

  /// Shop window.
  shop,

  /// No known fixed UI matched.
  unknown,
}

/// Stable template identifiers used by all vision detectors.
abstract final class VisionTemplates {
  static const androidGrowstoneIcon = 'android/growstone_icon';
  static const loadingLogo = 'loading/loading_logo';
  static const attendanceTitle = 'attendance/attendance_title';
  static const attendanceReceiveAll = 'attendance/receive_all';
  static const attendanceReceiveAllDisabled = 'attendance/receive_all_disabled';
  static const attendanceCloseButton = 'attendance/close_button';
  static const homeBag = 'home/bag';
  static const homeShop = 'home/shop';
  static const homeMail = 'home/mail';
  static const homeCraft = 'home/craft';
  static const bagTitle = 'bag/title';
  static const mailTitle = 'mail/title';
  static const shopTitle = 'shop/title';
}

/// Central image-recognition facade for OpenCV, OCR, and template matching.
class ImageDetector {
  /// Creates an image detector placeholder.
  const ImageDetector();

  /// Finds a named UI template on the current emulator screen.
  Future<bool> findTemplate(String templateId) async => false;

  /// Finds the screen rectangle occupied by a named template.
  Future<Rectangle<int>?> findTemplateRect(String templateId) async => null;

  /// Returns whether a template's visual state is bright/enabled.
  Future<bool> isTemplateBright(String templateId) async => false;

  /// Reads text using OCR from the current screen.
  Future<String> readText() async => '';

  /// Finds a named icon on the current screen.
  Future<bool> findIcon(String iconId) async => findTemplate(iconId);

  /// Finds a named button on the current screen.
  Future<bool> findButton(String buttonId) async => findTemplate(buttonId);

  /// Detects the current scene using only fixed UI templates.
  Future<Scene> detectScene() => const VisionSystem().detectScene(this);
}

/// Boolean detector contract for a single fixed-UI scene.
abstract class SceneDetector {
  /// Creates a detector for [scene].
  const SceneDetector(this.scene);

  /// Scene returned when [detect] succeeds.
  final Scene scene;

  /// Returns true when this scene's fixed UI is present.
  Future<bool> detect(ImageDetector detector);
}

class AndroidDetector extends SceneDetector {
  const AndroidDetector() : super(Scene.android);

  @override
  Future<bool> detect(ImageDetector detector) =>
      detector.findIcon(VisionTemplates.androidGrowstoneIcon);
}

class LoadingDetector extends SceneDetector {
  const LoadingDetector() : super(Scene.loading);

  @override
  Future<bool> detect(ImageDetector detector) =>
      detector.findTemplate(VisionTemplates.loadingLogo);
}

class AttendanceDetector extends SceneDetector {
  const AttendanceDetector() : super(Scene.attendance);

  @override
  Future<bool> detect(ImageDetector detector) async {
    final hasTitle = await detector.findTemplate(
      VisionTemplates.attendanceTitle,
    );
    final hasReceiveAll = await detector.findTemplate(
      VisionTemplates.attendanceReceiveAll,
    );
    final hasClose = await detector.findTemplate(
      VisionTemplates.attendanceCloseButton,
    );
    return hasTitle && hasReceiveAll && hasClose;
  }
}

class HomeDetector extends SceneDetector {
  const HomeDetector() : super(Scene.home);

  @override
  Future<bool> detect(ImageDetector detector) async {
    final hasBag = await detector.findTemplate(VisionTemplates.homeBag);
    final hasShop = await detector.findTemplate(VisionTemplates.homeShop);
    final hasMail = await detector.findTemplate(VisionTemplates.homeMail);
    final hasCraft = await detector.findTemplate(VisionTemplates.homeCraft);
    return hasBag && hasShop && hasMail && hasCraft;
  }
}

class BagDetector extends SceneDetector {
  const BagDetector() : super(Scene.bag);

  @override
  Future<bool> detect(ImageDetector detector) =>
      detector.findTemplate(VisionTemplates.bagTitle);
}

class MailDetector extends SceneDetector {
  const MailDetector() : super(Scene.mail);

  @override
  Future<bool> detect(ImageDetector detector) =>
      detector.findTemplate(VisionTemplates.mailTitle);
}

class ShopDetector extends SceneDetector {
  const ShopDetector() : super(Scene.shop);

  @override
  Future<bool> detect(ImageDetector detector) =>
      detector.findTemplate(VisionTemplates.shopTitle);
}

/// Minimum Vision Set scene resolver.
class VisionSystem {
  /// Creates a vision system with fixed detector precedence.
  const VisionSystem({
    this.detectors = const <SceneDetector>[
      AttendanceDetector(),
      LoadingDetector(),
      HomeDetector(),
      BagDetector(),
      MailDetector(),
      ShopDetector(),
      AndroidDetector(),
    ],
  });

  /// Ordered detectors. Popup scenes run first so automation can preempt tasks.
  final List<SceneDetector> detectors;

  /// Returns the first matching scene, or [Scene.unknown].
  Future<Scene> detectScene(ImageDetector detector) async {
    for (final sceneDetector in detectors) {
      if (await sceneDetector.detect(detector)) {
        return sceneDetector.scene;
      }
    }
    return Scene.unknown;
  }
}
