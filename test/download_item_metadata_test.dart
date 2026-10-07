import 'package:flutter_test/flutter_test.dart';
import 'package:tondro/src/features/downloads/domain/download_item.dart';

void main() {
  test('persists MIME Range folder and checksum metadata', () {
    final expected = List.filled(64, 'a').join();
    final computed = List.filled(64, 'b').join();
    final item = DownloadItem(
      id: '1',
      url: 'https://example.com/a.zip',
      fileName: 'a.zip',
      savePath: '/downloads/a.zip',
      createdAt: DateTime(2026, 10, 7),
      relativeDirectory: 'downloads/Archives',
      mimeType: 'application/zip',
      supportsRange: true,
      expectedSha256: expected,
      computedSha256: computed,
    );

    final restored = DownloadItem.fromJson(item.toJson());
    expect(restored.relativeDirectory, 'downloads/Archives');
    expect(restored.mimeType, 'application/zip');
    expect(restored.supportsRange, isTrue);
    expect(restored.expectedSha256, expected);
    expect(restored.computedSha256, computed);
  });
}
