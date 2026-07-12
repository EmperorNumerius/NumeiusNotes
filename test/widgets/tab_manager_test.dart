import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/widgets/tab_manager.dart';
import 'package:notes_app/models/document.dart';

void main() {
  testWidgets('TabManager has tooltips on close and new tab buttons', (WidgetTester tester) async {
    final docMgr = DocumentManager();
    docMgr.openTabs.clear();
    docMgr.openTabs.add(NoteDocument(id: '1', title: 'Doc 1', blocks: []));
    docMgr.openTabs.add(NoteDocument(id: '2', title: 'Doc 2', blocks: []));

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

    // Verify "New tab" tooltip exists
    expect(find.byTooltip('New tab'), findsOneWidget);

    // Verify "Close tab" tooltip exists (2 tabs = 2 close buttons)
    expect(find.byTooltip('Close tab'), findsNWidgets(2));
  });
}
