import 'dart:async';
import 'dart:io';

import '../domain/download_item.dart';

class ThrottledDownloadCanceled implements Exception {
  const ThrottledDownloadCanceled();
}

class ThrottledDownloadService {
  final Map<String, HttpClient> _clients = {};
  final Set<String> _canceled = {};

  Future<void> download({
    required DownloadItem item,
    required int speedLimitKbps,
    Map<String, String> headers = const {},
    required void Function(int received, int total, double speedBytesPerSecond)
        onProgress,
  }) async {
    final file = File(item.savePath);
    final existingBytes = await file.exists() ? await file.length() : 0;
    final client = HttpClient();
    _clients[item.id] = client;
    _canceled.remove(item.id);

    IOSink? sink;
    try {
      final request = await client.getUrl(Uri.parse(item.url));
      headers.forEach(request.headers.set);
      if (existingBytes > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
      }
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'HTTP ${response.statusCode}',
          uri: Uri.parse(item.url),
        );
      }

      final canResume = existingBytes > 0 && response.statusCode == HttpStatus.partialContent;
      final resumedBytes = canResume ? existingBytes : 0;
      final total = response.contentLength > 0
          ? resumedBytes + response.contentLength
          : 0;
      sink = file.openWrite(
        mode: canResume ? FileMode.append : FileMode.write,
      );

      var received = resumedBytes;
      var sessionBytes = 0;
      var lastBytes = received;
      var lastTick = DateTime.now();
      final stopwatch = Stopwatch()..start();

      await for (final chunk in response) {
        if (_canceled.contains(item.id)) {
          throw const ThrottledDownloadCanceled();
        }

        sink.add(chunk);
        received += chunk.length;
        sessionBytes += chunk.length;

        final now = DateTime.now();
        final elapsedMs = now.difference(lastTick).inMilliseconds;
        var speed = 0.0;
        if (elapsedMs >= 400) {
          speed = ((received - lastBytes) * 1000) / elapsedMs;
          lastBytes = received;
          lastTick = now;
        }
        onProgress(received, total, speed);

        if (speedLimitKbps > 0) {
          final bytesPerSecond = speedLimitKbps * 1024;
          final expectedMicros =
              ((sessionBytes / bytesPerSecond) * 1000000).round();
          final delayMicros = expectedMicros - stopwatch.elapsedMicroseconds;
          if (delayMicros > 0) {
            await Future<void>.delayed(Duration(microseconds: delayMicros));
          }
        }
      }
      await sink.flush();
    } finally {
      await sink?.close();
      client.close(force: true);
      _clients.remove(item.id);
      _canceled.remove(item.id);
    }
  }

  void pause(String id) {
    _canceled.add(id);
    _clients.remove(id)?.close(force: true);
  }
}