import 'package:flutter/material.dart';

import '../../downloads/presentation/downloads_controller.dart';

class DownloadSettingsPage extends StatefulWidget {
  const DownloadSettingsPage({
    super.key,
    required this.controller,
  });

  final DownloadsController controller;

  @override
  State<DownloadSettingsPage> createState() => _DownloadSettingsPageState();
}

class _DownloadSettingsPageState extends State<DownloadSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = widget.controller.settings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات دانلود')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionCard(
            title: 'اتصال و صف',
            children: [
              SwitchListTile.adaptive(
                value: settings.wifiOnly,
                title: const Text('فقط Wi-Fi'),
                subtitle: const Text('دانلود روی اینترنت موبایل شروع نمی‌شود.'),
                onChanged: (value) async {
                  await widget.controller.updateSettings(
                    settings.copyWith(wifiOnly: value),
                  );
                  if (mounted) setState(() {});
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('دانلود هم‌زمان'),
                subtitle: Text('${settings.maxConcurrentDownloads} فایل'),
                trailing: DropdownButton<int>(
                  value: settings.maxConcurrentDownloads,
                  underline: const SizedBox.shrink(),
                  items: List.generate(
                    5,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}'),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value == null) return;
                    await widget.controller.updateSettings(
                      settings.copyWith(maxConcurrentDownloads: value),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('تلاش خودکار'),
                subtitle: Text('${settings.autoRetry} بار پس از خطا'),
                trailing: DropdownButton<int>(
                  value: settings.autoRetry,
                  underline: const SizedBox.shrink(),
                  items: List.generate(
                    6,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text('$index'),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value == null) return;
                    await widget.controller.updateSettings(
                      settings.copyWith(autoRetry: value),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'تشخیص لینک',
            children: [
              SwitchListTile.adaptive(
                value: settings.clipboardDetection,
                title: const Text('تشخیص Clipboard'),
                subtitle: const Text('لینک HTTP/HTTPS کپی‌شده را هنگام بازگشت به برنامه تشخیص می‌دهد.'),
                onChanged: (value) async {
                  await widget.controller.updateSettings(
                    settings.copyWith(clipboardDetection: value),
                  );
                  if (mounted) setState(() {});
                },
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: settings.notifications,
                title: const Text('اعلان دانلود'),
                subtitle: const Text('پیشرفت، توقف و پایان دانلود در اعلان سیستم.'),
                onChanged: (value) async {
                  await widget.controller.updateSettings(
                    settings.copyWith(notifications: value),
                  );
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'محدودیت سرعت',
            children: [
              ListTile(
                title: const Text('سقف سرعت'),
                subtitle: Text(
                  settings.speedLimitKbps <= 0
                      ? 'نامحدود'
                      : '${settings.speedLimitKbps} KB/s',
                ),
              ),
              Slider(
                value: settings.speedLimitKbps.toDouble().clamp(0, 4096),
                min: 0,
                max: 4096,
                divisions: 16,
                label: settings.speedLimitKbps <= 0
                    ? 'نامحدود'
                    : '${settings.speedLimitKbps} KB/s',
                onChanged: (value) async {
                  final rounded = ((value / 256).round() * 256);
                  await widget.controller.updateSettings(
                    settings.copyWith(speedLimitKbps: rounded),
                  );
                  if (mounted) setState(() {});
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  'صفر یعنی بدون محدودیت. محدودیت سرعت در موتور کنترل‌شده تندرو اعمال می‌شود.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}