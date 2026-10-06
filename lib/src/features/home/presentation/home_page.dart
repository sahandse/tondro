import 'package:flutter/material.dart';

import '../../downloads/domain/download_category.dart';
import '../../downloads/domain/download_item.dart';
import '../../downloads/presentation/downloads_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final DownloadsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DownloadsController()..addListener(_refresh);
    _controller.init();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _showAddDownload() async {
    final input = TextEditingController();
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'دانلود جدید',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: input,
              autofocus: true,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                hintText: 'https://example.com/file.zip',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, input.text.trim()),
              icon: const Icon(Icons.download_rounded),
              label: const Text('شروع دانلود'),
            ),
          ],
        ),
      ),
    );
    input.dispose();

    if (url == null || url.isEmpty) return;
    try {
      await _controller.addUrl(url);
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _controller.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تندرو'),
        actions: [
          IconButton(
            tooltip: 'تنظیمات',
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDownload,
        icon: const Icon(Icons.add_rounded),
        label: const Text('دانلود جدید'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'دانلودها',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'سریع، مرتب و بدون شلوغی',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: _controller.loading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? const _EmptyDownloads()
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => _DownloadCard(
                              item: items[index],
                              onPause: () => _controller.pause(items[index].id),
                              onResume: () => _controller.start(items[index].id),
                              onDelete: () => _controller.remove(items[index].id),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.download_rounded,
                size: 48,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'هنوز دانلودی نداری',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'لینک دانلود را اضافه کن تا تندرو مدیریت بقیه کار را انجام دهد.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.8,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  const _DownloadCard({
    required this.item,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
  });

  final DownloadItem item;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = item.status == DownloadStatus.downloading;
    final isDone = item.status == DownloadStatus.completed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : Icons.downloading_rounded,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(item),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: item.totalBytes > 0 ? item.progress.clamp(0, 1) : null,
              borderRadius: BorderRadius.circular(99),
              minHeight: 7,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  item.totalBytes > 0 ? '${(item.progress * 100).clamp(0, 100).toStringAsFixed(0)}٪' : 'در حال اتصال…',
                  style: theme.textTheme.labelMedium,
                ),
                const Spacer(),
                if (!isDone)
                  IconButton.filledTonal(
                    tooltip: isRunning ? 'توقف' : 'ادامه',
                    onPressed: isRunning ? onPause : onResume,
                    icon: Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(DownloadItem item) {
    final status = _statusLabel(item.status);
    final category = categoryLabelFa(detectDownloadCategory(item.fileName));
    if (item.status != DownloadStatus.downloading) return '$status • $category';

    final speed = _formatSpeed(item.speedBytesPerSecond);
    final eta = _formatEta(item.eta);
    if (speed == null) return status;
    return eta == null
        ? '$status • $category • $speed'
        : '$status • $category • $speed • $eta مانده';
  }

  String _statusLabel(DownloadStatus status) => switch (status) {
        DownloadStatus.queued => 'در صف',
        DownloadStatus.downloading => 'در حال دانلود',
        DownloadStatus.paused => 'متوقف شده',
        DownloadStatus.completed => 'تکمیل شده',
        DownloadStatus.failed => 'ناموفق',
      };

  String? _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return null;
    if (bytesPerSecond >= 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    if (bytesPerSecond >= 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(0)} KB/s';
    }
    return '${bytesPerSecond.toStringAsFixed(0)} B/s';
  }

  String? _formatEta(Duration? duration) {
    if (duration == null) return null;
    if (duration.inHours > 0) {
      return '${duration.inHours}س ${duration.inMinutes.remainder(60)}د';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}د ${duration.inSeconds.remainder(60)}ث';
    }
    return '${duration.inSeconds}ث';
  }
}
