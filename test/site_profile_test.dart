import 'package:flutter_test/flutter_test.dart';
import 'package:tondro/src/features/site_profiles/domain/site_profile.dart';

void main() {
  test('matches host and subdomains and builds request headers', () {
    const profile = SiteProfile(
      id: '1',
      host: 'example.com',
      userAgent: 'Tondro',
      referer: 'https://example.com/',
      cookie: 'sid=1',
      headers: {'X-Test': 'yes'},
      maxSegments: 8,
    );

    expect(profile.matchesHost('example.com'), isTrue);
    expect(profile.matchesHost('cdn.example.com'), isTrue);
    expect(profile.matchesHost('notexample.com'), isFalse);
    expect(profile.requestHeaders['User-Agent'], 'Tondro');
    expect(profile.requestHeaders['Referer'], 'https://example.com/');
    expect(profile.requestHeaders['Cookie'], 'sid=1');
    expect(profile.requestHeaders['X-Test'], 'yes');
  });
}
