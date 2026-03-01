import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/widgets/code_block.dart';
import 'package:notes_app/models/code_language.dart';

void main() {
  testWidgets('CodeBlockWidget shows autocomplete suggestions', (tester) async {
    final block = ContentBlock(
      id: 'test_block',
      type: ContentBlockType.code,
      content: '',
      language: CodeLanguage.python,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CodeBlockWidget(block: block),
        ),
      ),
    );

    // Tap to enter edit mode (the GestureDetector is around the code area)
    await tester.tap(find.text('Tap to enter Python code...'));
    await tester.pump();

    // Enter text "pri" into the TextField
    await tester.enterText(find.byType(TextField), 'pri');
    await tester.pumpAndSettle(); // Wait for animations and overlay

    // Verify suggestions appear. "print()" is a suggestion for "pri" in python.
    expect(find.text('print()'), findsOneWidget);
  });
}
