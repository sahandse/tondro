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
      await _controller.addTorrentFile(path);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Torrent اضافه نشد: $error')),
      );
    }
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