import 'package:flutter/material.dart';
import '../../models/block_model.dart';
import '../../theme/app_theme.dart';

class SlashMenuItem {
  final BlockType type;
  final String label;
  final String description;
  final IconData iconData;
  final String? emoji;

  const SlashMenuItem({
    required this.type,
    required this.label,
    required this.description,
    required this.iconData,
    this.emoji,
  });
}

class SlashCommandMenu extends StatefulWidget {
  final Function(BlockType type, {String? defaultText}) onSelect;
  final VoidCallback onDismiss;

  const SlashCommandMenu({
    super.key,
    required this.onSelect,
    required this.onDismiss,
  });

  static const List<SlashMenuItem> items = [
    SlashMenuItem(
      type: BlockType.paragraph,
      label: 'Text',
      description: 'Just start writing with plain text.',
      iconData: Icons.text_fields_rounded,
    ),
    SlashMenuItem(
      type: BlockType.heading1,
      label: 'Heading 1',
      description: 'Big section heading.',
      iconData: Icons.title_rounded,
      emoji: 'H1',
    ),
    SlashMenuItem(
      type: BlockType.heading2,
      label: 'Heading 2',
      description: 'Medium section heading.',
      iconData: Icons.title_rounded,
      emoji: 'H2',
    ),
    SlashMenuItem(
      type: BlockType.heading3,
      label: 'Heading 3',
      description: 'Small section heading.',
      iconData: Icons.title_rounded,
      emoji: 'H3',
    ),
    SlashMenuItem(
      type: BlockType.todo,
      label: 'To-do list',
      description: 'Track tasks with a checkbox.',
      iconData: Icons.check_box_outlined,
    ),
    SlashMenuItem(
      type: BlockType.bullet,
      label: 'Bulleted list',
      description: 'Create a simple bulleted list.',
      iconData: Icons.format_list_bulleted_rounded,
    ),
    SlashMenuItem(
      type: BlockType.numbered,
      label: 'Numbered list',
      description: 'Create a list with numbering.',
      iconData: Icons.format_list_numbered_rounded,
    ),
    SlashMenuItem(
      type: BlockType.callout,
      label: 'Callout',
      description: 'Make writing stand out with an icon card.',
      iconData: Icons.lightbulb_outline_rounded,
    ),
    SlashMenuItem(
      type: BlockType.quote,
      label: 'Quote',
      description: 'Capture a quote or highlight an idea.',
      iconData: Icons.format_quote_rounded,
    ),
    SlashMenuItem(
      type: BlockType.code,
      label: 'Code',
      description: 'Capture a code snippet.',
      iconData: Icons.code_rounded,
    ),
    SlashMenuItem(
      type: BlockType.divider,
      label: 'Divider',
      description: 'Visually divide blocks.',
      iconData: Icons.horizontal_rule_rounded,
    ),
    SlashMenuItem(
      type: BlockType.table,
      label: 'Table',
      description: 'Add a clean markdown data table.',
      iconData: Icons.table_chart_outlined,
    ),
  ];

  @override
  State<SlashCommandMenu> createState() => _SlashCommandMenuState();
}

class _SlashCommandMenuState extends State<SlashCommandMenu> {
  int _selectedIndex = 0;
  String _filter = '';
  final TextEditingController _searchCtrl = TextEditingController();

  List<SlashMenuItem> get _filteredItems {
    if (_filter.isEmpty) return SlashCommandMenu.items;
    final q = _filter.toLowerCase();
    return SlashCommandMenu.items.where((item) {
      return item.label.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final hoverBg = isDark ? AppTheme.darkSidebarHover : AppTheme.lightSidebarHover;
    final items = _filteredItems;

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 380),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: TextStyle(fontSize: 13, color: textColor),
              decoration: InputDecoration(
                hintText: 'Filter blocks...',
                hintStyle: TextStyle(fontSize: 13, color: mutedColor),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
              onChanged: (val) {
                setState(() {
                  _filter = val;
                  _selectedIndex = 0;
                });
              },
            ),
          ),
          Divider(height: 1, color: border),
          // Items List
          Flexible(
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No matching blocks',
                      style: TextStyle(fontSize: 12, color: mutedColor),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: items.length,
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final isSelected = idx == _selectedIndex;

                      return InkWell(
                        onTap: () {
                          widget.onSelect(item.type);
                        },
                        onHover: (hover) {
                          if (hover) setState(() => _selectedIndex = idx);
                        },
                        child: Container(
                          color: isSelected ? hoverBg : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSidebarBg : AppTheme.lightSidebarBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: border),
                                ),
                                alignment: Alignment.center,
                                child: item.emoji != null
                                    ? Text(
                                        item.emoji!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: textColor,
                                        ),
                                      )
                                    : Icon(
                                        item.iconData,
                                        size: 18,
                                        color: textColor,
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      item.description,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: mutedColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
