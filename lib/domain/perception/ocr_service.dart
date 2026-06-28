import '../vision/vision_types.dart';
import 'perception_types.dart';

abstract class OCRService {
  Future<OCRResult> recognizeText(DecodedImageBuffer image);
}

class NoOpOCRService implements OCRService {
  const NoOpOCRService();

  @override
  Future<OCRResult> recognizeText(DecodedImageBuffer image) async => OCRResult(blocks: const <TextBlock>[], timestamp: DateTime.now());
}
