import 'package:flutter/material.dart';

import '../../../app/widgets/tondro_brand.dart';

class NewDownloadRequest {
  const NewDownloadRequest({
    required this.url,
    required this.scheduledAt,
  });

  final String url;
  final DateTime? scheduledAt;
}

class NewDownloadSheet extends StatefulWidget {
  const NewDownloadSheet({
    super.key,
    this.initialUrl,
  });

  final String? initialUrl;

  @override
  State<NewDownloadSheet> createState() => _NewDownloadSheetState();
}

class _NewDownloadSheetState extends State<NewDownloadSheet> {
  late final TextEditingController _input;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledAt ?? now.add(const Duration(minutes: 5)),
      ),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 8, 14, keyboard + 14),
      child: XpWindowFrame(
        title: 'New Download',
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const TondroLogo(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'دانلود جدید',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _input,
              autofocus: widget.initialUrl == null,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                hintText: 'https://example.com/file.zip',
                labelText: 'آدرس فایل',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickSchedule,
              icon: const Icon(Icons.schedule_rounded),
              label: Text(
                _scheduledAt == null
                    ? 'زمان‌بندی دانلود'
                    : 'شروع در ' + formatDownloadDateTime(_scheduledAt!),
              ),
            ),
            if (_scheduledAt != null)
              TextButton.icon(
                onPressed: () => setState(() => _scheduledAt = null),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('شروع فوری'),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                NewDownloadRequest(
                  url: _input.text.trim(),
                  scheduledAt: _scheduledAt,
                ),
              ),
              icon: Icon(
                _scheduledAt == null
                    ? Icons.download_rounded
                    : Icons.schedule_send_rounded,
              ),
              label: Text(
                _scheduledAt == null ? 'شروع دانلود' : 'ثبت زمان‌بندی',
              ),
            ),
          ],
        ),
      ),
    );
  }}

String formatDownloadDateTime(DateTime dateTime) {
  final h = dateTime.hour.toString().padLeft(2, '0');
  final m = dateTime.minute.toString().padLeft(2, '0');
  return '${dateTime.year}/${dateTime.month}/${dateTime.day} - $h:$m';
}