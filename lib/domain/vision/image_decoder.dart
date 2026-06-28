import 'dart:typed_data';
import 'dart:ui' as ui;

import 'vision_types.dart';

/// Decodes screenshot PNG bytes into RGBA pixels for platform vision analysis.
class ImageDecoder {
  const ImageDecoder();

  Future<DecodedImageBuffer> decode(ImageBuffer buffer) async {
    final ui.ImmutableBuffer immutableBuffer = await ui.ImmutableBuffer.fromUint8List(buffer.current.pngBytes);
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(immutableBuffer);
    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.ByteData? bytes = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) {
      throw StateError('Unable to decode screenshot pixels for ${buffer.deviceId}');
    }
    return DecodedImageBuffer(
      imageBuffer: buffer,
      width: frame.image.width,
      height: frame.image.height,
      rgbaBytes: bytes.buffer.asUint8List(),
    );
  }
}
