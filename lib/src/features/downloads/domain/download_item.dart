import 'dart:convert';

enum DownloadStatus { queued, downloading, paused, completed, failed }

class DownloadItem {
  const DownloadItem({
    required this.id,
    required this.url,
    required this.fileName,
    required this.savePath,
    required this.createdAt,
    this.relativeDirectory,
    this.mimeType,
    this.supportsRange = false,
    this.expectedSha256,
    this.computedSha256,
    this.status = DownloadStatus.queued,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSecond = 0,
    this.retryCount = 0,
    this.scheduledAt,
    this.errorMessage,
  });

  final String id;
  final String url;
  final String fileName;
  final String savePath;
  final DateTime createdAt;
  final String? relativeDirectory;
  final String? mimeType;
  final bool supportsRange;
  final String? expectedSha256;
  final String? computedSha256;
  final DownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final double speedBytesPerSecond;
  final int retryCount;
  final DateTime? scheduledAt;
  final String? errorMessage;

  double get progress => totalBytes <= 0 ? 0 : receivedBytes / totalBytes;

  Duration? get eta {
    if (speedBytesPerSecond <= 0 || totalBytes <= receivedBytes) return null;
    final seconds = (totalBytes - receivedBytes) / speedBytesPerSecond;
    return Duration(seconds: seconds.ceil());
  }

  DownloadItem copyWith({
    String? savePath,
    DownloadStatus? status,
    String? relativeDirectory,
    String? mimeType,
    bool? supportsRange,
    String? expectedSha256,
    String? computedSha256,
    bool clearComputedSha256 = false,
    int? receivedBytes,
    int? totalBytes,
    double? speedBytesPerSecond,
    int? retryCount,
    DateTime? scheduledAt,
    bool clearSchedule = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadItem(
      id: id,
      url: url,
      fileName: fileName,
      savePath: savePath ?? this.savePath,
      createdAt: createdAt,
      relativeDirectory: relativeDirectory ?? this.relativeDirectory,
      mimeType: mimeType ?? this.mimeType,
      supportsRange: supportsRange ?? this.supportsRange,
      expectedSha256: expectedSha256 ?? this.expectedSha256,
      computedSha256: clearComputedSha256
          ? null
          : computedSha256 ?? this.computedSha256,
      status: status ?? this.status,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      retryCount: retryCount ?? this.retryCount,
      scheduledAt: clearSchedule ? null : scheduledAt ?? this.scheduledAt,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
        'fileName': fileName,
        'savePath': savePath,
        'createdAt': createdAt.toIso8601String(),
        'relativeDirectory': relativeDirectory,
        'mimeType': mimeType,
        'supportsRange': supportsRange,
        'expectedSha256': expectedSha256,
        'computedSha256': computedSha256,
        'status': status.name,
        'receivedBytes': receivedBytes,
        'totalBytes': totalBytes,
        'retryCount': retryCount,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'errorMessage': errorMessage,
      };

  factory DownloadItem.fromMap(Map<String, dynamic> map) => DownloadItem(
        id: map['id'] as String,
        url: map['url'] as String,
        fileName: map['fileName'] as String,
        savePath: map['savePath'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        relativeDirectory: map['relativeDirectory'] as String?,
        mimeType: map['mimeType'] as String?,
        supportsRange: map['supportsRange'] as bool? ?? false,
        expectedSha256: map['expectedSha256'] as String?,
        computedSha256: map['computedSha256'] as String?,
        status: DownloadStatus.values.firstWhere(
          (value) => value.name == map['status'],
          orElse: () => DownloadStatus.paused,
        ),
        receivedBytes: (map['receivedBytes'] as num?)?.toInt() ?? 0,
        totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
        retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
        scheduledAt: map['scheduledAt'] == null
            ? null
            : DateTime.tryParse(map['scheduledAt'] as String),
        errorMessage: map['errorMessage'] as String?,
      );

  String toJson() => jsonEncode(toMap());
  factory DownloadItem.fromJson(String source) =>
      DownloadItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
