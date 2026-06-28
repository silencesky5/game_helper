/// OpenCV service boundary for template and icon matching.
abstract class OpenCvService {
  /// Returns whether [templateId] is present in [imageBytes].
  Future<bool> matchTemplate(List<int> imageBytes, String templateId);
}
