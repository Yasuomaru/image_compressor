// main.dart
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:file_selector/file_selector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Compression Demo',
      home: const ImageCompressorPage(),
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
    );
  }
}

class ImageCompressorPage extends StatefulWidget {
  const ImageCompressorPage({super.key});

  @override
  State<ImageCompressorPage> createState() => _ImageCompressorPageState();
}

class _ImageCompressorPageState extends State<ImageCompressorPage> {
  bool _dragging = false;
  File? _originalFile;
  final List<_CompressedImage> _compressed = [];

  Future<void> _compressAndShow(File file) async {
    try {
      // Clear existing compressed images and update original file immediately
      setState(() {
        _compressed.clear();
        _originalFile = file;
      });

      print("Starting compression for: ${file.path}");
      final qualities = [90, 70, 50, 30];
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final List<_CompressedImage> results = [];

      if (!await file.exists()) {
        print("File does not exist: ${file.path}");
        return;
      }

      // Read and decode the image
      final bytes = await file.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        print("Failed to decode image");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to decode image. Try another file.'),
          ),
        );
        return;
      }

      for (var q in qualities) {
        // Use timestamp to ensure unique filenames for each compression session
        final targetPath = '${tempDir.path}/compressed_${timestamp}_$q.jpg';
        print("Compressing with quality $q to: $targetPath");

        // Encode as JPEG with specified quality
        final compressedBytes = img.encodeJpg(originalImage, quality: q);

        // Write compressed data to file
        final compressedFile = File(targetPath);
        await compressedFile.writeAsBytes(compressedBytes);

        print(
          "Compression successful for quality $q, file size: ${compressedFile.lengthSync()}",
        );
        results.add(_CompressedImage(file: compressedFile, quality: q));
      }

      // Completely rebuild state with new data
      setState(() {
        _compressed.addAll(results);
        print("UI updated with ${results.length} compressed images");
      });
    } catch (e) {
      print("Error during compression: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
    }
  }

  Future<void> _saveImageToComputer(File imageFile, int quality) async {
    try {
      // Create a suggested file name
      final fileName =
          quality == 0
              ? 'original_image.jpg'
              : 'compressed_${quality}_percent.jpg';

      // Get save location from user
      final path = await getSavePath(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'JPEG Images', extensions: ['jpg', 'jpeg']),
        ],
      );

      if (path != null) {
        // Copy the file to the selected location
        await imageFile.copy(path);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image saved to: $path')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving image: $e')));
    }
  }

  void _showImagePreview(File imageFile, int quality) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(
                    quality == 0 ? 'Original Image' : 'Quality: $quality%',
                  ),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.save_alt),
                      tooltip: 'Save image to computer',
                      onPressed: () => _saveImageToComputer(imageFile, quality),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Image.file(imageFile, fit: BoxFit.contain),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Size: ${imageFile.lengthSync() ~/ 1024} KB',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrasta uma imagem para comprimir'),
        actions: [
          // Only show reset button when there's an image loaded
          if (_originalFile != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset and clear images',
              onPressed: () {
                setState(() {
                  _originalFile = null;
                  _compressed.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Imagens removidas')),
                );
              },
            ),
        ],
      ),
      body: DropTarget(
        onDragDone: (details) {
          if (details.files.isEmpty) {
            return;
          }

          final file = details.files.first;

          // Check file extension as fallback method
          final String filePath = file.path.toLowerCase();
          final bool isImageByExtension =
              filePath.endsWith('.jpg') ||
              filePath.endsWith('.jpeg') ||
              filePath.endsWith('.png') ||
              filePath.endsWith('.gif') ||
              filePath.endsWith('.webp') ||
              filePath.endsWith('.bmp');

          if ((file.mimeType?.startsWith('image/') ?? false) ||
              isImageByExtension) {
            _compressAndShow(File(file.path));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please drop a valid image file (JPG, PNG, etc.)',
                ),
              ),
            );
          }
        },
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        child: Container(
          // Use theme-aware colors instead of hardcoded ones
          color:
              _dragging
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surface,
          alignment: Alignment.center,
          child:
              _originalFile == null
                  ? Text(
                    'Arrasta uma imagem para começar',
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
                  : SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Imagem original:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        // Wrap image in a container with theme-aware background
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: InkWell(
                            onTap: () => _showImagePreview(_originalFile!, 0),
                            child: Column(
                              children: [
                                Image.file(_originalFile!, height: 200),
                                const Text(
                                  '(Click to preview)',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Versões comprimidas:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        // Use SingleChildScrollView for horizontal scrolling
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children:
                                _compressed
                                    .map(
                                      (img) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 16.0,
                                        ),
                                        child: Card(
                                          elevation: 2,
                                          child: Container(
                                            width:
                                                200, // Fixed width for each card
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Center(
                                                  child: InkWell(
                                                    onTap:
                                                        () => _showImagePreview(
                                                          img.file,
                                                          img.quality,
                                                        ),
                                                    child: Image.file(
                                                      img.file,
                                                      height: 150,
                                                      width: 180,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                                const Center(
                                                  child: Text(
                                                    '(Click to preview)',
                                                    style: TextStyle(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Qualidade: ${img.quality}%',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                        Text(
                                                          'Tamanho: ${img.file.lengthSync() ~/ 1024} KB',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                      ],
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.save_alt,
                                                      ),
                                                      tooltip:
                                                          'Save this image',
                                                      onPressed:
                                                          () =>
                                                              _saveImageToComputer(
                                                                img.file,
                                                                img.quality,
                                                              ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}

class _CompressedImage {
  final File file;
  final int quality;

  _CompressedImage({required this.file, required this.quality});
}
