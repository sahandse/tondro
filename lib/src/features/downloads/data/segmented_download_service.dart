import 'dart:async';
import 'dart:io';

import '../domain/download_item.dart';

class SegmentedDownloadCanceled implements Exception {
  const SegmentedDownloadCanceled();
}

class SegmentedDownloadService {
  final Map<String, List<HttpClient>> _clients = {};
  final Set<String> _canceled = {};

  Future<bool> download({
    required DownloadItem item,
    required int segments,
    required void Function(int received, int total, double speedBytesPerSecond)
        onProgress,
  }) async {
    final segmentCount = segments.clamp(1, 16);
    if (segmentCount <= 1) return false;

    final probe = await _probe(item.url);
    if (!probe.supportsRange || probe.totalBytes <= 0) {
      return false;
    }

    final totalBytes = probe.totalBytes;
    final effectiveSegments = _effectiveSegmentCount(totalBytes, segmentCount);
    if (effectiveSegments <= 1) return false;

    _canceled.remove(item.id);
    _clients[item.id] = [];

    final partFiles = <File>[];
    final downloaded = List<int>.filled(effectiveSegments, 0);
    final ranges = <({int start, int end})>[];

    final baseSize = totalBytes ~/ effectiveSegments;
    var cursor = 0;
    for (var index = 0; index < effectiveSegments; index++) {
      final start = cursor;
      final end = index == effectiveSegments - 1
          ? totalBytes - 1
          : start + baseSize - 1;
      ranges.add((start: start, end: end));
      cursor = end + 1;

      final part = File('${item.savePath}.part.$index');
      partFiles.add(part);
      if (await part.exists()) {
        final expected = end - start + 1;
        final current = await part.length();
        if (current > expected) {
          await part.delete();
        } else {
          downloaded[index] = current;
        }
      }
    }

    var lastTotal = downloaded.fold<int>(0, (a, b) => a + b);
    var lastTick = DateTime.now();
    final speedWatch = Stopwatch()..start();

    try {
      await Future.wait(
        List.generate(effectiveSegments, (index) async {
          final range = ranges[index];
          final part = partFiles[index];
          final expectedLength = range.end - range.start + 1;
          var existing = downloaded[index];
          if (existing >= expectedLength) {
            return;
          }

          final client = HttpClient();
          _clients[item.id]!.add(client);

          IOSink? sink;
          try {
            final request = await client.getUrl(Uri.parse(item.url));
            request.headers.set(
              HttpHeaders.rangeHeader,
              'bytes=${range.start + existing}-${range.end}',
            );
            final response = await request.close();
            if (response.statusCode != HttpStatus.partialContent) {
              throw const HttpException('Range unsupported during segmented download');
            }

            sink = part.openWrite(mode: FileMode.append);

            await for (final chunk in response) {
              if (_canceled.contains(item.id)) {
                throw const SegmentedDownloadCanceled();
              }
              sink.add(chunk);
              existing += chunk.length;
              downloaded[index] = existing;

              final now = DateTime.now();
              final aggregate = downloaded.fold<int>(0, (a, b) => a + b);
              final elapsedMs = now.difference(lastTick).inMilliseconds;
              var speed = 0.0;
              if (elapsedMs >= 350) {
                speed = ((aggregate - lastTotal) * 1000) / elapsedMs;
                lastTotal = aggregate;
                lastTick = now;
              } else if (speedWatch.elapsedMicroseconds > 0) {
                speed = aggregate /
                    (speedWatch.elapsedMicroseconds / Duration.microsecondsPerSecond);
              }

              onProgress(aggregate, totalBytes, speed);
            }

            await sink.flush();
            if (existing != expectedLength) {
              throw const HttpException('Segment length mismatch');
            }
          } finally {
            await sink?.close();
            client.close(force: true);
          }
        }),
      );

      if (_canceled.contains(item.id)) {
        throw const SegmentedDownloadCanceled();
      }

      final output = File(item.savePath);
      if (await output.exists()) {
        await output.delete();
      }
      final sink = output.openWrite(mode: FileMode.write);
      try {
        for (final part in partFiles) {
          await sink.addStream(part.openRead());
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      if (await output.length() != totalBytes) {
        throw const FileSystemException('Merged file size mismatch');
      }

      for (final part in partFiles) {
        if (await part.exists()) {
          await part.delete();
        }
      }
      onProgress(totalBytes, totalBytes, 0);
      return true;
    } finally {
      for (final client in _clients.remove(item.id) ?? <HttpClient>[]) {
        client.close(force: true);
      }
      _canceled.remove(item.id);
    }
  }

  Future<_SegmentProbe> _probe(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
      final response = await request.close();
      await response.drain<void>();

      if (response.statusCode != HttpStatus.partialContent) {
        return const _SegmentProbe(totalBytes: 0, supportsRange: false);
      }

      final contentRange = response.headers.value(HttpHeaders.contentRangeHeader);
      if (contentRange == null) {
        return const _SegmentProbe(totalBytes: 0, supportsRange: false);
      }

      final slash = contentRange.lastIndexOf('/');
      if (slash < 0) {
        return const _SegmentProbe(totalBytes: 0, supportsRange: false);
      }

      final total = int.tryParse(contentRange.substring(slash + 1).trim());
      if (total == null || total <= 0) {
        return const _SegmentProbe(totalBytes: 0, supportsRange: false);
      }

      return _SegmentProbe(totalBytes: total, supportsRange: true);
    } finally {
      client.close(force: true);
    }
  }

  int _effectiveSegmentCount(int totalBytes, int requested) {
    const minSegmentSize = 512 * 1024;
    final bySize = (totalBytes / minSegmentSize).ceil().clamp(1, 16);
    return requested < bySize ? requested : bySize;
  }

  void pause(String id) {
    _canceled.add(id);
    for (final client in _clients.remove(id) ?? <HttpClient>[]) {
      client.close(force: true);
    }
  }
}

class _SegmentProbe {
  const _SegmentProbe({
    required this.totalBytes,
    required this.supportsRange,
  });

  final int totalBytes;
  final bool supportsRange;
}
