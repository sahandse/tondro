import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'downloads_controller.dart';

class BatchDownloadPage extends StatefulWidget {
  const BatchDownloadPage({
    super.key,
    required this.controller,
  });

  final DownloadsController controller;

  @override
  State<BatchDownloadPage> createState() => _BatchDownloadPageState();
}

class _BatchDownloadPageState extends State<BatchDownloadPage> {
  final TextEditingController _links = TextEditingController();
  final TextEditingController _folder = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _links.dispose();
    _folder.dispose();
    super.dispose();
  }

  List<String> _extractLinks(String value) {
    final regex = RegExp(r'https?://[^\s]+', caseSensitive: false);
    return regex
        .allMatches(value)
        .map((match) => match.group(0) ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Future<void> _pickTextFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['txt'],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final text = utf8.decode(bytes, allowMalformed: true);
    final existing = _links.text.trim();
    _links.text = existing.isEmpty ? text : '$existing\n$text';
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final urls = _extractLinks(_links.text);
    if (urls.isEmpty || _working) return;

    setState(() => _working = true);
    try {
      final result = await widget.controller.addUrls(
        urls,
        customFolder: _folder.text.trim().isEmpty
            ? null
            : _folder.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.added} لینک اضافه شد • '
            '${result.duplicates} تکراری • '
            '${result.invalid} نامعتبر',
          ),
        ),
      );
      if (result.added > 0) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _extractLinks(_links.text).length;
    return Scaffold(
      appBar: AppBar(title: const Text('چند دانلود باهم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _links,
            minLines: 9,
            maxLines: 16,
            textDirection: TextDirection.ltr,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'لینک‌ها',
              hintText: 'هر لینک در یک خط یا متن حاوی چند لینک',
              helperText: '$count لینک پیدا شد',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickTextFile,
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('Import فایل TXT'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _folder,
            decoration: const InputDecoration(
              labelText: 'پوشه مشترک (اختیاری)',
              prefixIcon: Icon(Icons.folder_outlined),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: count == 0 || _working ? null : _submit,
            icon: _working
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_rounded),
            label: Text(_working ? 'در حال افزودن…' : 'افزودن به صف'),
          ),
        ],
      ),
    );
  }
}