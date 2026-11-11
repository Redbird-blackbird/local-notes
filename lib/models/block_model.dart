enum BlockType {
  heading1,
  heading2,
  heading3,
  paragraph,
  todo,
  bullet,
  numbered,
  callout,
  quote,
  code,
  divider,
  table,
}

class NotionBlock {
  String id;
  BlockType type;
  String text;
  bool isChecked;
  String? calloutIcon;
  String? calloutColor;
  String? codeLanguage;
  int? numberIndex;
  List<List<String>>? tableData;

  NotionBlock({
    required this.id,
    required this.type,
    required this.text,
    this.isChecked = false,
    this.calloutIcon = '💡',
    this.calloutColor = 'gray',
    this.codeLanguage = '',
    this.numberIndex,
    this.tableData,
  });

  NotionBlock copyWith({
    String? id,
    BlockType? type,
    String? text,
    bool? isChecked,
    String? calloutIcon,
    String? calloutColor,
    String? codeLanguage,
    int? numberIndex,
    List<List<String>>? tableData,
  }) {
    return NotionBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
      calloutIcon: calloutIcon ?? this.calloutIcon,
      calloutColor: calloutColor ?? this.calloutColor,
      codeLanguage: codeLanguage ?? this.codeLanguage,
      numberIndex: numberIndex ?? this.numberIndex,
      tableData: tableData ?? this.tableData,
    );
  }

  /// Serialize this single block back to markdown line(s)
  String toMarkdown() {
    switch (type) {
      case BlockType.heading1:
        return '# $text';
      case BlockType.heading2:
        return '## $text';
      case BlockType.heading3:
        return '### $text';
      case BlockType.todo:
        return '- [${isChecked ? 'x' : ' '}] $text';
      case BlockType.bullet:
        return '- $text';
      case BlockType.numbered:
        return '${numberIndex ?? 1}. $text';
      case BlockType.callout:
        return '> [!NOTE]\n> $calloutIcon $text';
      case BlockType.quote:
        return '> $text';
      case BlockType.code:
        return '```$codeLanguage\n$text\n```';
      case BlockType.divider:
        return '---';
      case BlockType.table:
        if (tableData == null || tableData!.isEmpty) return '';
        final buf = StringBuffer();
        for (int r = 0; r < tableData!.length; r++) {
          final row = tableData![r];
          buf.writeln('| ${row.join(' | ')} |');
          if (r == 0) {
            buf.writeln('| ${row.map((_) => '---').join(' | ')} |');
          }
        }
        return buf.toString().trimRight();
      case BlockType.paragraph:
        return text;
    }
  }
}

/// Robust bi-directional parser between raw Markdown and Notion blocks
class BlockParser {
  static int _idCounter = 0;
  static String _genId() => 'block_${DateTime.now().millisecondsSinceEpoch}_${++_idCounter}';

  /// Parse Markdown text into NotionBlocks
  static List<NotionBlock> parseMarkdown(String markdown) {
    final List<NotionBlock> blocks = [];
    final lines = markdown.split('\n');

    int i = 0;
    int currentNumberIndex = 1;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // Empty line -> empty paragraph block
      if (trimmed.isEmpty) {
        // Only add if previous wasn't also empty
        if (blocks.isNotEmpty && blocks.last.text.isNotEmpty) {
          blocks.add(NotionBlock(
            id: _genId(),
            type: BlockType.paragraph,
            text: '',
          ));
        }
        i++;
        continue;
      }

      // Code Block ```lang ... ```
      if (trimmed.startsWith('```')) {
        final lang = trimmed.substring(3).trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length && lines[i].trim().startsWith('```')) {
          i++; // skip closing ```
        }
        blocks.add(NotionBlock(
          id: _genId(),
          type: BlockType.code,
          text: codeLines.join('\n'),
          codeLanguage: lang.isEmpty ? 'text' : lang,
        ));
        continue;
      }

      // Markdown Table (| Col 1 | Col 2 |)
      if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
        final tableRows = <List<String>>[];
        while (i < lines.length && lines[i].trim().startsWith('|') && lines[i].trim().endsWith('|')) {
          final rowStr = lines[i].trim();
          // Skip divider row |---|---|
          if (!rowStr.contains('---')) {
            final cells = rowStr
                .substring(1, rowStr.length - 1)
                .split('|')
                .map((c) => c.trim())
                .toList();
            tableRows.add(cells);
          }
          i++;
        }
        if (tableRows.isNotEmpty) {
          blocks.add(NotionBlock(
            id: _genId(),
            type: BlockType.table,
            text: '',
            tableData: tableRows,
          ));
        }
        continue;
      }

      // Divider --- or *** or ___
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        blocks.add(NotionBlock(
          id: _genId(),
          type: BlockType.divider,
          text: '',
        ));
        i++;
        continue;
      }

      // Headings
      if (trimmed.startsWith('### ')) {
        blocks.add(NotionBlock(
          id: _genId(),
          type: BlockType.heading3,
          text: trimmed.substring(4).trim(),
        ));
        i++;
        continue;
      }
      if (trimmed.startsWith('## ')) {
        blocks.add(NotionBlock(
          id: _genId(),
          type: BlockType.heading2,
          text: trimmed.substring(3).trim(),
        ));
        i++;
        continue;
      }
      if (trimmed.startsWith('# ')) {
        blocks.add(NotionBlock(
          id: _genId(),
          type: BlockType.heading1,
          text: trimmed.substring(2).trim(),
        ));
        i++;
        continue;
      }

      // Checkbox / Todo: - [ ] or - [x] or * [ ] or * [x]
      final todoMatch = RegExp(r'^[-*]\s*\[([ xX])\]\s*(.*)$').firstMatch(trimmed);
      if (todoMatch != null) {
        final isChecked = todoMatch.group(1)?.toLowerCase() == 'x';
        final text = todoMatch.group(2) ?? '';
        blocks.add(NotionBlock(
          id: _genId(),
          type: BlockType.todo,
          text: text,
          isChecked: isChecked,
        ));
        i++;
        continue;
      }

      // Bullet List: - item or * item
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        blocks.add(NotionBlock(
          id: _genId(),
          type: BlockType.bullet,
          text: trimmed.substring(2).trim(),
        ));
        i++;
        continue;
      }

      // Numbered List: 1. item
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        final idx = int.tryParse(numMatch.group(1) ?? '1') ?? currentNumberIndex;
        final text = numMatch.group(2) ?? '';
        blocks.add(NotionBlock(
          id: _genId(),
          type: BlockType.numbered,
          text: text,
          numberIndex: idx,
        ));
        currentNumberIndex = idx + 1;
        i++;
        continue;
      } else {
        currentNumberIndex = 1;
      }

      // Callouts / Blockquotes
      if (trimmed.startsWith('>')) {
        // Check for Obsidian / GitHub callout syntax: > [!NOTE] or > [!TIP]
        String quoteContent = trimmed.substring(1).trim();
        if (quoteContent.startsWith('[!') && quoteContent.contains(']')) {
          final closeIdx = quoteContent.indexOf(']');
          final calloutType = quoteContent.substring(2, closeIdx).toLowerCase();
          
          String icon = '💡';
          String color = 'blue';
          if (calloutType == 'tip' || calloutType == 'idea') {
            icon = '💡';
            color = 'yellow';
          } else if (calloutType == 'warning' || calloutType == 'caution') {
            icon = '⚠️';
            color = 'orange';
          } else if (calloutType == 'important' || calloutType == 'danger') {
            icon = '🚨';
            color = 'pink';
          } else if (calloutType == 'success' || calloutType == 'done') {
            icon = '✅';
            color = 'green';
          }

          // Next line might have text
          i++;
          final textLines = <String>[];
          while (i < lines.length && lines[i].trim().startsWith('>')) {
            String c = lines[i].trim().substring(1).trim();
            // check if there's leading emoji
            if (textLines.isEmpty && c.startsWith(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true))) {
              final emoji = c.substring(0, 2).trim();
              if (emoji.isNotEmpty) icon = emoji;
              c = c.substring(2).trim();
            }
            textLines.add(c);
            i++;
          }
          blocks.add(NotionBlock(
            id: _genId(),
            type: BlockType.callout,
            text: textLines.join('\n'),
            calloutIcon: icon,
            calloutColor: color,
          ));
          continue;
        }

        // Check if quote contains an emoji for Notion callout style
        final firstEmojiMatch = RegExp(r'^([\u{1F300}-\u{1F9FF}|💡|📌|🚀|⚠️|✅|🔥|⭐|🎯])\s*(.*)$', unicode: true).firstMatch(quoteContent);
        if (firstEmojiMatch != null) {
          final icon = firstEmojiMatch.group(1) ?? '💡';
          final text = firstEmojiMatch.group(2) ?? '';
          blocks.add(NotionBlock(
            id: _genId(),
            type: BlockType.callout,
            text: text,
            calloutIcon: icon,
            calloutColor: 'yellow',
          ));
          i++;
          continue;
        }

        // Standard Quote
        blocks.add(NotionBlock(
          id: _genId(),
          type: BlockType.quote,
          text: quoteContent,
        ));
        i++;
        continue;
      }

      // Default: Paragraph
      blocks.add(NotionBlock(
        id: _genId(),
        type: BlockType.paragraph,
        text: trimmed,
      ));
      i++;
    }

    if (blocks.isEmpty) {
      blocks.add(NotionBlock(
        id: _genId(),
        type: BlockType.paragraph,
        text: '',
      ));
    }

    return blocks;
  }

  /// Serialize list of NotionBlocks back to clean Markdown
  static String blocksToMarkdown(List<NotionBlock> blocks) {
    final buffer = StringBuffer();
    for (int i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      buffer.writeln(b.toMarkdown());
      // Add newline after headings, dividers, code blocks, tables, callouts
      if (b.type == BlockType.heading1 ||
          b.type == BlockType.heading2 ||
          b.type == BlockType.heading3 ||
          b.type == BlockType.divider ||
          b.type == BlockType.code ||
          b.type == BlockType.callout ||
          b.type == BlockType.table) {
        buffer.writeln();
      }
    }
    return buffer.toString().trim();
  }
}
