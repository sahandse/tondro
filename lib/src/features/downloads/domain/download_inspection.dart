class DownloadInspection {
  const DownloadInspection({
    required this.url,
    required this.fileName,
    required this.totalBytes,
    required this.mimeType,
    required this.supportsRange,
  });

  final String url;
  final String fileName;
  final int totalBytes;
  final String? mimeType;
  final bool supportsRange;
}