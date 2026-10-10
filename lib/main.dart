import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'تندرو',
        locale: const Locale('fa'),
        supportedLocales: const [Locale('fa')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeController.instance.mode,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: HomePage(),
        ),
      ),
    );
  }
}
