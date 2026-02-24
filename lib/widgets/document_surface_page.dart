import 'package:flutter/material.dart';
import 'package:notes_app/widgets/canvas_page.dart';

/// Unified document surface for both plain notes and PDF-backed notes.
class DocumentSurfacePage extends StatelessWidget {
  const DocumentSurfacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CanvasPage();
  }
}

