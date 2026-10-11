import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'torrent_module_controller.dart';

class TorrentPage extends StatefulWidget {
  const TorrentPage({super.key});

  @override
  State<TorrentPage> createState() => _TorrentPageState();
}

class _TorrentPageState extends State<TorrentPage> {
  final TorrentModuleController _controller = TorrentModuleController();
  final TextEditingController _magnet = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _magnet.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _addMagnet() async {
    final value = _magnet.text.trim();
    if (value.isEmpty) return;
    try {
      await _controller.addMagnet(value);
      _magnet.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Magnet اضافه نشد: $error')),
      );
    }
  }

  Future<void> _pickTorrent() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['torrent'],
    );
    final path = file?.path;
    if (path == null) return;

    try {
      final model = await _controller.inspectTorrentFile(path);
      List<int>? selected;
      if (model.files.length > 1 && mounted) {
        selected = await _selectFiles(
          model.files
              .map((file) => (name: file.path, size: file.length))
              .toList(),
        );
        if (selected == null || selected.isEmpty) return;
      }
      await _controller.addTorrentFile(
        path,
        selectedFiles: selected,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Torrent اضافه نشد: $error')),
      );
    }
  }

  Future<List<int>?> _selectFiles(
    List<({String name, int size})> entries,
  ) async {
    final selected = List<bool>.filled(entries.length, true);

    return showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .7,
          minChildSize: .4,
          maxChildSize: .92,
          builder: (context, scrollController) => Column(
            children: [
              ListTile(
                title: const Text('انتخاب فایل‌ها'),
                subtitle: Text('${entries.length} فایل'),
                trailing: TextButton(
                  onPressed: () {
                    setSheetState(() {
                      final allSelected = selected.every((value) => value);
                      for (var i = 0; i < selected.length; i++) {
                        selected[i] = !allSelected;
                      }
                    });
                  },
                  child: const Text('همه/هیچ'),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return CheckboxListTile(
                      value: selected[index],
                      onChanged: (value) {
                        setSheetState(() {
                          selected[index] = value ?? false;
                        });
                      },
                      title: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                      ),
                      subtitle: Text(_formatBytes(entry.size)),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final indices = <int>[];
                        for (var i = 0; i < selected.length; i++) {
                          if (selected[i]) indices.add(i);
                        }
                        Navigator.pop(context, indices);
                      },
                      child: const Text('تأیید فایل‌ها'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editSessionFiles(TorrentSession session) async {
    final task = session.task;
    if (task == null) return;
    final entries = task.metaInfo.files
        .map((file) => (name: file.path, size: file.length))
        .toList();
    if (entries.isEmpty) return;

    final indices = await _selectFiles(entries);
    if (indices == null || indices.isEmpty) return;
    _controller.applySelectedFiles(session.id, indices);
  }

  String _formatBytes(int value) {
    if (value >= 1024 * 1024 * 1024) {
      return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    if (value >= 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (value >= 1024) {
      return '${(value / 1024).toStringAsFixed(0)} KB';
    }
    return '$value B';
  }

  String _formatSpeed(double value) {
    if (value <= 0) return '0 KB/s';
    if (value >= 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(value / 1024).toStringAsFixed(0)} KB/s';
  }
  @override
  Widget build(BuildContext context) {
    final sessions = _controller.sessions;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Torrent / Magnet'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'افزودن دانلود',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _magnet,
            textDirection: TextDirection.ltr,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'لینک Magnet',
              hintText: 'magnet:?xt=urn:btih:...',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _addMagnet,
                  icon: const Icon(Icons.add_link_rounded),
                  label: const Text('افزودن'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'انتخاب فایل .torrent',
                onPressed: _pickTorrent,
                icon: const Icon(Icons.insert_drive_file_outlined),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'دانلودها',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${sessions.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(
                    Icons.hub_outlined,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'هنوز Torrent یا Magnet اضافه نشده.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            ...sessions.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: .45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            session.status,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (session.metadataProgress > 0 &&
                          session.metadataProgress < 1) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: session.metadataProgress,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ],
                      if (session.task != null) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: session.progress.clamp(0, 1).toDouble(),
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(session.progress * 100).clamp(0, 100).toStringAsFixed(0)}٪ • ${_formatSpeed(session.downloadSpeed)} • ${session.connectedPeers} Peer',
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'توقف موقت',
                            visualDensity: VisualDensity.compact,
                            onPressed: session.task == null
                                ? null
                                : () => _controller.pause(session.id),
                            icon: const Icon(Icons.pause_rounded),
                          ),
                          IconButton(
                            tooltip: 'ادامه',
                            visualDensity: VisualDensity.compact,
                            onPressed: session.task == null
                                ? null
                                : () => _controller.resume(session.id),
                            icon: const Icon(Icons.play_arrow_rounded),
                          ),
                          if (session.task != null)
                            TextButton(
                              onPressed: () => _editSessionFiles(session),
                              child: const Text('فایل‌ها'),
                            ),
                          IconButton(
                            tooltip: 'توقف کامل',
                            visualDensity: VisualDensity.compact,
                            onPressed: session.task == null
                                ? null
                                : () => _controller.stop(session.id),
                            icon: const Icon(Icons.stop_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'فقط فایل‌هایی را دریافت کن که اجازه دانلود و اشتراک آن‌ها را داری.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}