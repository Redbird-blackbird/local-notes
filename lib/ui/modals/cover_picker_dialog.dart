import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CoverPreset {
  final String id;
  final String name;
  final List<Color>? gradientColors;
  final String? imageUrl;

  const CoverPreset({
    required this.id,
    required this.name,
    this.gradientColors,
    this.imageUrl,
  });
}

class CoverPickerDialog extends StatefulWidget {
  final String? currentCover;
  final Function(String selectedCover) onSelectCover;
  final VoidCallback onRemoveCover;

  const CoverPickerDialog({
    super.key,
    required this.currentCover,
    required this.onSelectCover,
    required this.onRemoveCover,
  });

  static const List<CoverPreset> presets = [
    CoverPreset(
      id: 'gradient_sand',
      name: 'Warm Sand',
      gradientColors: [Color(0xFFE8D5C4), Color(0xFFF3E9DF), Color(0xFFC9ADA7)],
    ),
    CoverPreset(
      id: 'gradient_space',
      name: 'Deep Cosmos',
      gradientColors: [Color(0xFF1E1E2E), Color(0xFF2D2B55), Color(0xFF433E78)],
    ),
    CoverPreset(
      id: 'gradient_emerald',
      name: 'Emerald Pine',
      gradientColors: [Color(0xFF2C3E50), Color(0xFF34495E), Color(0xFF16A085)],
    ),
    CoverPreset(
      id: 'gradient_sunset',
      name: 'Sunset Ember',
      gradientColors: [Color(0xFFFF7E5F), Color(0xFFFEB47B), Color(0xFFFFD194)],
    ),
    CoverPreset(
      id: 'gradient_lavender',
      name: 'Lavender Mist',
      gradientColors: [Color(0xFFB39DDB), Color(0xFFCE93D8), Color(0xFFE1BEE7)],
    ),
    CoverPreset(
      id: 'gradient_ocean',
      name: 'Ocean Slate',
      gradientColors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
    ),
    CoverPreset(
      id: 'gradient_monochrome',
      name: 'Architectural Slate',
      gradientColors: [Color(0xFF373B44), Color(0xFF4286F4)],
    ),
    CoverPreset(
      id: 'photo_architecture',
      name: 'Modern Concrete',
      imageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=1200&q=80',
    ),
    CoverPreset(
      id: 'photo_forest',
      name: 'Misty Forest',
      imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1200&q=80',
    ),
    CoverPreset(
      id: 'photo_mountain',
      name: 'Alpine Peak',
      imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1200&q=80',
    ),
    CoverPreset(
      id: 'photo_minimal_desk',
      name: 'Minimal Workspace',
      imageUrl: 'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=1200&q=80',
    ),
  ];

  static Decoration getDecoration(String coverId) {
    final preset = presets.firstWhere(
      (p) => p.id == coverId,
      orElse: () => presets.first,
    );

    if (preset.gradientColors != null) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: preset.gradientColors!,
        ),
      );
    } else if (preset.imageUrl != null) {
      return BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(preset.imageUrl!),
          fit: BoxFit.cover,
        ),
      );
    }
    return const BoxDecoration(color: Color(0xFFE8D5C4));
  }

  @override
  State<CoverPickerDialog> createState() => _CoverPickerDialogState();
}

class _CoverPickerDialogState extends State<CoverPickerDialog> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
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
        width: 520,
        height: 520,
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
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Change cover',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  if (widget.currentCover != null)
                    TextButton(
                      onPressed: () {
                        widget.onRemoveCover();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentRed,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Remove cover', style: TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(width: 8),
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
            Divider(height: 1, color: border),

            // Presets Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(18),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                ),
                itemCount: CoverPickerDialog.presets.length,
                itemBuilder: (context, idx) {
                  final preset = CoverPickerDialog.presets[idx];
                  final isSelected = widget.currentCover == preset.id;

                  return InkWell(
                    onTap: () {
                      widget.onSelectCover(preset.id);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppTheme.accentBlue : border,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: CoverPickerDialog.getDecoration(preset.id),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                              child: Text(
                                preset.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
      ),
    );
  }
}
