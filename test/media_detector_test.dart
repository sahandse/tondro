import 'package:flutter_test/flutter_test.dart';
import 'package:tondro/src/features/browser/domain/media_detector.dart';

void main() {
  test('detects direct downloadable media URLs', () {
    expect(MediaDetector.isDirectDownloadUrl('https://cdn.example.com/a.mp4'), isTrue);
    expect(MediaDetector.isDirectDownloadUrl('https://cdn.example.com/file.zip'), isTrue);
    expect(
      MediaDetector.isDirectDownloadUrl(
        'https://pbs.twimg.com/media/photo?format=jpg&name=large',
      ),
      isTrue,
    );
    expect(MediaDetector.isDirectDownloadUrl('https://example.com/page'), isFalse);
  });

  test('recognizes supported social pages', () {
    expect(MediaDetector.isSupportedSocialPage('https://x.com/user/status/1'), isTrue);
    expect(MediaDetector.isSupportedSocialPage('https://www.reddit.com/r/a/'), isTrue);
    expect(MediaDetector.isSupportedSocialPage('https://youtube.com/watch?v=1'), isFalse);
  });
}
