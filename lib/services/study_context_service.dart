import 'dart:convert';

import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/document.dart';

class StudyContextBuildOptions {
  final int maxApproxTokens;
  final int maxSectionChars;
  final int maxCodeChars;
  final int maxCodeOutputChars;
  final int maxPreviewChars;

  const StudyContextBuildOptions({
    this.maxApproxTokens = 2500,
    this.maxSectionChars = 4000,
    this.maxCodeChars = 1200,
    this.maxCodeOutputChars = 500,
    this.maxPreviewChars = 5000,
  });
}

class StudyContextSection {
  final String id;
  final String title;
  final String type;
  final String content;

  const StudyContextSection({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'content': content,
      };
}

class StudyContextResult {
  final String preview;
  final Map<String, dynamic> payload;

  const StudyContextResult({required this.preview, required this.payload});

  String payloadJson() => jsonEncode(payload);
}

class StudyContextService {
  static StudyContextResult build(
    NoteDocument document, {
    StudyContextBuildOptions options = const StudyContextBuildOptions(),
  }) {
    final sections = <StudyContextSection>[];

    final transcription = _sanitize(document.transcription);
    if (transcription.isNotEmpty) {
      sections.add(
        StudyContextSection(
          id: 'transcription',
          title: 'Lecture transcription',
          type: 'transcription',
          content: _truncate(transcription, options.maxSectionChars),
        ),
      );
    }

    final textBlocks = document.blocks
        .where((b) => b.type == ContentBlockType.text)
        .map((b) => _sanitize(b.content))
        .where((text) => text.isNotEmpty)
        .toList();
    if (textBlocks.isNotEmpty) {
      sections.add(
        StudyContextSection(
          id: 'text_blocks',
          title: 'Text notes',
          type: 'text',
          content: _truncate(_joinUnique(textBlocks), options.maxSectionChars),
        ),
      );
    }

    final latexBlocks = document.blocks
        .where((b) => b.type == ContentBlockType.latex)
        .map((b) => _sanitize(b.content))
        .where((latex) => latex.isNotEmpty)
        .toList();
    if (latexBlocks.isNotEmpty) {
      sections.add(
        StudyContextSection(
          id: 'latex_blocks',
          title: 'LaTeX formulas',
          type: 'latex',
          content: _truncate(_joinUnique(latexBlocks), options.maxSectionChars),
        ),
      );
    }

    final codeSummaries = document.blocks
        .where((b) => b.type == ContentBlockType.code)
        .map((b) => _buildCodeSummary(
              b,
              maxCodeChars: options.maxCodeChars,
              maxOutputChars: options.maxCodeOutputChars,
            ))
        .where((summary) => summary.isNotEmpty)
        .toList();
    if (codeSummaries.isNotEmpty) {
      sections.add(
        StudyContextSection(
          id: 'code_blocks',
          title: 'Code blocks',
          type: 'code',
          content: _truncate(_joinUnique(codeSummaries), options.maxSectionChars),
        ),
      );
    }

    final budgetedSections = _applyTokenBudget(sections, options.maxApproxTokens);
    final preview = _buildPreview(document, budgetedSections, options.maxPreviewChars);

    final payload = {
      'note': {
        'id': document.id,
        'title': document.title,
        'subject': document.subject,
      },
      'limits': {
        'maxApproxTokens': options.maxApproxTokens,
        'maxSectionChars': options.maxSectionChars,
      },
      'sections': budgetedSections.map((s) => s.toJson()).toList(),
    };

    return StudyContextResult(preview: preview, payload: payload);
  }

  static List<StudyContextSection> _applyTokenBudget(
      List<StudyContextSection> sections, int maxApproxTokens) {
    if (sections.isEmpty) return sections;

    final maxChars = maxApproxTokens * 4;
    var used = 0;
    final result = <StudyContextSection>[];

    for (final section in sections) {
      final remaining = maxChars - used;
      if (remaining <= 0) break;

      final content = section.content.length <= remaining
          ? section.content
          : '${section.content.substring(0, remaining)}…';

      if (content.trim().isEmpty) continue;

      result.add(StudyContextSection(
        id: section.id,
        title: section.title,
        type: section.type,
        content: content,
      ));
      used += content.length;
    }

    return result;
  }

  static String _buildPreview(
      NoteDocument document, List<StudyContextSection> sections, int maxPreviewChars) {
    final buffer = StringBuffer()
      ..writeln('Note: ${document.title}')
      ..writeln('Subject: ${document.subject.isEmpty ? 'Uncategorized' : document.subject}')
      ..writeln();

    for (final section in sections) {
      buffer
        ..writeln('## ${section.title}')
        ..writeln(section.content)
        ..writeln();
    }

    return _truncate(buffer.toString().trim(), maxPreviewChars);
  }

  static String _buildCodeSummary(
    ContentBlock block, {
    required int maxCodeChars,
    required int maxOutputChars,
  }) {
    final code = _sanitize(block.content);
    final output = _sanitize(block.output);

    if (code.isEmpty && output.isEmpty) return '';

    final safeCode = _truncate(code, maxCodeChars);
    final safeOutput = _truncate(output, maxOutputChars);

    final buffer = StringBuffer()
      ..writeln('Language: ${block.language}')
      ..writeln('Code: ${safeCode.isEmpty ? '(empty)' : safeCode}');

    if (safeOutput.isNotEmpty) {
      buffer.writeln('Output summary: $safeOutput');
    }

    return buffer.toString().trim();
  }

  static String _joinUnique(List<String> parts) {
    final unique = <String>{};
    final ordered = <String>[];
    for (final part in parts) {
      if (unique.add(part)) ordered.add(part);
    }
    return ordered.join('\n\n');
  }

  static String _sanitize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final collapsedWhitespace = raw
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return collapsedWhitespace;
  }

  static String _truncate(String value, int maxChars) {
    if (maxChars <= 0) return '';
    if (value.length <= maxChars) return value;
    return '${value.substring(0, maxChars)}…';
  }
}
