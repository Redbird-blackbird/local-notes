import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class IconPickerDialog extends StatefulWidget {
  final String currentIcon;
  final Function(String selectedIcon) onSelectIcon;
  final VoidCallback onRemoveIcon;

  const IconPickerDialog({
    super.key,
    required this.currentIcon,
    required this.onSelectIcon,
    required this.onRemoveIcon,
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  String _selectedCategory = 'All';

  final Map<String, List<String>> _categories = {
    'All': [],
    'Productivity': ['🚀', '🎯', '⚡', '💡', '📌', '⭐', '🔥', '🏆', '💎', '⌛', '⏰', '📅', '📝', '📋', '✅', '📈'],
    'Tech & Code': ['💻', '🖥️', '⌨️', '📱', '⚙️', '🔧', '📦', '🗄️', '☁️', '🌐', '📡', '🔒', '🔑', '🛠️', '🧬', '🔬'],
    'Knowledge': ['📚', '📖', '🎓', '🧠', '✏️', '🖋️', '🗞️', '📜', '📁', '📂', '📑', '🔖', '🏷️', '🔎', '🗺️', '🏛️'],
    'Life & Mood': ['☕', '🍵', '🌿', '🌱', '☀️', '🌙', '✨', '🧘', '🎧', '🎨', '🏖️', '⛰️', '🏡', '🚲', '🍕', '🍰'],
    'Work': ['💼', '📊', '🏢', '🤝', '✉️', '📞', '💡', '💳', '💰', '🧾', '🖊️', '📮', '🏷️', '📢', '🎯', '📋'],
  };

  @override
  void initState() {
    super.initState();
    final Set<String> allEmojis = {};
    for (final entry in _categories.entries) {
      if (entry.key != 'All') allEmojis.addAll(entry.value);
    }
    _categories['All'] = allEmojis.toList();
  }

  List<String> get _filteredEmojis {
    return _categories[_selectedCategory] ?? _categories['All']!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 420,
        height: 480,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Choose an icon',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onRemoveIcon();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Remove icon', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: mutedColor),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: _categories.keys.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppTheme.darkSidebarActive : AppTheme.lightSidebarActive)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? textColor : mutedColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: border),

            // Emoji Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 44,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: _filteredEmojis.length,
                itemBuilder: (context, idx) {
                  final emoji = _filteredEmojis[idx];
                  final isCurrent = widget.currentIcon == emoji;
                  return InkWell(
                    onTap: () {
                      widget.onSelectIcon(emoji);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? (isDark ? AppTheme.darkSidebarActive : AppTheme.lightSidebarActive)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent ? Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.5)) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
