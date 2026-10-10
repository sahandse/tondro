import 'package:flutter/material.dart';

import '../../downloads/domain/download_category.dart';
import '../../downloads/domain/download_item.dart';
import '../../downloads/presentation/downloads_controller.dart';

class FileLibraryPage extends StatefulWidget {
  const FileLibraryPage({
    super.key,
    required this.controller,
  });

  final DownloadsController controller;

  @override
  State<FileLibraryPage> createState() => _FileLibraryPageState();
}

class _FileLibraryPageState extends State<FileLibraryPage> {
  DownloadCategory? _category;

  @override
  Widget build(BuildContext context) {
    final completed = widget.controller.items
        .where((item) => item.status == DownloadStatus.completed)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final visible = _category == null
        ? completed
        : completed
            .where(
              (item) => detectDownloadCategory(item.fileName) == _category,
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('فایل‌های من'),
      ),
      body: completed.isEmpty
          ? const _EmptyLibrary()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: _CategoryGrid(
                      items: completed,
                      selected: _category,
                      onSelected: (value) => setState(() {
                        _category = _category == value ? null : value;
                      }),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _category == null
                                ? 'همه فایل‌ها'
                                : categoryLabelFa(_category!),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${visible.length} فایل',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 68,
                  ),
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    final category = detectDownloadCategory(item.fileName);
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_categoryIcon(category), size: 21),
                      ),
                      title: Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                      ),
                      subtitle: Text(
                        categoryLabelFa(category),
                        maxLines: 1,
                      ),
                      onTap: () => widget.controller.openFile(item.id),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'open') {
                            await widget.controller.openFile(item.id);
                          }
                          if (value == 'share') {
                            await widget.controller.shareFile(item.id);
                          }
                          if (value == 'delete') {
                            await widget.controller.remove(item.id);
                            if (mounted) setState(() {});
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'open',
                            child: Text('باز کردن'),
                          ),
                          PopupMenuItem(
                            value: 'share',
                            child: Text('اشتراک‌گذاری'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('حذف'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<DownloadItem> items;
  final DownloadCategory? selected;
  final ValueChanged<DownloadCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = DownloadCategory.values.where((category) {
      return items.any(
        (item) => detectDownloadCategory(item.fileName) == category,
      );
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 82,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final count = items
            .where(
              (item) => detectDownloadCategory(item.fileName) == category,
            )
            .length;
        final active = selected == category;
        return InkWell(
          onTap: () => onSelected(category),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: .45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_categoryIcon(category), size: 20),
                const Spacer(),
                Text(
                  categoryLabelFa(category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open_rounded, size: 54),
            const SizedBox(height: 14),
            Text(
              'هنوز فایلی دانلود نشده',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'بعد از دانلود، فایل‌ها خودکار داخل Downloads/Tondro دسته‌بندی می‌شوند.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(DownloadCategory category) => switch (category) {
      DownloadCategory.image => Icons.image_outlined,
      DownloadCategory.video => Icons.movie_outlined,
      DownloadCategory.audio => Icons.music_note_rounded,
      DownloadCategory.document => Icons.description_outlined,
      DownloadCategory.book => Icons.menu_book_outlined,
      DownloadCategory.archive => Icons.inventory_2_outlined,
      DownloadCategory.app => Icons.android_rounded,
      DownloadCategory.font => Icons.font_download_outlined,
      DownloadCategory.other => Icons.insert_drive_file_outlined,
    };