import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/widgets/tondro_brand.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            TondroLogo(size: 32),
            SizedBox(width: 10),
            Text('دانلود پیشرفته'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          XpWindowFrame(
            title: 'افزودن تورنت',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'فقط فایل‌هایی را دانلود کن که اجازه دریافت و اشتراک آن‌ها را داری.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _magnet,
                  textDirection: TextDirection.ltr,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'لینک Magnet',
                    hintText: 'magnet:?xt=urn:btih:...',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _addMagnet,
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('افزودن Magnet'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTorrent,
                        icon: const Icon(Icons.insert_drive_file_outlined),
                        label: const Text('فایل .torrent'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (sessions.isEmpty)
            const XpWindowFrame(
              title: 'صف تورنت',
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'هنوز Torrent یا Magnet اضافه نشده.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...sessions.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: XpWindowFrame(
                  title: session.status,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        session.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (session.metadataProgress > 0 &&
                          session.metadataProgress < 1) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: session.metadataProgress,
                          minHeight: 8,
                        ),
                      ],
                      if (session.task != null) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: session.progress.clamp(0, 1).toDouble(),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Text(
                              '${(session.progress * 100).clamp(0, 100).toStringAsFixed(0)}٪',
                            ),
                            Text(_formatSpeed(session.downloadSpeed)),
                            Text('${session.connectedPeers} Peer'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Pause',
                            onPressed: session.task == null
                                ? null
                                : () => _controller.pause(session.id),
                            icon: const Icon(Icons.pause_rounded),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            tooltip: 'Resume',
                            onPressed: session.task == null
                                ? null
                                : () => _controller.resume(session.id),
                            icon: const Icon(Icons.play_arrow_rounded),
                          ),
                          const Spacer(),
                          if (session.task != null)
                            TextButton.icon(
                              onPressed: () => _editSessionFiles(session),
                              icon: const Icon(Icons.folder_copy_outlined),
                              label: const Text('فایل‌ها'),
                            ),
                          TextButton.icon(
                            onPressed: session.task == null
                                ? null
                                : () => _controller.stop(session.id),
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('توقف'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}