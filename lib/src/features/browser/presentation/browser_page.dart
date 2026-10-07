import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/widgets/tondro_brand.dart';
import '../../downloads/presentation/downloads_controller.dart';
import '../domain/media_detector.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({
    super.key,
    required this.downloadsController,
  });

  final DownloadsController downloadsController;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final WebViewController _web;
  late final TextEditingController _address;
  final Set<String> _detected = <String>{};
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (url) {
            _address.text = url;
          },
          onPageFinished: (url) {
            _address.text = url;
            unawaited(_scanPage());
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null && mounted) _address.text = url;
          },
          onNavigationRequest: (request) {
            if (MediaDetector.isDirectDownloadUrl(request.url)) {
              unawaited(_capture(request.url));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(
        '<html><body style="font-family:sans-serif;padding:32px">'
        '<h3>Tondro Browser</h3>'
        '<p>آدرس سایت را در نوار بالا وارد کن.</p>'
        '</body></html>',
      );
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final value = _address.text.trim();
    if (value.isEmpty) return;

    final uri = Uri.tryParse(value);
    final target = uri != null && uri.hasScheme
        ? uri
        : Uri.https('www.google.com', '/search', {'q': value});
    await _web.loadRequest(target);
  }

  Future<void> _capture(String url) async {
    if (!_detected.add(url)) return;
    if (!mounted) return;
    setState(() {});
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

  Future<void> _scanPage() async {
    try {
      final raw = await _web.runJavaScriptReturningResult(
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
      final urls = MediaDetector.extractDirectUrls(
        decoded.whereType<String>(),
      );
      if (urls.isEmpty) return;

      final oldLength = _detected.length;
      _detected.addAll(urls);
      if (mounted && _detected.length != oldLength) setState(() {});
    } catch (_) {}
  }

  Future<void> _showDetected() async {
    final urls = _detected.toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .62,
        minChildSize: .35,
        maxChildSize: .9,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.travel_explore_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${urls.length} لینک مستقیم',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: urls.isEmpty
                  ? const Center(
                      child: Text('هنوز لینک مستقیم فایلی پیدا نشده.'),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: urls.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final url = urls[index];
                        return ListTile(
                          leading: const Icon(Icons.link_rounded),
                          title: Text(
                            Uri.tryParse(url)?.pathSegments.last ?? url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                          ),
                          subtitle: Text(
                            url,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                          ),
                          trailing: IconButton.filledTonal(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: TextField(
          controller: _address,
          textDirection: TextDirection.ltr,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _go(),
          decoration: const InputDecoration(
            hintText: 'آدرس یا جستجو',
            isDense: true,
            prefixIcon: Icon(Icons.public_rounded),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'لینک‌های پیدا شده',
            onPressed: _showDetected,
            icon: Badge(
              isLabelVisible: _detected.isNotEmpty,
              label: Text('${_detected.length}'),
              child: const Icon(Icons.download_for_offline_outlined),
            ),
          ),
          const SizedBox(width: 6),
        ],
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _web),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: XpWindowFrame(
            title: 'Browser Controls',
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'عقب',
                  onPressed: () async {
                    if (await _web.canGoBack()) await _web.goBack();
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                IconButton(
                  tooltip: 'جلو',
                  onPressed: () async {
                    if (await _web.canGoForward()) await _web.goForward();
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
                IconButton(
                  tooltip: 'تازه‌سازی',
                  onPressed: _web.reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                const Spacer(),
                const TondroLogo(size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}