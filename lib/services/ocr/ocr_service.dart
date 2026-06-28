/// OCR service boundary for screen text extraction.
abstract class OcrService {
  /// Reads text from an image buffer.
  Future<String> recognizeText(List<int> imageBytes);
}
