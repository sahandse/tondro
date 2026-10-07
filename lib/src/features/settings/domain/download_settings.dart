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
  });

  final int maxConcurrentDownloads;
  final bool wifiOnly;
  final int autoRetry;
  final bool clipboardDetection;
  final bool notifications;
  final int speedLimitKbps;
  final int maxSegments;
  final bool smartSegments;

  DownloadSettings copyWith({
    int? maxConcurrentDownloads,
    bool? wifiOnly,
    int? autoRetry,
    bool? clipboardDetection,
    bool? notifications,
    int? speedLimitKbps,
    int? maxSegments,
    bool? smartSegments,
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
    );
  }
}
