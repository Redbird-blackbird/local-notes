import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/note_file.dart';
import '../../services/vault_service.dart';
import '../../theme/app_theme.dart';

class SearchModal extends StatefulWidget {
  final VaultService vaultService;

  const SearchModal({
    super.key,
    required this.vaultService,
  });

  @override
  State<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<SearchModal> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<NoteFile> get _results {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.vaultService.notes.take(6).toList();
    }
    return widget.vaultService.notes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q) ||
          n.folder.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final hoverBg = isDark ? AppTheme.darkSidebarHover : AppTheme.lightSidebarHover;
    final results = _results;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        alignment: const Alignment(0, -0.4),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 460),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20, color: mutedColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search title, content, or tags...',
                          hintStyle: TextStyle(
                            color: mutedColor.withValues(alpha: 0.6),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _selectedIndex = 0;
                          });
                        },
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, size: 16, color: mutedColor),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ESC',
                        style: TextStyle(fontSize: 10, color: mutedColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: border),

              // Results List
              Flexible(
                child: results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.find_in_page_outlined, size: 36, color: mutedColor.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'No notes found matching "${_controller.text}"',
                              style: TextStyle(fontSize: 13, color: mutedColor),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: results.length,
                        itemBuilder: (context, idx) {
                          final note = results[idx];
                          final isSelected = idx == _selectedIndex;

                          // Snippet calculation
                          String snippet = '';
                          final q = _controller.text.trim().toLowerCase();
                          if (q.isNotEmpty) {
                            final lowerContent = note.content.toLowerCase();
                            final matchIdx = lowerContent.indexOf(q);
                            if (matchIdx != -1) {
                              final start = (matchIdx - 30).clamp(0, note.content.length);
                              final end = (matchIdx + 60).clamp(0, note.content.length);
                              snippet = note.content.substring(start, end).replaceAll('\n', ' ').trim();
                              if (start > 0) snippet = '...$snippet';
                              if (end < note.content.length) snippet = '$snippet...';
                            }
                          }

                          return InkWell(
                            onTap: () {
                              widget.vaultService.selectNote(note);
                              Navigator.pop(context);
                            },
                            onHover: (hover) {
                              if (hover) setState(() => _selectedIndex = idx);
                            },
                            child: Container(
                              color: isSelected ? hoverBg : Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Text(note.icon, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                note.title.isEmpty ? 'Untitled' : note.title,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withValues(alpha: 0.6),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                note.folder,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: mutedColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (snippet.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            snippet,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: mutedColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('MMM d').format(note.lastModified),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mutedColor.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              Divider(height: 1, color: border),
              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      _controller.text.isEmpty ? 'Recent Pages' : 'Search Results',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: mutedColor.withValues(alpha: 0.7)),
                    ),
                    const Spacer(),
                    Text(
                      '${results.length} notes',
                      style: TextStyle(fontSize: 11, color: mutedColor.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
