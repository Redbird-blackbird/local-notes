/// Represents a Markdown note inside an Obsidian or Local Notes vault.
/// Preserves markdown integrity, Obsidian frontmatter, tags, and Notion metadata.
class NoteFile {
  String id;
  String title;
  String content;
  String path;
  String folder;
  String icon;
  String? coverUrl;
  bool isFavorite;
  DateTime lastModified;
  List<String> tags;

  NoteFile({
    required this.id,
    required this.title,
    required this.content,
    required this.path,
    this.folder = 'Root',
    this.icon = '📄',
    this.coverUrl,
    this.isFavorite = false,
    DateTime? lastModified,
    List<String>? tags,
  })  : lastModified = lastModified ?? DateTime.now(),
        tags = tags ?? [];

  /// Calculate word count
  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  /// Calculate reading time (avg 200 wpm)
  String get readingTime {
    final words = wordCount;
    final minutes = (words / 200).ceil();
    if (minutes <= 1) return '1 min read';
    return '$minutes min read';
  }

  /// Create a NoteFile from markdown text and path, extracting frontmatter if present
  factory NoteFile.fromMarkdown({
    required String path,
    required String rawContent,
    DateTime? lastModified,
  }) {
    // Determine folder from path
    final normalizedPath = path.replaceAll('\\', '/');
    final segments = normalizedPath.split('/');
    final filename = segments.isNotEmpty ? segments.last : 'Untitled.md';
    String title = filename.replaceAll(RegExp(r'\.(md|markdown|txt)$'), '');
    String folder = segments.length > 1 ? segments[segments.length - 2] : 'Root';

    String icon = '📄';
    String? coverUrl;
    List<String> tags = [];
    bool isFavorite = false;
    String cleanContent = rawContent;

    // Check for Obsidian / YAML frontmatter --- ... ---
    if (rawContent.startsWith('---')) {
      final endIdx = rawContent.indexOf('---', 3);
      if (endIdx != -1) {
        final frontmatterStr = rawContent.substring(3, endIdx).trim();
        cleanContent = rawContent.substring(endIdx + 3).trim();

        for (final line in frontmatterStr.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('title:')) {
            final val = trimmed.substring(6).trim().replaceAll('"', '').replaceAll("'", "");
            if (val.isNotEmpty) title = val;
          } else if (trimmed.startsWith('icon:')) {
            final val = trimmed.substring(5).trim().replaceAll('"', '').replaceAll("'", "");
            if (val.isNotEmpty) icon = val;
          } else if (trimmed.startsWith('cover:')) {
            final val = trimmed.substring(6).trim().replaceAll('"', '').replaceAll("'", "");
            if (val.isNotEmpty) coverUrl = val;
          } else if (trimmed.startsWith('favorite:')) {
            final val = trimmed.substring(9).trim().toLowerCase();
            isFavorite = val == 'true';
          } else if (trimmed.startsWith('tags:')) {
            final val = trimmed.substring(5).trim();
            if (val.startsWith('[') && val.endsWith(']')) {
              tags = val
                  .substring(1, val.length - 1)
                  .split(',')
                  .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ""))
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
          }
        }
      }
    }

    // Default icons based on title or folder if still default
    if (icon == '📄') {
      final lowerTitle = title.toLowerCase();
      if (lowerTitle.contains('project') || lowerTitle.contains('roadmap')) {
        icon = '🚀';
      } else if (lowerTitle.contains('idea') || lowerTitle.contains('brainstorm')) {
        icon = '💡';
      } else if (lowerTitle.contains('book') || lowerTitle.contains('read') || lowerTitle.contains('wiki')) {
        icon = '📚';
      } else if (lowerTitle.contains('daily') || lowerTitle.contains('journal')) {
        icon = '☕';
      } else if (lowerTitle.contains('task') || lowerTitle.contains('todo')) {
        icon = '🎯';
      } else if (lowerTitle.contains('meeting') || lowerTitle.contains('notes')) {
        icon = '📋';
      } else if (lowerTitle.contains('design') || lowerTitle.contains('ui')) {
        icon = '🎨';
      } else if (lowerTitle.contains('code') || lowerTitle.contains('architecture')) {
        icon = '💻';
      }
    }

    return NoteFile(
      id: normalizedPath,
      title: title,
      content: cleanContent,
      path: normalizedPath,
      folder: folder,
      icon: icon,
      coverUrl: coverUrl,
      isFavorite: isFavorite,
      lastModified: lastModified ?? DateTime.now(),
      tags: tags,
    );
  }

  /// Serialize note back to full markdown including Obsidian-compatible frontmatter
  String toFullMarkdown() {
    final buffer = StringBuffer();
    final hasMetadata = icon != '📄' || coverUrl != null || isFavorite || tags.isNotEmpty;
    if (hasMetadata) {
      buffer.writeln('---');
      buffer.writeln('title: "$title"');
      if (icon != '📄') buffer.writeln('icon: "$icon"');
      if (coverUrl != null) buffer.writeln('cover: "$coverUrl"');
      if (isFavorite) buffer.writeln('favorite: true');
      if (tags.isNotEmpty) {
        buffer.writeln('tags: [${tags.map((t) => '"$t"').join(', ')}]');
      }
      buffer.writeln('---');
      buffer.writeln();
    }
    buffer.write(content);
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'path': path,
        'folder': folder,
        'icon': icon,
        'coverUrl': coverUrl,
        'isFavorite': isFavorite,
        'lastModified': lastModified.toIso8601String(),
        'tags': tags,
      };

  factory NoteFile.fromJson(Map<String, dynamic> json) => NoteFile(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        path: json['path'] as String,
        folder: json['folder'] as String? ?? 'Root',
        icon: json['icon'] as String? ?? '📄',
        coverUrl: json['coverUrl'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
        lastModified: json['lastModified'] != null
            ? DateTime.tryParse(json['lastModified'] as String) ?? DateTime.now()
            : DateTime.now(),
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );

  NoteFile copyWith({
    String? id,
    String? title,
    String? content,
    String? path,
    String? folder,
    String? icon,
    String? coverUrl,
    bool? isFavorite,
    DateTime? lastModified,
    List<String>? tags,
  }) {
    return NoteFile(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      path: path ?? this.path,
      folder: folder ?? this.folder,
      icon: icon ?? this.icon,
      coverUrl: coverUrl ?? this.coverUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      lastModified: lastModified ?? this.lastModified,
      tags: tags ?? this.tags,
    );
  }
}
