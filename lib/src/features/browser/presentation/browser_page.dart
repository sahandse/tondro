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
  String url = '';
  String title = 'تب جدید';
  int progress = 0;
  bool desktopMode = false;
  final Set<String> detected = <String>{};
}

class _BrowserPageState extends State<BrowserPage> {
  static const _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/140.0.0.0 Safari/537.36';

  final BrowserStore _store = BrowserStore();
  final List<_BrowserTab> _tabs = [];
  late final TextEditingController _address;
  int _activeIndex = 0;

  _BrowserTab get _active => _tabs[_activeIndex];

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(text: widget.initialUrl ?? '');
    _createTab(
      initialUrl: widget.initialUrl,
      incognito: false,
      makeActive: true,
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
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (value) {
          tab.progress = value;
          if (mounted && _active.id == tab.id) setState(() {});
        },
        onPageStarted: (url) {
          tab.url = url;
          if (mounted && _active.id == tab.id) {
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
          if (mounted && _active.id == tab.id) {
            _address.text = url;
            setState(() {});
          }
        },
        onUrlChange: (change) {
          final url = change.url;
          if (url == null) return;
          tab.url = url;
          if (mounted && _active.id == tab.id) _address.text = url;
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

    if (incognito) {
      await controller.clearCache();
      await controller.clearLocalStorage();
    }

    _tabs.add(tab);
    if (makeActive) _activeIndex = _tabs.length - 1;

    final value = initialUrl?.trim();
    if (value != null && value.isNotEmpty) {
      final uri = Uri.tryParse(value);
      if (uri != null) await controller.loadRequest(uri);
    } else {
      await controller.loadHtmlString(
        '<html><body style="font-family:sans-serif;padding:32px">'
        '<h3>مرورگر تندرو</h3>'
        '<p>آدرس یا عبارت جستجو را وارد کن.</p>'
        '</body></html>',
      );
    }

    if (mounted) {
      _address.text = tab.url;
      setState(() {});
    }
  }

  Future<void> _go() async {
    final value = _address.text.trim();
    if (value.isEmpty) return;
    final uri = Uri.tryParse(value);
    final target = uri != null && uri.hasScheme
        ? uri
        : Uri.https('www.google.com', '/search', {'q': value});
    await _active.controller.loadRequest(target);
  }

  Future<void> _capture(_BrowserTab tab, String url) async {
    if (!tab.detected.add(url) || !mounted) return;
    if (_active.id == tab.id) setState(() {});
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
        "JSON.stringify(Array.from(document.querySelectorAll('a[href],video[src],audio[src],source[src]')).map(function(el){return el.href || el.src || '';}).filter(Boolean))",
      );
      dynamic decoded = raw;
      if (decoded is String) {
        try {
          decoded = jsonDecode(decoded);
          if (decoded is String) decoded = jsonDecode(decoded);
        } catch (_) {}
      }
      if (decoded is! List) return;
      tab.detected.addAll(
        MediaDetector.extractDirectUrls(decoded.whereType<String>()),
      );
      if (mounted && _active.id == tab.id) setState(() {});
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
              title: Text('${urls.length} لینک مستقیم'),
              leading: const Icon(Icons.download_for_offline_outlined),
            ),
            const Divider(height: 1),
            Expanded(
              child: urls.isEmpty
                  ? const Center(child: Text('لینکی پیدا نشده.'))
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: urls.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final url = urls[index];
                        return ListTile(
                          title: Text(
                            Uri.tryParse(url)?.pathSegments.last ?? url,
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
                          final wasActive = index == _activeIndex;
                          setState(() {
                            _tabs.removeAt(index);
                            if (_activeIndex >= _tabs.length) {
                              _activeIndex = _tabs.length - 1;
                            } else if (index < _activeIndex) {
                              _activeIndex--;
                            } else if (wasActive) {
                              _activeIndex = _activeIndex.clamp(
                                0,
                                _tabs.length - 1,
                              );
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
            tooltip: 'لینک‌های پیدا شده',
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
                  active.desktopMode
                      ? 'حالت موبایل'
                      : 'حالت دسکتاپ',
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
            .map((tab) => WebViewWidget(controller: tab.controller))
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