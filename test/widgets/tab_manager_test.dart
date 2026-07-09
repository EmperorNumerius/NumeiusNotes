import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/widgets/tab_manager.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/controllers/document_manager.dart';

void main() {
  testWidgets('TabManager tooltips are present', (WidgetTester tester) async {
    final docMgr = DocumentManager();
    // mock some documents
    docMgr.createDocument();
    docMgr.createDocument();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DocumentManager>.value(
            value: docMgr,
            child: const TabManager(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 'New Note' tooltip is present on the add button
    expect(find.byTooltip('New Note'), findsOneWidget);

    // Verify 'Close' tooltip is present on the close button
    expect(find.byTooltip('Close'),
        findsNWidgets(2)); // two tabs, two close buttons
  });
}
