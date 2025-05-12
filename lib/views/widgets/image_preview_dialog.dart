import 'dart:io';
import 'package:flutter/material.dart';
import '../../view_models/image_compressor_view_model.dart';

class ImagePreviewDialog extends StatelessWidget {
  final File imageFile;
  final int quality;
  final ImageCompressorViewModel viewModel;

  const ImagePreviewDialog({
    super.key,
    required this.imageFile,
    required this.quality,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text(quality == 0 ? 'Original Image' : 'Quality: $quality%'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.save_alt),
                tooltip: 'Save image to computer',
                onPressed: () => _saveImage(context),
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
    );
  }

  Future<void> _saveImage(BuildContext context) async {
    try {
      final path = await viewModel.saveImageToComputer(imageFile, quality);

      if (!context.mounted) return;

      if (path != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image saved to: $path')));
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving image: $e')));
    }
  }
}
