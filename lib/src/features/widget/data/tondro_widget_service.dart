import 'dart:async';

import 'package:home_widget/home_widget.dart';

import '../../downloads/domain/download_item.dart';

class TondroWidgetService {
  static const qualifiedAndroidName =
      'ir.tondro.tondro.TondroWidgetProvider';

  Future<void> update(List<DownloadItem> items) async {
    final active =
        items.where((item) => item.status == DownloadStatus.downloading).toList();
    final paused =
        items.where((item) => item.status == DownloadStatus.paused).toList();
    final speed = active.fold<double>(
      0,
      (sum, item) => sum + item.speedBytesPerSecond,
    );

    final current = active.isNotEmpty
        ? active.first
        : paused.isNotEmpty
            ? paused.first
            : null;

    await Future.wait([
      HomeWidget.saveWidgetData<int>('active_count', active.length),
      HomeWidget.saveWidgetData<String>(
        'current_file',
        current?.fileName ?? 'دانلود فعالی نیست',
      ),
      HomeWidget.saveWidgetData<String>(
        'speed_text',
        _formatSpeed(speed),
      ),
      HomeWidget.saveWidgetData<bool>('has_active', active.isNotEmpty),
      HomeWidget.saveWidgetData<bool>('has_paused', paused.isNotEmpty),
    ]);

    await HomeWidget.updateWidget(
      qualifiedAndroidName: qualifiedAndroidName,
    );
  }

  Future<void> requestPin() => HomeWidget.requestPinWidget(
        qualifiedAndroidName: qualifiedAndroidName,
      );

  Future<Uri?> initialLaunch() => HomeWidget.initiallyLaunchedFromHomeWidget();

  Stream<Uri?> get clicks => HomeWidget.widgetClicked;

  String _formatSpeed(double value) {
    if (value <= 0) return '0 KB/s';
    if (value >= 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    if (value >= 1024) {
      return '${(value / 1024).toStringAsFixed(0)} KB/s';
    }
    return '${value.toStringAsFixed(0)} B/s';
  }
}