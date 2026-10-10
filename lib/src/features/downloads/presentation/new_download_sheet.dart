import 'package:flutter/material.dart';

import '../../../app/widgets/tondro_brand.dart';
import '../domain/download_inspection.dart';
import '../domain/duplicate_policy.dart';
import 'downloads_controller.dart';

class NewDownloadRequest {
  const NewDownloadRequest({
    required this.url,
    required this.scheduledAt,
    required this.customFolder,
    required this.duplicatePolicy,
    required this.expectedSha256,
    required this.segmentOverride,
    required this.speedLimitKbpsOverride,
    required this.inspection,
  });

  final String url;
  final DateTime? scheduledAt;
  final String? customFolder;
  final DuplicatePolicy duplicatePolicy;
  final String? expectedSha256;
  final int? segmentOverride;
  final int? speedLimitKbpsOverride;
  final DownloadInspection? inspection;
}

class NewDownloadSheet extends StatefulWidget {
  const NewDownloadSheet({
    super.key,
    required this.controller,
    this.initialUrl,
  });

  final DownloadsController controller;
  final String? initialUrl;

  @override
  State<NewDownloadSheet> createState() => _NewDownloadSheetState();
}

class _NewDownloadSheetState extends State<NewDownloadSheet> {
  late final TextEditingController _input;
  late final TextEditingController _folder;
  late final TextEditingController _sha256;
  DateTime? _scheduledAt;
  DownloadInspection? _inspection;
  DuplicatePolicy _duplicatePolicy = DuplicatePolicy.rename;
  int? _segmentOverride;
  int _speedLimitKbpsOverride = 0;
  bool _inspecting = false;
  String? _inspectionError;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.initialUrl ?? '');
    _folder = TextEditingController();
    _sha256 = TextEditingController();
    if (widget.initialUrl?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _inspect());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _folder.dispose();
    _sha256.dispose();
    super.dispose();
  }

  Future<void> _inspect() async {
    final value = _input.text.trim();
    if (value.isEmpty || _inspecting) return;
    setState(() {
      _inspecting = true;
      _inspectionError = null;
    });
    try {
      final result = await widget.controller.inspectUrl(value);
      if (!mounted) return;
      setState(() => _inspection = result);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _inspection = null;
        _inspectionError = 'اطلاعات فایل قابل دریافت نبود؛ دانلود هنوز قابل انجام است.';
      });
    } finally {
      if (mounted) setState(() => _inspecting = false);
    }
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

  String _sizeLabel(int bytes) {
    if (bytes <= 0) return 'نامشخص';
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final inspection = _inspection;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 8, 14, keyboard + 14),
      child: SingleChildScrollView(
        child: XpWindowFrame(
          title: 'دانلود جدید',
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
                onChanged: (_) {
                  if (_inspection != null || _inspectionError != null) {
                    setState(() {
                      _inspection = null;
                      _inspectionError = null;
                    });
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'https://example.com/file.zip',
                  labelText: 'لینک دانلود',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _inspecting ? null : _inspect,
                icon: _inspecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.manage_search_rounded),
                label: Text(_inspecting ? 'در حال بررسی…' : 'بررسی لینک'),
              ),
              if (inspection != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inspection.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Chip(label: Text(_sizeLabel(inspection.totalBytes))),
                          Chip(label: Text(inspection.mimeType ?? 'MIME نامشخص')),
                          Chip(
                            avatar: Icon(
                              inspection.supportsRange
                                  ? Icons.check_circle_outline
                                  : Icons.link_off_rounded,
                              size: 17,
                            ),
                            label: Text(
                              inspection.supportsRange
                                  ? 'Resume / Range'
                                  : 'تک‌اتصالی',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (_inspectionError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _inspectionError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _folder,
                decoration: const InputDecoration(
                  labelText: 'پوشه ذخیره (اختیاری)',
                  hintText: 'مثلاً Movies',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<DuplicatePolicy>(
                initialValue: _duplicatePolicy,
                decoration: const InputDecoration(
                  labelText: 'اگر فایل تکراری بود',
                ),
                items: DuplicatePolicy.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(duplicatePolicyLabelFa(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _duplicatePolicy = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _sha256,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'SHA-256 (اختیاری)',
                  hintText: '64 hex characters',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
              ),
              const SizedBox(height: 10),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('تنظیمات پیشرفته'),
                subtitle: const Text('اتصال و سقف سرعت همین فایل'),
                children: [
                  DropdownButtonFormField<int?>(
                    initialValue: _segmentOverride,
                    decoration: const InputDecoration(
                      labelText: 'تعداد اتصال',
                    ),
                    items: const [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Auto'),
                      ),
                      DropdownMenuItem<int?>(value: 1, child: Text('1')),
                      DropdownMenuItem<int?>(value: 2, child: Text('2')),
                      DropdownMenuItem<int?>(value: 4, child: Text('4')),
                      DropdownMenuItem<int?>(value: 8, child: Text('8')),
                      DropdownMenuItem<int?>(value: 16, child: Text('16')),
                    ],
                    onChanged: (value) {
                      setState(() => _segmentOverride = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _speedLimitKbpsOverride,
                    decoration: const InputDecoration(
                      labelText: 'سقف سرعت',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Text('تنظیم عمومی'),
                      ),
                      DropdownMenuItem(
                        value: 512,
                        child: Text('512 KB/s'),
                      ),
                      DropdownMenuItem(
                        value: 1024,
                        child: Text('1 MB/s'),
                      ),
                      DropdownMenuItem(
                        value: 2048,
                        child: Text('2 MB/s'),
                      ),
                      DropdownMenuItem(
                        value: 4096,
                        child: Text('4 MB/s'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _speedLimitKbpsOverride = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickSchedule,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(
                  _scheduledAt == null
                      ? 'زمان‌بندی دانلود'
                      : 'شروع در ${formatDownloadDateTime(_scheduledAt!)}',
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
                    customFolder: _folder.text.trim().isEmpty
                        ? null
                        : _folder.text.trim(),
                    duplicatePolicy: _duplicatePolicy,
                    expectedSha256: _sha256.text.trim().isEmpty
                        ? null
                        : _sha256.text.trim(),
                    segmentOverride: _segmentOverride,
                    speedLimitKbpsOverride:
                        _speedLimitKbpsOverride == 0
                            ? null
                            : _speedLimitKbpsOverride,
                    inspection: inspection,
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
      ),
    );
  }
}

String formatDownloadDateTime(DateTime dateTime) {
  final h = dateTime.hour.toString().padLeft(2, '0');
  final m = dateTime.minute.toString().padLeft(2, '0');
  return '${dateTime.year}/${dateTime.month}/${dateTime.day} - $h:$m';
}