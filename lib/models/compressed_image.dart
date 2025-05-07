import 'dart:io';

class CompressedImage {
  final File file;
  final int quality;
  final int sizeInBytes;

  CompressedImage({
    required this.file,
    required this.quality,
    required this.sizeInBytes,
  });

  int get sizeInKB => sizeInBytes ~/ 1024;
}
