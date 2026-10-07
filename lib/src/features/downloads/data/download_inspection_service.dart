import 'dart:io';

import '../domain/download_inspection.dart';

class DownloadInspectionService {
  Future<DownloadInspection> inspect(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    final uri = Uri.parse(url);
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers.forEach((name, value) => request.headers.set(name, value));
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
      final response = await request.close();

      final supportsRange = response.statusCode == HttpStatus.partialContent;
      final contentRange =
          response.headers.value(HttpHeaders.contentRangeHeader);
      final totalFromRange = _totalFromContentRange(contentRange);
      final totalBytes = totalFromRange ??
          (response.contentLength > 0 ? response.contentLength : 0);
      final mimeType = response.headers.contentType?.mimeType;
      final fileName = _fileNameFromDisposition(
            response.headers.value(HttpHeaders.contentDispositionHeader),
          ) ??
          _fileNameFromUri(uri);

      await response.drain<void>();

      return DownloadInspection(
        url: url,
        fileName: fileName,
        totalBytes: totalBytes,
        mimeType: mimeType,
        supportsRange: supportsRange,
      );
    } finally {
      client.close(force: true);
    }
  }

  int? _totalFromContentRange(String? value) {
    if (value == null) return null;
    final slash = value.lastIndexOf('/');
    if (slash < 0) return null;
    return int.tryParse(value.substring(slash + 1).trim());
  }

  String? _fileNameFromDisposition(String? value) {
    if (value == null) return null;
    final utf = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(value);
    if (utf != null) {
      return Uri.decodeComponent(utf.group(1) ?? '');
    }
    final simple = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(value);
    return simple?.group(1)?.trim();
  }

  String _fileNameFromUri(Uri uri) {
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.last);
    }
    return 'download-${DateTime.now().millisecondsSinceEpoch}';
  }
}