import 'dart:convert';

enum DownloadStatus { queued, downloading, paused, completed, failed }

class DownloadItem {
  const DownloadItem({
    required this.id,
    required this.url,
    required this.fileName,
    required this.savePath,
    required this.createdAt,
    this.status = DownloadStatus.queued,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSecond = 0,
    this.retryCount = 0,
    this.errorMessage,
  });

  final String id;
  final String url;
  final String fileName;
  final String savePath;
  final DateTime createdAt;
  final DownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final double speedBytesPerSecond;
  final int retryCount;
  final String? errorMessage;

  double get progress => totalBytes <= 0 ? 0 : receivedBytes / totalBytes;

  Duration? get eta {
    if (speedBytesPerSecond <= 0 || totalBytes <= receivedBytes) return null;
    final seconds = (totalBytes - receivedBytes) / speedBytesPerSecond;
    return Duration(seconds: seconds.ceil());
  }

  DownloadItem copyWith({
    DownloadStatus? status,
    int? receivedBytes,
    int? totalBytes,
    double? speedBytesPerSecond,
    int? retryCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadItem(
      id: id,
      url: url,
      fileName: fileName,
      savePath: savePath,
      createdAt: createdAt,
      status: status ?? this.status,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
        'fileName': fileName,
        'savePath': savePath,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'receivedBytes': receivedBytes,
        'totalBytes': totalBytes,
        'retryCount': retryCount,
        'errorMessage': errorMessage,
      };

  factory DownloadItem.fromMap(Map<String, dynamic> map) => DownloadItem(
        id: map['id'] as String,
        url: map['url'] as String,
        fileName: map['fileName'] as String,
        savePath: map['savePath'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        status: DownloadStatus.values.firstWhere(
          (value) => value.name == map['status'],
          orElse: () => DownloadStatus.paused,
        ),
        receivedBytes: (map['receivedBytes'] as num?)?.toInt() ?? 0,
        totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
        retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
        errorMessage: map['errorMessage'] as String?,
      );

  String toJson() => jsonEncode(toMap());
  factory DownloadItem.fromJson(String source) =>
      DownloadItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
