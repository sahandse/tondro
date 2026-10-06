import 'package:flutter_test/flutter_test.dart';
import 'package:tondro/src/features/downloads/domain/download_item.dart';

void main() {
  test('download item round trips through json', () {
    final scheduledAt = DateTime(2026, 10, 7, 3, 30);
    final item = DownloadItem(
      id: '42',
      url: 'https://example.com/file.zip',
      fileName: 'file.zip',
      savePath: '/downloads/file.zip',
      createdAt: DateTime(2026, 10, 6),
      status: DownloadStatus.queued,
      receivedBytes: 1024,
      totalBytes: 4096,
      retryCount: 1,
      scheduledAt: scheduledAt,
    );

    final restored = DownloadItem.fromJson(item.toJson());

    expect(restored.id, item.id);
    expect(restored.url, item.url);
    expect(restored.fileName, item.fileName);
    expect(restored.receivedBytes, item.receivedBytes);
    expect(restored.totalBytes, item.totalBytes);
    expect(restored.retryCount, item.retryCount);
    expect(restored.scheduledAt, scheduledAt);
  });

  test('calculates progress and eta', () {
    final item = DownloadItem(
      id: '1',
      url: 'https://example.com/a',
      fileName: 'a',
      savePath: '/a',
      createdAt: DateTime(2026),
      receivedBytes: 500,
      totalBytes: 1000,
      speedBytesPerSecond: 100,
    );

    expect(item.progress, 0.5);
    expect(item.eta, const Duration(seconds: 5));
  });
}
