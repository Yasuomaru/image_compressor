import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:provider/provider.dart';
import '../view_models/image_compressor_view_model.dart';
import 'widgets/compressed_image_card.dart';
import 'widgets/image_preview_dialog.dart';

class ImageCompressorPage extends StatelessWidget {
  const ImageCompressorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImageCompressorViewModel(),
      child: const _ImageCompressorView(),
    );
  }
}

class _ImageCompressorView extends StatelessWidget {
  const _ImageCompressorView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ImageCompressorViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrasta uma imagem para comprimir'),
        actions: [
          if (viewModel.originalFile != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset and clear images',
              onPressed: () {
                viewModel.resetAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Imagens removidas')),
                );
              },
            ),
        ],
      ),
      body: DropTarget(
        onDragDone: (details) => _handleDragDone(context, details),
        onDragEntered: (_) => viewModel.dragging = true,
        onDragExited: (_) => viewModel.dragging = false,
        child: Container(
          color:
              viewModel.dragging
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surface,
          alignment: Alignment.center,
          child:
              viewModel.originalFile == null
                  ? Text(
                    'Arrasta uma imagem para começar',
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
                  : _buildContent(context, viewModel),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ImageCompressorViewModel viewModel,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Imagem original:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: InkWell(
              onTap: () => _showOriginalPreview(context, viewModel),
              child: Column(
                children: [
                  Image.file(viewModel.originalFile!, height: 200),
                  const Text(
                    '(Click to preview)',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
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
          viewModel.isProcessing
              ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              )
              : _buildCompressedImages(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildCompressedImages(
    BuildContext context,
    ImageCompressorViewModel viewModel,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children:
            viewModel.compressed
                .map(
                  (img) => Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: CompressedImageCard(
                      image: img,
                      viewModel: viewModel,
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  void _showOriginalPreview(
    BuildContext context,
    ImageCompressorViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => ImagePreviewDialog(
            imageFile: viewModel.originalFile!,
            quality: 0,
            viewModel: viewModel,
          ),
    );
  }

  void _handleDragDone(BuildContext context, DropDoneDetails details) async {
    final viewModel = Provider.of<ImageCompressorViewModel>(
      context,
      listen: false,
    );

    if (details.files.isEmpty) {
      return;
    }

    final file = details.files.first;
    final String filePath = file.path.toLowerCase();
    final bool isImageByExtension =
        filePath.endsWith('.jpg') ||
        filePath.endsWith('.jpeg') ||
        filePath.endsWith('.png') ||
        filePath.endsWith('.gif') ||
        filePath.endsWith('.webp') ||
        filePath.endsWith('.bmp');

    if ((file.mimeType?.startsWith('image/') ?? false) || isImageByExtension) {
      try {
        await viewModel.compressImage(File(file.path));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please drop a valid image file (JPG, PNG, etc.)'),
        ),
      );
    }
  }
}
