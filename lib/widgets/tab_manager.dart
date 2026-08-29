import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/controllers/document_manager.dart';

/// GoodNotes-style horizontal tab bar for open documents.
class TabManager extends StatelessWidget {
  const TabManager({super.key});

  @override
  Widget build(BuildContext context) {
    final docMgr = context.watch<DocumentManager>();
    final tabs = docMgr.openTabs;

    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 42,
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  child: child,
                );
              },
              itemCount: tabs.length,
              // ignore: deprecated_member_use
              onReorder: (oldIdx, newIdx) {
                docMgr.reorderTabs(oldIdx, newIdx);
              },
              itemBuilder: (ctx, i) {
                final doc = tabs[i];
                final isActive = i == docMgr.activeTabIndex;

                return ReorderableDragStartListener(
                  key: ValueKey(doc.id),
                  index: i,
                  child: GestureDetector(
                    onTap: () => docMgr.setActiveTab(i),
                    child: Container(
                      constraints: const BoxConstraints(
                          minWidth: 100, maxWidth: 180),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF1A1A3E)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: isActive
                                ? const Color(0xFF00D2FF)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            doc.pdfPath != null
                                ? Icons.picture_as_pdf
                                : Icons.description_outlined,
                            size: 13,
                            color: isActive
                                ? const Color(0xFF00D2FF)
                                : Colors.white.withAlpha(80),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              doc.title,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withAlpha(100),
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Close button
                          if (tabs.length > 1)
                            IconButton(
                              onPressed: () => docMgr.closeTab(i),
                              icon: const Icon(Icons.close),
                              iconSize: 12,
                              color: Colors.white.withAlpha(60),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              tooltip: 'Close tab',
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Add tab
          Material(
            color: Colors.transparent,
            child: IconButton(
              onPressed: () => docMgr.createDocument(),
              icon: const Icon(Icons.add),
              iconSize: 16,
              color: Colors.white.withAlpha(80),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 42),
              tooltip: 'New document',
            ),
          ),
        ],
      ),
    );
  }
}
