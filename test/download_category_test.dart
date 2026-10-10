import 'package:flutter_test/flutter_test.dart';
import 'package:tondro/src/features/downloads/domain/download_category.dart';

void main() {
  group('download categories', () {
    test('detects common and extended extensions', () {
      expect(detectDownloadCategory('photo.webp'), DownloadCategory.image);
      expect(detectDownloadCategory('movie.mkv'), DownloadCategory.video);
      expect(detectDownloadCategory('track.flac'), DownloadCategory.audio);
      expect(detectDownloadCategory('report.docx'), DownloadCategory.document);
      expect(detectDownloadCategory('sheet.xlsx'), DownloadCategory.document);
      expect(detectDownloadCategory('book.epub'), DownloadCategory.book);
      expect(detectDownloadCategory('font.woff2'), DownloadCategory.font);
      expect(detectDownloadCategory('files.7z'), DownloadCategory.archive);
      expect(detectDownloadCategory('app.xapk'), DownloadCategory.app);
      expect(detectDownloadCategory('model.glb'), DownloadCategory.document);
    });

    test('uses public Tondro folder names', () {
      expect(categoryFolderName(DownloadCategory.audio), 'Music');
      expect(categoryFolderName(DownloadCategory.video), 'Videos');
      expect(categoryFolderName(DownloadCategory.document), 'Documents');
      expect(categoryFolderName(DownloadCategory.book), 'Books');
      expect(categoryFolderName(DownloadCategory.app), 'Apps');
      expect(categoryFolderName(DownloadCategory.font), 'Fonts');
    });

    test('returns useful mime types', () {
      expect(mimeTypeForFileName('manual.pdf'), 'application/pdf');
      expect(
        mimeTypeForFileName('app.apk'),
        'application/vnd.android.package-archive',
      );
      expect(mimeTypeForFileName('font.ttf'), 'font/ttf');
      expect(mimeTypeForFileName('movie.mkv'), 'video/x-matroska');
      expect(mimeTypeForFileName('song.flac'), 'audio/flac');
    });

    test('falls back to other', () {
      expect(detectDownloadCategory('README'), DownloadCategory.other);
      expect(detectDownloadCategory('file.unknown'), DownloadCategory.other);
    });
  });
}
