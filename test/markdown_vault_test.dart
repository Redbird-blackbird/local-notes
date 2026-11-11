import 'package:flutter_test/flutter_test.dart';
import 'package:local_notes/models/block_model.dart';
import 'package:local_notes/models/note_file.dart';

void main() {
  group('NoteFile Tests', () {
    test('parses markdown with YAML frontmatter correctly', () {
      const rawMarkdown = '''---
title: "My Custom Note"
icon: "🚀"
cover: "gradient_space"
favorite: true
tags: ["obsidian", "flutter", "notion"]
---

# Hello World
This is pure local markdown.
''';

      final note = NoteFile.fromMarkdown(
        path: 'Projects/My Custom Note.md',
        rawContent: rawMarkdown,
      );

      expect(note.title, equals('My Custom Note'));
      expect(note.folder, equals('Projects'));
      expect(note.icon, equals('🚀'));
      expect(note.coverUrl, equals('gradient_space'));
      expect(note.isFavorite, isTrue);
      expect(note.tags, containsAll(['obsidian', 'flutter', 'notion']));
      expect(note.content.contains('Hello World'), isTrue);
    });

    test('re-serializes back to clean markdown with frontmatter', () {
      final note = NoteFile(
        id: 'Projects/Test.md',
        path: 'Projects/Test.md',
        title: 'Roadmap',
        content: '# Roadmap Content\n\nSome body text.',
        folder: 'Projects',
        icon: '🎯',
        coverUrl: 'gradient_sand',
        isFavorite: true,
        tags: ['strategy'],
      );

      final serialized = note.toFullMarkdown();
      expect(serialized, contains('---'));
      expect(serialized, contains('title: "Roadmap"'));
      expect(serialized, contains('icon: "🎯"'));
      expect(serialized, contains('cover: "gradient_sand"'));
      expect(serialized, contains('favorite: true'));
      expect(serialized, contains('tags: ["strategy"]'));
      expect(serialized, contains('# Roadmap Content'));
    });
  });

  group('BlockParser Tests', () {
    test('parses interactive todos, headings, and quotes correctly', () {
      const sample = '''# Main Title
## Section Two
- [ ] Uncompleted task
- [x] Completed task
> [!NOTE]
> 💡 This is a Notion callout box
> A simple blockquote
---
```dart
void main() => print("test");
```
''';

      final blocks = BlockParser.parseMarkdown(sample);
      expect(blocks.length, greaterThanOrEqualTo(7));

      final h1 = blocks.firstWhere((b) => b.type == BlockType.heading1);
      expect(h1.text, equals('Main Title'));

      final h2 = blocks.firstWhere((b) => b.type == BlockType.heading2);
      expect(h2.text, equals('Section Two'));

      final todoUnchecked = blocks.firstWhere((b) => b.type == BlockType.todo && !b.isChecked);
      expect(todoUnchecked.text, equals('Uncompleted task'));

      final todoChecked = blocks.firstWhere((b) => b.type == BlockType.todo && b.isChecked);
      expect(todoChecked.text, equals('Completed task'));

      final callout = blocks.firstWhere((b) => b.type == BlockType.callout);
      expect(callout.calloutIcon, equals('💡'));

      final codeBlock = blocks.firstWhere((b) => b.type == BlockType.code);
      expect(codeBlock.codeLanguage, equals('dart'));
      expect(codeBlock.text, contains('void main()'));
    });

    test('bi-directional round-trip conversion preserves content', () {
      final blocks = [
        NotionBlock(id: '1', type: BlockType.heading1, text: 'Top Level'),
        NotionBlock(id: '2', type: BlockType.todo, text: 'Check me', isChecked: true),
        NotionBlock(id: '3', type: BlockType.paragraph, text: 'Clean text paragraph.'),
      ];

      final markdown = BlockParser.blocksToMarkdown(blocks);
      expect(markdown, contains('# Top Level'));
      expect(markdown, contains('- [x] Check me'));
      expect(markdown, contains('Clean text paragraph.'));

      final reparsed = BlockParser.parseMarkdown(markdown);
      expect(reparsed.any((b) => b.type == BlockType.heading1 && b.text == 'Top Level'), isTrue);
      expect(reparsed.any((b) => b.type == BlockType.todo && b.isChecked && b.text == 'Check me'), isTrue);
    });
  });
}
