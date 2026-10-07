import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../app/widgets/tondro_brand.dart';

import '../../browser/domain/media_detector.dart';
import '../../browser/presentation/browser_page.dart';
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
  StreamSubscription<Uri?>? _widgetClickSub;
  String? _lastClipboardUrl;
  String _filter = 'all';
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DownloadsController()..addListener(_refresh);
    _widgetClickSub = _controller.widgetClicks.listen(
      (uri) => unawaited(_controller.handleWidgetAction(uri)),
    );
    unawaited(_controller.init().then((_) async {
      final widgetLaunch = await _controller.initialWidgetLaunch();
      await _controller.handleWidgetAction(widgetLaunch);
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
    unawaited(_widgetClickSub?.cancel());
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
      await _handleIncomingUrl(url);
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
              label: MediaDetector.isSupportedSocialPage(url) ? 'باز کردن' : 'دانلود',
              onPressed: () => unawaited(_handleIncomingUrl(url)),
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
  Future<void> _handleIncomingUrl(String url) async {
    if (MediaDetector.isDirectDownloadUrl(url)) {
      await _showAddDownload(initialUrl: url);
      return;
    }

    if (MediaDetector.isSupportedSocialPage(url)) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BrowserPage(
            downloadsController: _controller,
            initialUrl: url,
          ),
        ),
      );
      return;
    }

    await _showAddDownload(initialUrl: url);
  }

  Future<void> _showAddDownload({String? initialUrl}) async {
    final request = await showModalBottomSheet<NewDownloadRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => NewDownloadSheet(
        controller: _controller,
        initialUrl: initialUrl,
      ),
    );

    if (request == null || request.url.isEmpty) return;
    try {
      await _controller.addUrl(
        request.url,
        scheduledAt: request.scheduledAt,
        customFolder: request.customFolder,
        duplicatePolicy: request.duplicatePolicy,
        expectedSha256: request.expectedSha256,
        inspection: request.inspection,
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
  List<DownloadItem> _visibleItems(List<DownloadItem> source) {
    final list = source.where((item) {
      final category = detectDownloadCategory(item.fileName);
      return switch (_filter) {
        'active' => item.status == DownloadStatus.downloading || item.status == DownloadStatus.queued,
        'completed' => item.status == DownloadStatus.completed,
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
    final allItems = _controller.items;
    final items = _visibleItems(allItems);
    final activeCount = allItems
        .where((item) => item.status == DownloadStatus.downloading)
        .length;
    final queuedCount = allItems
        .where((item) => item.status == DownloadStatus.queued)
        .length;
    final totalSpeed = allItems
        .where((item) => item.status == DownloadStatus.downloading)
        .fold<double>(0, (sum, item) => sum + item.speedBytesPerSecond);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'تندرو',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'بیشتر',
            onSelected: (value) async {
              if (value == 'browser') {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BrowserPage(
                      downloadsController: _controller,
                    ),
                  ),
                );
              }
              if (value == 'settings') {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        DownloadSettingsPage(controller: _controller),
                  ),
                );
                if (mounted) setState(() {});
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'browser',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.public_rounded),
                  title: Text('مرورگر'),
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.tune_rounded),
                  title: Text('تنظیمات'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'دانلود جدید',
        onPressed: _showAddDownload,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: activeCount > 0
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activeCount > 0
                          ? '$activeCount دانلود فعال'
                          : queuedCount > 0
                              ? '$queuedCount دانلود در صف'
                              : 'آماده برای دانلود',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (totalSpeed > 0)
                    Text(
                      _formatTotalSpeed(totalSpeed),
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  PopupMenuButton<String>(
                    tooltip: 'مرتب‌سازی',
                    initialValue: _sort,
                    onSelected: (value) => setState(() => _sort = value),
                    icon: const Icon(Icons.sort_rounded, size: 21),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'newest',
                        child: Text('جدیدترین'),
                      ),
                      PopupMenuItem(
                        value: 'oldest',
                        child: Text('قدیمی‌ترین'),
                      ),
                      PopupMenuItem(
                        value: 'name',
                        child: Text('نام فایل'),
                      ),
                      PopupMenuItem(
                        value: 'size',
                        child: Text('حجم فایل'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'all',
                    label: Text('همه'),
                  ),
                  ButtonSegment(
                    value: 'active',
                    label: Text('فعال'),
                  ),
                  ButtonSegment(
                    value: 'completed',
                    label: Text('تمام‌شده'),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (value) {
                  setState(() => _filter = value.first);
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _controller.loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? const _EmptyDownloads()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) => _DownloadCard(
                            item: items[index],
                            onOpen: () async {
                              HapticFeedback.selectionClick();
                              final opened =
                                  await _controller.openFile(items[index].id);
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
                              unawaited(
                                _controller.pause(items[index].id),
                              );
                            },
                            onResume: () {
                              HapticFeedback.lightImpact();
                              unawaited(
                                _controller.start(items[index].id),
                              );
                            },
                            onShare: () async {
                              HapticFeedback.selectionClick();
                              final shared =
                                  await _controller.shareFile(items[index].id);
                              if (!shared && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('فایل قابل اشتراک‌گذاری نیست.'),
                                  ),
                                );
                              }
                            },
                            onChecksum: () async {
                              final hash = await _controller
                                  .calculateSha256(items[index].id);
                              if (hash == null || !context.mounted) return;
                              await Clipboard.setData(
                                ClipboardData(text: hash),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('SHA-256 کپی شد'),
                                ),
                              );
                            },
                            onDelete: () {
                              HapticFeedback.mediumImpact();
                              unawaited(
                                _controller.remove(items[index].id),
                              );
                            },
                          ),
                        ),
            ),
          ],
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
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Icon(
                Icons.download_for_offline_outlined,
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
    required this.onShare,
    required this.onChecksum,
    required this.onDelete,
  });

  final DownloadItem item;
  final VoidCallback onOpen;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onShare;
  final VoidCallback onChecksum;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = item.status == DownloadStatus.downloading;
    final isDone = item.status == DownloadStatus.completed;

    return XpWindowFrame(
      title: _xpStatusLabel(item.status),
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
                    _downloadTypeIcon(item.fileName, isDone: isDone, failed: item.status == DownloadStatus.failed),
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
                    if (value == 'share') onShare();
                    if (value == 'checksum') onChecksum();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    if (isDone)
                      const PopupMenuItem(
                        value: 'open',
                        child: Text('باز کردن'),
                      ),
                    if (isDone)
                      const PopupMenuItem(
                        value: 'share',
                        child: Text('اشتراک‌گذاری'),
                      ),
                    if (isDone)
                      const PopupMenuItem(
                        value: 'checksum',
                        child: Text('SHA-256'),
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
              minHeight: 10,
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


class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? .35 : .12),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 19),
          const SizedBox(height: 5),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

String _formatTotalSpeed(double bytesPerSecond) {
  if (bytesPerSecond >= 1024 * 1024) {
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
  if (bytesPerSecond >= 1024) {
    return '${(bytesPerSecond / 1024).toStringAsFixed(0)} KB/s';
  }
  return '${bytesPerSecond.toStringAsFixed(0)} B/s';
}


String _xpStatusLabel(DownloadStatus status) => switch (status) {
      DownloadStatus.queued => 'Queued',
      DownloadStatus.downloading => 'Downloading...',
      DownloadStatus.paused => 'Paused',
      DownloadStatus.completed => 'Completed',
      DownloadStatus.failed => 'Error',
    };

IconData _downloadTypeIcon(
  String fileName, {
  required bool isDone,
  required bool failed,
}) {
  if (failed) return Icons.warning_amber_rounded;
  if (isDone) return Icons.check_box_outlined;
  return switch (detectDownloadCategory(fileName)) {
    DownloadCategory.image => Icons.image_outlined,
    DownloadCategory.video => Icons.movie_outlined,
    DownloadCategory.audio => Icons.headphones_outlined,
    DownloadCategory.document => Icons.description_outlined,
    DownloadCategory.archive => Icons.archive_outlined,
    DownloadCategory.app => Icons.android_outlined,
    DownloadCategory.other => Icons.insert_drive_file_outlined,
  };
}
