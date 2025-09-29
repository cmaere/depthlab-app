import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/shared_image.dart';
import '../services/image_processor.dart';

class SharedImageScreen extends StatelessWidget {
  final SharedImage sharedImage;

  const SharedImageScreen({
    super.key,
    required this.sharedImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Image'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showImageInfo(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageDisplay(),
            _buildImageDetails(),
            _buildBase64Section(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (sharedImage.base64Data == null) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text('No image data available'),
        ),
      );
    }

    final Uint8List imageBytes = base64Decode(sharedImage.base64Data!);
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              height: 300,
              child: Center(
                child: Text('Error loading image'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageDetails() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('File Name', sharedImage.fileName),
            _buildDetailRow('Path', sharedImage.path),
            _buildDetailRow('Received At', sharedImage.receivedAt.toString()),
            if (sharedImage.base64Data != null)
              _buildDetailRow(
                'File Size', 
                ImageProcessor.formatFileSize(
                  ImageProcessor.getImageSizeInBytes(sharedImage.base64Data!)
                )
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBase64Section() {
    if (sharedImage.base64Data == null) {
      return const SizedBox();
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Base64 Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                  onPressed: () => _copyBase64ToClipboard(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 150,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  sharedImage.base64Data!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Image Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This image was received via iOS share intent.'),
              const SizedBox(height: 8),
              Text('The image has been converted to base64 format for display and processing.'),
              if (sharedImage.base64Data != null)
                Text('Base64 size: ${sharedImage.base64Data!.length} characters'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _copyBase64ToClipboard() {
    // Implementation would copy base64 to clipboard
    // For now, just show a snackbar
  }
}