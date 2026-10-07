class MediaDetector {
  static const _extensions = <String>{
    'mp4', 'm4v', 'mkv', 'webm', 'mov', 'avi', '3gp',
    'mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg', 'opus',
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic',
    'pdf', 'epub', 'zip', 'rar', '7z', 'apk',
  };

  static bool isDirectDownloadUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) return false;
    if (uri.pathSegments.isEmpty) return false;

    final last = uri.pathSegments.last.toLowerCase();
    final dot = last.lastIndexOf('.');
    if (dot < 0 || dot == last.length - 1) return false;
    return _extensions.contains(last.substring(dot + 1));
  }

  static List<String> extractDirectUrls(Iterable<String> values) {
    final unique = <String>{};
    for (final value in values) {
      if (isDirectDownloadUrl(value)) {
        unique.add(value);
      }
    }
    return unique.toList();
  }
}
