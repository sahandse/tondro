import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../app/widgets/tondro_brand.dart';

import '../../downloads/domain/download_category.dart';
import '../../downloads/domain/download_item.dart';
import '../../downloads/presentation/downloads_controller.dart';
import '../../downloads/presentation/new_download_sheet.dart';
import '../../settings/presentation/download_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final DownloadsController _controller;
  StreamSubscription<List<SharedMediaFile>>? _shareSub;
  String? _lastClipboardUrl;
  String _filter = 'all';
  String _sort = 'newest';
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DownloadsController()..addListener(_refresh);
    unawaited(_controller.init().then((_) async {
      if (!mounted) return;
      await _checkInitialShare();
      await _checkClipboard();
    }));
    _shareSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleSharedMedia,
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_shareSub?.cancel());
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkClipboard());
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _checkInitialShare() async {
    try {
      final values = await ReceiveSharingIntent.instance.getInitialMedia();
      await _handleSharedMedia(values);
      await ReceiveSharingIntent.instance.reset();
    } catch (_) {}
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> values) async {
    for (final media in values) {
      if (media.type != SharedMediaType.url &&
          media.type != SharedMediaType.text) {
        continue;
      }
      final url = _extractUrl(media.path);
      if (url == null) continue;
      _lastClipboardUrl = url;
      if (!mounted) return;
      await _showAddDownload(initialUrl: url);
      break;
    }
  }

  Future<void> _checkClipboard() async {
    if (!_controller.settings.clipboardDetection || !mounted) return;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final url = _extractUrl(data?.text ?? '');
      if (url == null || url == _lastClipboardUrl || !mounted) return;
      _lastClipboardUrl = url;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('لینک دانلود در Clipboard پیدا شد'),
            action: SnackBarAction(
              label: 'دانلود',
              onPressed: () => unawaited(_showAddDownload(initialUrl: url)),
            ),
          ),
        );
    } catch (_) {}
  }

  String? _extractUrl(String value) {
    final match =
        RegExp(r'https?://[^\s]+', caseSensitive: false).firstMatch(value);
    if (match == null) return null;

    final matchedUrl = match.group(0);
    if (matchedUrl == null) return null;
    var url = matchedUrl;
    const trailing = [')', ']', '}', '>', ',', '،', '؛'];
    while (url.isNotEmpty && trailing.contains(url[url.length - 1])) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
  Future<void> _showAddDownload({String? initialUrl}) async {
    final request = await showModalBottomSheet<NewDownloadRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => NewDownloadSheet(initialUrl: initialUrl),
    );

    if (request == null || request.url.isEmpty) return;
    try {
      await _controller.addUrl(
        request.url,
        scheduledAt: request.scheduledAt,
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
  Widget _filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  List<DownloadItem> _visibleItems(List<DownloadItem> source) {
    final list = source.where((item) {
      final category = detectDownloadCategory(item.fileName);
      return switch (_filter) {
        'active' => item.status == DownloadStatus.downloading || item.status == DownloadStatus.queued,
        'completed' => item.status == DownloadStatus.completed,
        'image' => category == DownloadCategory.image,
        'video' => category == DownloadCategory.video,
        'audio' => category == DownloadCategory.audio,
        'document' => category == DownloadCategory.document,
        'archive' => category == DownloadCategory.archive,
        _ => true,
      };
    }).toList();

    switch (_sort) {
      case 'oldest':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'name':
        list.sort((a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
      case 'size':
        list.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _visibleItems(_controller.items);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const TondroLogo(size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تندرو', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, height: 1.05)),
                Text('XP MONO', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.8, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تنظیمات',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DownloadSettingsPage(controller: _controller),
                ),
              );
              if (mounted) setState(() {});
            },
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
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('all', 'همه'),
                    _filterChip('active', 'فعال'),
                    _filterChip('completed', 'تکمیل‌شده'),
                    _filterChip('image', 'تصویر'),
                    _filterChip('video', 'ویدیو'),
                    _filterChip('audio', 'صوت'),
                    _filterChip('document', 'سند'),
                    _filterChip('archive', 'آرشیو'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: PopupMenuButton<String>(
                  tooltip: 'مرتب‌سازی',
                  initialValue: _sort,
                  onSelected: (value) => setState(() => _sort = value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'newest', child: Text('جدیدترین')),
                    PopupMenuItem(value: 'oldest', child: Text('قدیمی‌ترین')),
                    PopupMenuItem(value: 'name', child: Text('نام فایل')),
                    PopupMenuItem(value: 'size', child: Text('حجم فایل')),
                  ],
                  child: const Chip(
                    avatar: Icon(Icons.sort_rounded, size: 18),
                    label: Text('مرتب‌سازی'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                              onOpen: () async {
                                HapticFeedback.selectionClick();
                                final opened = await _controller.openFile(items[index].id);
                                if (!opened && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('فایل قابل باز شدن نیست.'),
                                    ),
                                  );
                                }
                              },
                              onPause: () {
                                HapticFeedback.lightImpact();
                                unawaited(_controller.pause(items[index].id));
                              },
                              onResume: () {
                                HapticFeedback.lightImpact();
                                unawaited(_controller.start(items[index].id));
                              },
                              onDelete: () {
                                HapticFeedback.mediumImpact();
                                unawaited(_controller.remove(items[index].id));
                              },
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
              'لینک را اضافه کن، کپی کن یا از مرورگر برای تندرو Share کن.',
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
    required this.onOpen,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
  });

  final DownloadItem item;
  final VoidCallback onOpen;
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
                    if (value == 'open') onOpen();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    if (isDone)
                      const PopupMenuItem(
                        value: 'open',
                        child: Text('باز کردن'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف'),
                    ),
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
    if (item.scheduledAt != null &&
        item.scheduledAt!.isAfter(DateTime.now())) {
      return 'زمان‌بندی • $category • ${formatDownloadDateTime(item.scheduledAt!)}';
    }
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
