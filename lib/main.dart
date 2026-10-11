import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import 'src/app/theme/app_theme.dart';
import 'src/app/theme/theme_controller.dart';
import 'src/features/home/presentation/home_page.dart';
import 'src/features/downloads/data/scheduled_download_worker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.init();
  await ScheduledDownloadWorker.initialize();
  runApp(const TondroApp());
}

class TondroApp extends StatelessWidget {
  const TondroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final preset = ThemeController.instance.preset;
        final darkTheme = switch (preset) {
          TondroThemePreset.amoled => AppTheme.amoled(),
          TondroThemePreset.ocean => AppTheme.ocean(),
          _ => AppTheme.dark(),
        };
        return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'تندرو',
        locale: const Locale('fa'),
        supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
        localizationsDelegates: const [
          PersianMaterialLocalizations.delegate,
          PersianCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        darkTheme: darkTheme,
        themeMode: ThemeController.instance.mode,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: HomePage(),
        ),
      );
      },
    );
  }
}
