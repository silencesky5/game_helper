import 'perception_types.dart';

class PerceptionRepository {
  final Map<String, OCRResult> _lastOcr = <String, OCRResult>{};
  final Map<String, PopupDetection> _lastPopup = <String, PopupDetection>{};
  final Map<String, UIElement> _lastUiTree = <String, UIElement>{};
  final Map<String, PerceptionResult> _lastSemanticResult = <String, PerceptionResult>{};

  OCRResult? lastOcr(String deviceId) => _lastOcr[deviceId];
  PopupDetection? lastPopup(String deviceId) => _lastPopup[deviceId];
  UIElement? lastUiTree(String deviceId) => _lastUiTree[deviceId];
  PerceptionResult? lastResult(String deviceId) => _lastSemanticResult[deviceId];
  List<PerceptionResult> get all => List<PerceptionResult>.unmodifiable(_lastSemanticResult.values);

  void save(PerceptionResult result) {
    _lastOcr[result.deviceId] = result.ocr;
    _lastPopup[result.deviceId] = result.popup;
    _lastUiTree[result.deviceId] = result.uiTree;
    _lastSemanticResult[result.deviceId] = result;
  }
}
