import 'dart:io';

import 'package:flutter/material.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/services/image_service.dart';

class ImageBlockWidget extends StatefulWidget {
  final ContentBlock block;
  final VoidCallback? onChanged;

  const ImageBlockWidget({
    super.key,
    required this.block,
    this.onChanged,
  });

  @override
  State<ImageBlockWidget> createState() => _ImageBlockWidgetState();
}

class _ImageBlockWidgetState extends State<ImageBlockWidget> {
  static const double _minWidth = 220;
  static const double _maxWidth = 960;
  static const double _minHeight = 140;
  static const double _maxHeight = 720;

  double get _imageHeight {
    final raw = widget.block.metadata['imageHeight'];
    if (raw is num) return raw.toDouble();
    return 220;
  }

  String? get _imagePath {
    final raw = widget.block.metadata['imagePath'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw;
    }
    return null;
  }

  Future<void> _pickImage() async {
    final path = await ImageService.importImage();
    if (path == null) return;

    setState(() {
      widget.block.metadata['imagePath'] = path;
      widget.block.metadata['imageHeight'] = _imageHeight;
    });
    widget.onChanged?.call();
  }

  void _resizeImage(DragUpdateDetails details) {
    setState(() {
      widget.block.blockWidth =
          (widget.block.blockWidth + details.delta.dx).clamp(_minWidth, _maxWidth);
      widget.block.metadata['imageHeight'] =
          (_imageHeight + details.delta.dy).clamp(_minHeight, _maxHeight);
    });
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _imagePath;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              height: _imageHeight,
              color: const Color(0xFF0F1022),
              child: imagePath == null
                  ? _buildImportPrompt()
                  : _buildImagePreview(imagePath),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: widget.block.content)
              ..selection = TextSelection.collapsed(offset: widget.block.content.length),
            onChanged: (value) {
              widget.block.content = value;
              widget.onChanged?.call();
            },
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Caption',
              hintStyle: TextStyle(color: Colors.white.withAlpha(60)),
              filled: true,
              fillColor: Colors.white.withAlpha(6),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withAlpha(14)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF4DABF7)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onPanUpdate: _resizeImage,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF4DABF7).withAlpha(28),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF4DABF7).withAlpha(120)),
                ),
                child: const Icon(Icons.open_in_full_rounded,
                    color: Color(0xFF4DABF7), size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportPrompt() {
    return Center(
      child: TextButton.icon(
        onPressed: _pickImage,
        icon: const Icon(Icons.image_outlined),
        label: const Text('Import image'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4DABF7),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.white54),
            const SizedBox(height: 6),
            Text(
              'Image not found',
              style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _pickImage,
              child: const Text('Re-import'),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(file, fit: BoxFit.cover),
        Positioned(
          right: 8,
          top: 8,
          child: Material(
            color: Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _pickImage,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
