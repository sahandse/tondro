import 'package:flutter/material.dart';

import '../../../app/widgets/tondro_brand.dart';
import '../../downloads/presentation/downloads_controller.dart';
import '../domain/site_profile.dart';

class SiteProfilesPage extends StatefulWidget {
  const SiteProfilesPage({
    super.key,
    required this.controller,
  });

  final DownloadsController controller;

  @override
  State<SiteProfilesPage> createState() => _SiteProfilesPageState();
}

class _SiteProfilesPageState extends State<SiteProfilesPage> {
  Future<void> _edit([SiteProfile? profile]) async {
    final host = TextEditingController(text: profile?.host ?? '');
    final folder = TextEditingController(text: profile?.folderName ?? '');
    final userAgent = TextEditingController(text: profile?.userAgent ?? '');
    final referer = TextEditingController(text: profile?.referer ?? '');
    final cookie = TextEditingController(text: profile?.cookie ?? '');
    final headers = TextEditingController(
      text: (profile?.headers.entries ??
              const Iterable<MapEntry<String, String>>.empty())
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n'),
    );
    var segments = profile?.maxSegments ?? 4;

    final result = await showModalBottomSheet<SiteProfile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: XpWindowFrame(
                title: profile == null ? 'New Site Profile' : 'Edit Site Profile',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: host,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'دامنه',
                        hintText: 'example.com',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: folder,
                      decoration: const InputDecoration(
                        labelText: 'پوشه اختصاصی',
                        hintText: 'مثلاً Videos',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: segments,
                      decoration: const InputDecoration(
                        labelText: 'تعداد Segment',
                      ),
                      items: const [1, 2, 4, 8, 16]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => segments = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: userAgent,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'User-Agent',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: referer,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'Referer',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cookie,
                      textDirection: TextDirection.ltr,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Cookie',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: headers,
                      textDirection: TextDirection.ltr,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Headerهای سفارشی',
                        hintText: 'X-Token: value',
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () {
                        final normalizedHost = host.text
                            .trim()
                            .replaceFirst(RegExp(r'^https?://'), '')
                            .split('/')
                            .first
                            .toLowerCase();
                        if (normalizedHost.isEmpty) return;

                        Navigator.pop(
                          context,
                          SiteProfile(
                            id: profile?.id ??
                                DateTime.now().microsecondsSinceEpoch.toString(),
                            host: normalizedHost,
                            folderName: _emptyToNull(folder.text),
                            userAgent: _emptyToNull(userAgent.text),
                            referer: _emptyToNull(referer.text),
                            cookie: _emptyToNull(cookie.text),
                            headers: _parseHeaders(headers.text),
                            maxSegments: segments,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('ذخیره پروفایل'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    host.dispose();
    folder.dispose();
    userAgent.dispose();
    referer.dispose();
    cookie.dispose();
    headers.dispose();

    if (result == null) return;
    await widget.controller.saveSiteProfile(result);
    if (mounted) setState(() {});
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Map<String, String> _parseHeaders(String value) {
    final result = <String, String>{};
    for (final line in value.split('\n')) {
      final separator = line.indexOf(':');
      if (separator <= 0) continue;
      final name = line.substring(0, separator).trim();
      final headerValue = line.substring(separator + 1).trim();
      if (name.isNotEmpty && headerValue.isNotEmpty) {
        result[name] = headerValue;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final profiles = widget.controller.siteProfiles;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            TondroLogo(size: 32),
            SizedBox(width: 10),
            Text('Site Profiles'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add_rounded),
      ),
      body: profiles.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'هنوز پروفایلی ساخته نشده.\nبرای سایت‌هایی که Header یا تنظیمات خاص می‌خواهند پروفایل بساز.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return XpWindowFrame(
                  title: profile.host,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language_rounded),
                    title: Text(profile.host),
                    subtitle: Text(
                      '${profile.maxSegments ?? 4} بخش'
                      '${profile.folderName == null ? '' : ' • ${profile.folderName}'}',
                    ),
                    onTap: () => _edit(profile),
                    trailing: IconButton(
                      tooltip: 'حذف',
                      onPressed: () async {
                        await widget.controller.deleteSiteProfile(profile.id);
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                );
              },
            ),
    );
  }
}