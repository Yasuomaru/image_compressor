import 'package:flutter/material.dart';
import '../../models/compressed_image.dart';
import '../../view_models/image_compressor_view_model.dart';
import 'image_preview_dialog.dart';

class CompressedImageCard extends StatelessWidget {
  final CompressedImage image;
  final ImageCompressorViewModel viewModel;

  const CompressedImageCard({
    Key? key,
    required this.image,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: InkWell(
                onTap: () => _showImagePreview(context),
                child: Image.file(
                  image.file,
                  height: 150,
                  width: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Center(
              child: Text(
                '(Click to preview)',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qualidade: ${image.quality}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Tamanho: ${image.sizeInKB} KB',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  tooltip: 'Save this image',
                  onPressed: () => _saveImage(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => ImagePreviewDialog(
            imageFile: image.file,
            quality: image.quality,
            viewModel: viewModel,
          ),
    );
  }

  Future<void> _saveImage(BuildContext context) async {
    try {
      final path = await viewModel.saveImageToComputer(
        image.file,
        image.quality,
      );
      if (path != null) {
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
}
