import 'package:flutter/material.dart';

import '../../../app/theme/theme_controller.dart';
import '../../backup/data/app_backup_service.dart';
import '../../downloads/presentation/downloads_controller.dart';
import '../../site_profiles/presentation/site_profiles_page.dart';
import '../../torrent/presentation/torrent_page.dart';
import '../domain/download_settings.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _SettingsGroup(
            title: 'اصلی',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: DropdownButtonFormField<NetworkProfilePreset>(
                  initialValue: settings.networkProfile,
                  decoration: const InputDecoration(
                    labelText: 'حالت شبکه',
                    prefixIcon: Icon(Icons.network_check_rounded),
                  ),
                  items: NetworkProfilePreset.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(networkProfileLabelFa(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    await widget.controller.applyNetworkProfile(value);
                    if (mounted) setState(() {});
                  },
                ),
              ),
              SwitchListTile.adaptive(
                value: settings.wifiOnly,
                title: const Text('فقط Wi‑Fi'),
                subtitle: const Text('روی اینترنت موبایل دانلود شروع نشود.'),
                onChanged: (value) async {
                  await widget.controller.updateSettings(
                    settings.copyWith(wifiOnly: value),
                  );
                  if (mounted) setState(() {});
                },
              ),
              SwitchListTile.adaptive(
                value: settings.clipboardDetection,
                title: const Text('تشخیص لینک کپی‌شده'),
                onChanged: (value) async {
                  await widget.controller.updateSettings(
                    settings.copyWith(clipboardDetection: value),
                  );
                  if (mounted) setState(() {});
                },
              ),
              SwitchListTile.adaptive(
                value: settings.notifications,
                title: const Text('اعلان دانلود'),
                onChanged: (value) async {
                  await widget.controller.updateSettings(
                    settings.copyWith(notifications: value),
                  );
                  if (mounted) setState(() {});
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: DropdownButtonFormField<CompletionAction>(
                  initialValue: settings.completionAction,
                  decoration: const InputDecoration(
                    labelText: 'بعد از پایان دانلود',
                    prefixIcon: Icon(Icons.done_all_rounded),
                  ),
                  items: CompletionAction.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(completionActionLabelFa(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    await widget.controller.updateSettings(
                      settings.copyWith(completionAction: value),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            title: 'پیشرفته',
            children: [
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                leading: const Icon(Icons.tune_rounded),
                title: const Text('تنظیمات موتور دانلود'),
                subtitle: const Text('اتصال، Segment، Retry و سرعت'),
                children: [
                  _NumberSetting(
                    title: 'دانلود هم‌زمان',
                    value: settings.maxConcurrentDownloads,
                    values: const [1, 2, 3, 4, 5],
                    onChanged: (value) async {
                      await widget.controller.updateSettings(
                        settings.copyWith(maxConcurrentDownloads: value),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                  _NumberSetting(
                    title: 'اتصال هر فایل',
                    value: settings.maxSegments,
                    values: const [1, 2, 4, 8, 16],
                    onChanged: (value) async {
                      await widget.controller.updateSettings(
                        settings.copyWith(maxSegments: value),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: settings.smartSegments,
                    title: const Text('Smart Segments'),
                    subtitle: const Text('تعداد اتصال را خودکار تنظیم کند.'),
                    onChanged: (value) async {
                      await widget.controller.updateSettings(
                        settings.copyWith(smartSegments: value),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                  _NumberSetting(
                    title: 'تلاش دوباره',
                    value: settings.autoRetry,
                    values: const [0, 1, 2, 3, 4, 5],
                    onChanged: (value) async {
                      await widget.controller.updateSettings(
                        settings.copyWith(autoRetry: value),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                  ListTile(
                    title: const Text('محدودیت سرعت'),
                    subtitle: Text(
                      settings.speedLimitKbps <= 0
                          ? 'نامحدود'
                          : '${settings.speedLimitKbps} KB/s',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Slider(
                      value: settings.speedLimitKbps.toDouble().clamp(0, 4096),
                      min: 0,
                      max: 4096,
                      divisions: 16,
                      onChanged: (value) async {
                        final rounded = ((value / 256).round() * 256);
                        await widget.controller.updateSettings(
                          settings.copyWith(speedLimitKbps: rounded),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('پروفایل سایت‌ها'),
                subtitle: Text('${widget.controller.siteProfiles.length} پروفایل'),
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
              ListTile(
                leading: const Icon(Icons.hub_outlined),
                title: const Text('Torrent / Magnet'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TorrentPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            title: 'ابزارها',
            children: [
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                leading: const Icon(Icons.palette_outlined),
                title: const Text('ظاهر برنامه'),
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
                          title: Text('سیستم'),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.light,
                          title: Text('روشن'),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.dark,
                          title: Text('تیره'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.widgets_outlined),
                title: const Text('افزودن ویجت'),
                onTap: widget.controller.requestHomeWidget,
              ),
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('خروجی بکاپ'),
                onTap: () async {
                  final uri = await AppBackupService().exportBackup();
                  if (!context.mounted || uri == null) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('بکاپ ذخیره شد')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore_rounded),
                title: const Text('بازیابی بکاپ'),
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
                          '${result.downloads} دانلود و ${result.profiles} پروفایل بازیابی شد',
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
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 7),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: .45),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _NumberSetting extends StatelessWidget {
  const _NumberSetting({
    required this.title,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String title;
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<int>(
        value: value,
        underline: const SizedBox.shrink(),
        items: values
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text('$item'),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}