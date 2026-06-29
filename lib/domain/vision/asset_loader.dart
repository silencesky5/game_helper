import 'dart:typed_data';

/// Loads asset bytes for platform-independent vision services.
typedef AssetBytesLoader = Future<Uint8List> Function(String assetPath);
