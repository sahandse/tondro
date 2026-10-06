class DownloadSettings {
  const DownloadSettings({
    this.maxConcurrentDownloads = 3,
    this.wifiOnly = false,
    this.autoRetry = 2,
    this.clipboardDetection = true,
    this.notifications = true,
    this.speedLimitKbps = 0,
  });

  final int maxConcurrentDownloads;
  final bool wifiOnly;
  final int autoRetry;
  final bool clipboardDetection;
  final bool notifications;
  final int speedLimitKbps;

  DownloadSettings copyWith({
    int? maxConcurrentDownloads,
    bool? wifiOnly,
    int? autoRetry,
    bool? clipboardDetection,
    bool? notifications,
    int? speedLimitKbps,
  }) {
    return DownloadSettings(
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      autoRetry: autoRetry ?? this.autoRetry,
      clipboardDetection: clipboardDetection ?? this.clipboardDetection,
      notifications: notifications ?? this.notifications,
      speedLimitKbps: speedLimitKbps ?? this.speedLimitKbps,
    );
  }
}
