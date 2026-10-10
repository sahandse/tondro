enum NetworkProfilePreset {
  balanced,
  wifiFast,
  dataSaver,
  custom,
}

String networkProfileLabelFa(NetworkProfilePreset value) => switch (value) {
      NetworkProfilePreset.balanced => 'متعادل',
      NetworkProfilePreset.wifiFast => 'Wi-Fi سریع',
      NetworkProfilePreset.dataSaver => 'صرفه‌جویی دیتا',
      NetworkProfilePreset.custom => 'سفارشی',
    };

enum CompletionAction {
  notify,
  open,
  none,
}

String completionActionLabelFa(CompletionAction value) => switch (value) {
      CompletionAction.notify => 'فقط اعلان',
      CompletionAction.open => 'بازکردن فایل',
      CompletionAction.none => 'هیچ‌کاری',
    };

class DownloadSettings {
  const DownloadSettings({
    this.maxConcurrentDownloads = 3,
    this.wifiOnly = false,
    this.autoRetry = 2,
    this.clipboardDetection = true,
    this.notifications = true,
    this.speedLimitKbps = 0,
    this.maxSegments = 4,
    this.smartSegments = true,
    this.networkProfile = NetworkProfilePreset.balanced,
    this.completionAction = CompletionAction.notify,
    this.pauseOnLowBattery = false,
    this.lowBatteryThreshold = 15,
  });

  final int maxConcurrentDownloads;
  final bool wifiOnly;
  final int autoRetry;
  final bool clipboardDetection;
  final bool notifications;
  final int speedLimitKbps;
  final int maxSegments;
  final bool smartSegments;
  final NetworkProfilePreset networkProfile;
  final CompletionAction completionAction;
  final bool pauseOnLowBattery;
  final int lowBatteryThreshold;

  DownloadSettings copyWith({
    int? maxConcurrentDownloads,
    bool? wifiOnly,
    int? autoRetry,
    bool? clipboardDetection,
    bool? notifications,
    int? speedLimitKbps,
    int? maxSegments,
    bool? smartSegments,
    NetworkProfilePreset? networkProfile,
    CompletionAction? completionAction,
    bool? pauseOnLowBattery,
    int? lowBatteryThreshold,
  }) {
    return DownloadSettings(
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      autoRetry: autoRetry ?? this.autoRetry,
      clipboardDetection: clipboardDetection ?? this.clipboardDetection,
      notifications: notifications ?? this.notifications,
      speedLimitKbps: speedLimitKbps ?? this.speedLimitKbps,
      maxSegments: maxSegments ?? this.maxSegments,
      smartSegments: smartSegments ?? this.smartSegments,
      networkProfile: networkProfile ?? this.networkProfile,
      completionAction: completionAction ?? this.completionAction,
      pauseOnLowBattery: pauseOnLowBattery ?? this.pauseOnLowBattery,
      lowBatteryThreshold: lowBatteryThreshold ?? this.lowBatteryThreshold,
    );
  }
}
