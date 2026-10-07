import 'package:flutter/material.dart';

import '../../../app/theme/theme_controller.dart';
import '../../backup/data/app_backup_service.dart';
import '../../../app/widgets/tondro_brand.dart';
import '../../downloads/presentation/downloads_controller.dart';
import '../../site_profiles/presentation/site_profiles_page.dart';

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
      appBar: AppBar(
        title: const Row(
          children: [
            TondroLogo(size: 34),
            SizedBox(width: 10),
            Text('Control Panel'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionCard(
            title: 'ظاهر',
            children: [
              RadioGroup<ThemeMode>(
                groupValue: ThemeController.instance.mode,
                onChanged: (value) async {
                  if (value == null) return;
                  await ThemeController.instance.setMode(value);
                  if (mounted) setState(() {});
                },
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      title: Text('خودکار (سیستم)'),
                      secondary: Icon(Icons.brightness_auto_rounded),
                    ),
                    Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      title: Text('سفید'),
                      secondary: Icon(Icons.light_mode_rounded),
                    ),
                    Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      title: Text('مشکی'),
                      secondary: Icon(Icons.dark_mode_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
              const Divider(height: 1),              ListTile(
                title: const Text('اتصال‌های هر فایل'),
                subtitle: Text('${settings.maxSegments} بخش موازی'),
                trailing: DropdownButton<int>(
                  value: settings.maxSegments,
                  underline: const SizedBox.shrink(),
                  items: const [1, 2, 4, 8, 16]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    await widget.controller.updateSettings(
                      settings.copyWith(maxSegments: value),
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
            title: 'سایت‌ها',
            children: [
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('Site Profiles'),
                subtitle: Text(
                  '${widget.controller.siteProfiles.length} پروفایل ذخیره‌شده',
                ),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SiteProfilesPage(
                        controller: widget.controller,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
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
            title: 'پشتیبان‌گیری',
            children: [
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('خروجی بکاپ'),
                subtitle: const Text(
                  'تنظیمات، Site Profiles و تاریخچه دانلودها',
                ),
                onTap: () async {
                  final uri = await AppBackupService().exportBackup();
                  if (!context.mounted || uri == null) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('بکاپ ذخیره شد')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restore_rounded),
                title: const Text('بازیابی بکاپ'),
                subtitle: const Text('بازیابی فایل JSON تندرو'),
                onTap: () async {
                  try {
                    final result = await AppBackupService().importBackup();
                    if (result == null) return;
                    await widget.controller.reloadFromStores();
                    if (!context.mounted) return;
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${result.downloads} دانلود و '
                          '${result.profiles} پروفایل بازیابی شد',
                        ),
                      ),
                    );
                  } on FormatException catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.message)),
                    );
                  }
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
    return XpWindowFrame(
      title: title,
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}