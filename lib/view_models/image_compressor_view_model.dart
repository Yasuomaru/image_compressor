import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:file_selector/file_selector.dart';
import '../models/compressed_image.dart';

class ImageCompressorViewModel extends ChangeNotifier {
  bool _dragging = false;
  File? _originalFile;
  final List<CompressedImage> _compressed = [];
  bool _isProcessing = false;

  // Getters
  bool get dragging => _dragging;
  File? get originalFile => _originalFile;
  List<CompressedImage> get compressed => List.unmodifiable(_compressed);
  bool get isProcessing => _isProcessing;

  // Setters
  set dragging(bool value) {
    _dragging = value;
    notifyListeners();
  }

  void resetAll() {
    _originalFile = null;
    _compressed.clear();
    notifyListeners();
  }

  Future<void> compressImage(File file) async {
    try {
      // Clear existing data first
      _compressed.clear();
      _originalFile = file;
      _isProcessing = true;
      notifyListeners();

      // print("Starting compression for: ${file.path}");
      final qualities = [90, 70, 50, 30];
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final List<CompressedImage> results = [];

      if (!await file.exists()) {
        // print("File does not exist: ${file.path}");
        _isProcessing = false;
        notifyListeners();
        return;
      }

      final bytes = await file.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        // print("Failed to decode image");
        _isProcessing = false;
        notifyListeners();
        throw Exception('Failed to decode image. Try another file.');
      }

      for (var q in qualities) {
        final targetPath = '${tempDir.path}/compressed_${timestamp}_$q.jpg';
        // print("Compressing with quality $q to: $targetPath");

        final compressedBytes = img.encodeJpg(originalImage, quality: q);

        final compressedFile = File(targetPath);
        await compressedFile.writeAsBytes(compressedBytes);

        final fileSize = compressedFile.lengthSync();
        // print("Compression successful for quality $q, file size: $fileSize");

        results.add(
          CompressedImage(
            file: compressedFile,
            quality: q,
            sizeInBytes: fileSize,
          ),
        );
      }

      _compressed.addAll(results);
      _isProcessing = false;
      notifyListeners();
      // print("UI updated with ${results.length} compressed images");
    } catch (e) {
      // print("Error during compression: $e");
      _isProcessing = false;
      notifyListeners();
      rethrow; // Allow view to handle the error
    }
  }

  Future<String?> saveImageToComputer(File imageFile, int quality) async {
    try {
      final fileName =
          quality == 0
              ? 'original_image.jpg'
              : 'compressed_${quality}_percent.jpg';

      final fileSaveLocation = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'JPEG Images', extensions: ['jpg', 'jpeg']),
        ],
      );

      final path = fileSaveLocation?.path;

      if (path != null) {
        // Create a new file at the destination path
        final destinationFile = File(path);

        // Check if the destination directory exists
        final directory = Directory(destinationFile.parent.path);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        // Read bytes from source and write to destination
        final bytes = await imageFile.readAsBytes();
        await destinationFile.writeAsBytes(bytes);

        print("Image successfully saved to: $path");
        return path;
      }
      return null;
    } catch (e) {
      print("Error saving image: $e");
      // Try alternate saving method on error
      if (Platform.isMacOS) {
        try {
          return await _saveImageMacOSFallback(imageFile, quality);
        } catch (fallbackError) {
          print("Fallback save failed: $fallbackError");
        }
      }
      rethrow;
    }
  }

  // Add a macOS-specific fallback method
  Future<String?> _saveImageMacOSFallback(File imageFile, int quality) async {
    // Get the Downloads folder - a common location accessible on macOS
    final downloadsDir = '${Platform.environment['HOME']}/Downloads';
    final fileName =
        quality == 0
            ? 'original_image.jpg'
            : 'compressed_${quality}_percent.jpg';
    final savePath = '$downloadsDir/$fileName';

    // Copy the file directly to Downloads
    await imageFile.copy(savePath);
    print("Image saved to Downloads folder: $savePath");
    return savePath;
  }
}
