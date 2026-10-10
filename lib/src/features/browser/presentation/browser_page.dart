import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../downloads/presentation/downloads_controller.dart';
import '../data/browser_store.dart';
import '../domain/media_detector.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({
    super.key,
    required this.downloadsController,
    this.initialUrl,
  });

  final DownloadsController downloadsController;
  final String? initialUrl;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserTab {
  _BrowserTab({
    required this.id,
    required this.controller,
    required this.incognito,
  });

  final String id;
  final WebViewController controller;
  final bool incognito;
  final Set<String> detected = <String>{};
  String url = '';
  String title = 'تب جدید';
  int progress = 0;
  bool desktopMode = false;
  String? errorMessage;
}

class _BrowserPageState extends State<BrowserPage> {
  static const _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/140.0.0.0 Safari/537.36';

  final BrowserStore _store = BrowserStore();
  final List<_BrowserTab> _tabs = <_BrowserTab>[];
  late final TextEditingController _address;
  int _activeIndex = 0;

  _BrowserTab get _active => _tabs[_activeIndex];

  bool _isActive(_BrowserTab tab) {
    return _tabs.isNotEmpty &&
        _activeIndex >= 0 &&
        _activeIndex < _tabs.length &&
        identical(_tabs[_activeIndex], tab);
  }

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(text: widget.initialUrl ?? '');
    unawaited(
      _createTab(
        initialUrl: widget.initialUrl,
        incognito: false,
        makeActive: true,
      ),
    );
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _createTab({
    String? initialUrl,
    required bool incognito,
    bool makeActive = true,
  }) async {
    late final _BrowserTab tab;
    final controller = WebViewController();
    tab = _BrowserTab(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      controller: controller,
      incognito: incognito,
    );

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(const Color(0x00000000));
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (value) {
          tab.progress = value;
          if (mounted && _isActive(tab)) setState(() {});
        },
        onPageStarted: (url) {
          tab.url = url;
          tab.errorMessage = null;
          if (mounted && _isActive(tab)) {
            _address.text = url;
            setState(() {});
          }
        },
        onPageFinished: (url) async {
          tab.url = url;
          final title = await controller.getTitle();
          tab.title = title?.trim().isNotEmpty == true ? title! : url;
          if (!tab.incognito) {
            await _store.addHistory(url, tab.title);
          }
          await _scanPage(tab);
          if (mounted && _isActive(tab)) {
            _address.text = url;
            setState(() {});
          }
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == false) return;
          tab.errorMessage = _browserErrorMessage(error);
          if (mounted && _isActive(tab)) setState(() {});
        },
        onUrlChange: (change) {
          final url = change.url;
          if (url == null) return;
          tab.url = url;
          if (mounted && _isActive(tab)) {
            _address.text = url;
          }
        },
        onNavigationRequest: (request) {
          if (MediaDetector.isDirectDownloadUrl(request.url)) {
            unawaited(_capture(tab, request.url));
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );

    _tabs.add(tab);
    if (makeActive) _activeIndex = _tabs.length - 1;

    final value = initialUrl?.trim();
    if (value != null && value.isNotEmpty) {
      await controller.loadRequest(_resolveInput(value));
    } else {
      await controller.loadHtmlString(
        '<html dir="rtl"><body style="font-family:sans-serif;padding:32px">'
        '<h3>مرورگر تندرو</h3>'
        '<p>آدرس سایت یا عبارت جستجو را وارد کن.</p>'
        '</body></html>',
      );
    }

    if (mounted && _isActive(tab)) {
      _address.text = tab.url;
      setState(() {});
    }
  }

  Uri _resolveInput(String raw) {
    final value = raw.trim();
    final parsed = Uri.tryParse(value);
    if (parsed != null && {'http', 'https'}.contains(parsed.scheme)) {
      return parsed;
    }

    final hostCandidate = Uri.tryParse('https://$value');
    final host = hostCandidate?.host.toLowerCase() ?? '';
    final looksLikeHost =
        host.isNotEmpty && (host == 'localhost' || host.contains('.'));
    if (looksLikeHost && hostCandidate != null) {
      return hostCandidate;
    }

    return Uri.https('www.google.com', '/search', {'q': value});
  }

  Future<void> _go() async {
    final value = _address.text.trim();
    if (value.isEmpty) return;
    FocusScope.of(context).unfocus();
    _active.errorMessage = null;
    await _active.controller.loadRequest(_resolveInput(value));
    if (mounted) setState(() {});
  }

  String _browserErrorMessage(WebResourceError error) {
    final description = error.description.trim();
    if (description.isEmpty) return 'صفحه باز نشد.';
    final normalized = description.toLowerCase();
    if (normalized.contains('err_name_not_resolved')) {
      return 'آدرس پیدا نشد. اینترنت یا آدرس سایت را بررسی کن.';
    }
    if (normalized.contains('cleartext')) {
      return 'اتصال HTTP این سایت توسط دستگاه مسدود شده.';
    }
    if (normalized.contains('ssl')) {
      return 'اتصال امن سایت مشکل دارد.';
    }
    return 'صفحه باز نشد: $description';
  }

  Future<void> _capture(_BrowserTab tab, String url) async {
    if (!tab.detected.add(url) || !mounted) return;
    if (_isActive(tab)) setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('لینک مستقیم فایل پیدا شد'),
          action: SnackBarAction(
            label: 'دانلود',
            onPressed: () => unawaited(_download(url)),
          ),
        ),
      );
  }

  Future<void> _download(String url) async {
    try {
      await widget.downloadsController.addUrl(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('به صف دانلود اضافه شد')),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _scanPage(_BrowserTab tab) async {
    try {
      final raw = await tab.controller.runJavaScriptReturningResult(
        "JSON.stringify({"
        "direct:Array.from(document.querySelectorAll('a[href],video[src],audio[src],source[src]')).map(function(el){return el.href || el.src || '';}).filter(Boolean),"
        "download:Array.from(document.querySelectorAll('a[download][href]')).map(function(el){return el.href || '';}).filter(Boolean)"
        "})",
      );

      dynamic decoded = raw;
      if (decoded is String) {
        try {
          decoded = jsonDecode(decoded);
          if (decoded is String) decoded = jsonDecode(decoded);
        } catch (_) {}
      }
      if (decoded is! Map) return;

      final map = Map<String, dynamic>.from(decoded);
      final direct = (map['direct'] as List? ?? const <dynamic>[])
          .whereType<String>();
      final explicitDownloads =
          (map['download'] as List? ?? const <dynamic>[]).whereType<String>();

      tab.detected.addAll(MediaDetector.extractDirectUrls(direct));
      for (final url in explicitDownloads) {
        final uri = Uri.tryParse(url);
        if (uri != null && {'http', 'https'}.contains(uri.scheme)) {
          tab.detected.add(url);
        }
      }

      if (mounted && _isActive(tab)) setState(() {});
    } catch (_) {}
  }

  Future<void> _showDetected() async {
    final urls = _active.detected.toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .62,
        minChildSize: .35,
        maxChildSize: .9,
        builder: (context, scrollController) => Column(
          children: [
            ListTile(
              title: Text('${urls.length} لینک دانلود'),
              leading: const Icon(Icons.download_for_offline_outlined),
            ),
            const Divider(height: 1),
            Expanded(
              child: urls.isEmpty
                  ? const Center(child: Text('لینک قابل دانلودی پیدا نشده.'))
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: urls.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final url = urls[index];
                        final uri = Uri.tryParse(url);
                        final name = uri != null && uri.pathSegments.isNotEmpty
                            ? uri.pathSegments.last
                            : url;
                        return ListTile(
                          title: Text(
                            name.isEmpty ? url : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                          ),
                          subtitle: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                          ),
                          trailing: IconButton(
                            tooltip: 'دانلود',
                            onPressed: () => _download(url),
                            icon: const Icon(Icons.download_rounded),
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

  Future<void> _showTabs() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text('${_tabs.length} تب'),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'تب جدید',
                    onPressed: () async {
                      Navigator.pop(context);
                      await _createTab(incognito: false);
                    },
                    icon: const Icon(Icons.add_rounded),
                  ),
                  IconButton(
                    tooltip: 'تب خصوصی',
                    onPressed: () async {
                      Navigator.pop(context);
                      await _createTab(incognito: true);
                    },
                    icon: const Icon(Icons.visibility_off_outlined),
                  ),
                ],
              ),
            ),
            ...List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              return ListTile(
                selected: index == _activeIndex,
                leading: Icon(
                  tab.incognito
                      ? Icons.visibility_off_outlined
                      : Icons.public_rounded,
                ),
                title: Text(
                  tab.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  tab.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                ),
                onTap: () {
                  setState(() {
                    _activeIndex = index;
                    _address.text = tab.url;
                  });
                  Navigator.pop(context);
                },
                trailing: _tabs.length == 1
                    ? null
                    : IconButton(
                        onPressed: () {
                          setState(() {
                            _tabs.removeAt(index);
                            if (_activeIndex >= _tabs.length) {
                              _activeIndex = _tabs.length - 1;
                            } else if (index < _activeIndex) {
                              _activeIndex--;
                            }
                            _address.text = _active.url;
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _showLibrary() async {
    final history = await _store.history();
    final bookmarks = await _store.bookmarks();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DefaultTabController(
        length: 2,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'نشان‌ها'),
                  Tab(text: 'تاریخچه'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _BrowserRecordsList(
                      records: bookmarks,
                      onOpen: (record) {
                        Navigator.pop(context);
                        _active.controller.loadRequest(Uri.parse(record.url));
                      },
                    ),
                    _BrowserRecordsList(
                      records: history,
                      onOpen: (record) {
                        Navigator.pop(context);
                        _active.controller.loadRequest(Uri.parse(record.url));
                      },
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

  Future<void> _toggleBookmark() async {
    final url = _active.url;
    if (url.isEmpty) return;
    await _store.toggleBookmark(url, _active.title);
    if (mounted) setState(() {});
  }

  Future<void> _toggleDesktopMode() async {
    _active.desktopMode = !_active.desktopMode;
    await _active.controller.setUserAgent(
      _active.desktopMode ? _desktopUserAgent : null,
    );
    await _active.controller.reload();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final active = _active;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: TextField(
          controller: _address,
          textDirection: TextDirection.ltr,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _go(),
          decoration: InputDecoration(
            hintText: 'آدرس یا جستجو',
            isDense: true,
            prefixIcon: Icon(
              active.incognito
                  ? Icons.visibility_off_outlined
                  : Icons.public_rounded,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'لینک‌های دانلود',
            onPressed: _showDetected,
            icon: Badge(
              isLabelVisible: active.detected.isNotEmpty,
              label: Text('${active.detected.length}'),
              child: const Icon(Icons.download_for_offline_outlined),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'bookmark') await _toggleBookmark();
              if (value == 'library') await _showLibrary();
              if (value == 'desktop') await _toggleDesktopMode();
              if (value == 'clearHistory') {
                await _store.clearHistory();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تاریخچه پاک شد')),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'bookmark',
                child: Text('افزودن/حذف نشان'),
              ),
              const PopupMenuItem(
                value: 'library',
                child: Text('نشان‌ها و تاریخچه'),
              ),
              PopupMenuItem(
                value: 'desktop',
                child: Text(
                  active.desktopMode ? 'حالت موبایل' : 'حالت دسکتاپ',
                ),
              ),
              const PopupMenuItem(
                value: 'clearHistory',
                child: Text('پاک‌کردن تاریخچه'),
              ),
            ],
          ),
        ],
        bottom: active.progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: active.progress / 100,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: IndexedStack(
        index: _activeIndex,
        children: _tabs
            .map(
              (tab) => Stack(
                children: [
                  Positioned.fill(
                    child: WebViewWidget(controller: tab.controller),
                  ),
                  if (tab.errorMessage != null)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.public_off_rounded,
                                    size: 52,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    tab.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(height: 1.7),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      tab.errorMessage = null;
                                      if (mounted) setState(() {});
                                      await tab.controller.reload();
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('تلاش دوباره'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
            .toList(),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                tooltip: 'عقب',
                onPressed: () async {
                  if (await active.controller.canGoBack()) {
                    await active.controller.goBack();
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              IconButton(
                tooltip: 'جلو',
                onPressed: () async {
                  if (await active.controller.canGoForward()) {
                    await active.controller.goForward();
                  }
                },
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              IconButton(
                tooltip: 'تازه‌سازی',
                onPressed: active.controller.reload,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'تب‌ها',
                onPressed: _showTabs,
                icon: Badge(
                  label: Text('${_tabs.length}'),
                  child: const Icon(Icons.tab_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowserRecordsList extends StatelessWidget {
  const _BrowserRecordsList({
    required this.records,
    required this.onOpen,
  });

  final List<BrowserRecord> records;
  final ValueChanged<BrowserRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('هنوز چیزی اینجا نیست.'));
    }
    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = records[index];
        return ListTile(
          title: Text(
            record.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            record.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
          ),
          onTap: () => onOpen(record),
        );
      },
    );
  }
}