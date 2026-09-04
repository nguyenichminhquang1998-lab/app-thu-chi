import 'dart:typed_data';

/// A file the app has produced in memory, before it reaches the user.
/// Building the bytes is pure Dart, so the mobile share sheet and the browser
/// download path deliver byte-identical output.
class ExportedFile {
  final String name;
  final String mimeType;
  final Uint8List bytes;

  const ExportedFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });
}
