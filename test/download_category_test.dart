import 'package:flutter_test/flutter_test.dart';
import 'package:tondro/src/features/downloads/domain/download_category.dart';

void main() {
  group('download categories', () {
    test('detects common extensions', () {
      expect(detectDownloadCategory('photo.webp'), DownloadCategory.image);
      expect(detectDownloadCategory('movie.mkv'), DownloadCategory.video);
      expect(detectDownloadCategory('track.mp3'), DownloadCategory.audio);
      expect(detectDownloadCategory('report.pdf'), DownloadCategory.document);
      expect(detectDownloadCategory('files.zip'), DownloadCategory.archive);
      expect(detectDownloadCategory('app.apk'), DownloadCategory.app);
    });

    test('falls back to other', () {
      expect(detectDownloadCategory('README'), DownloadCategory.other);
      expect(detectDownloadCategory('file.unknown'), DownloadCategory.other);
    });
  });
}
