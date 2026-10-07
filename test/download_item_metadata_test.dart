import 'package:flutter_test/flutter_test.dart';
import 'package:tondro/src/features/downloads/domain/download_item.dart';

void main() {
  test('persists MIME Range folder and checksum metadata', () {
    final item = DownloadItem(
      id: '1',
      url: 'https://example.com/a.zip',
      fileName: 'a.zip',
      savePath: '/downloads/a.zip',
      createdAt: DateTime(2026, 10, 7),
      relativeDirectory: 'downloads/Archives',
      mimeType: 'application/zip',
      supportsRange: true,
      expectedSha256: 'a' * 64,
      computedSha256: 'b' * 64,
    );

    final restored = DownloadItem.fromJson(item.toJson());
    expect(restored.relativeDirectory, 'downloads/Archives');
    expect(restored.mimeType, 'application/zip');
    expect(restored.supportsRange, isTrue);
    expect(restored.expectedSha256, 'a' * 64);
    expect(restored.computedSha256, 'b' * 64);
  });
}
