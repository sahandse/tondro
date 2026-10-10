class MediaDetector {
  static const _extensions = <String>{
    'jpg','jpeg','jpe','png','gif','webp','bmp','svg','heic','heif','avif',
    'tif','tiff','ico','raw','dng','cr2','cr3','nef','arw','psd','ai','eps',
    'mp4','m4v','mkv','webm','mov','avi','3gp','3g2','wmv','flv','f4v',
    'mpeg','mpg','m2v','mts','m2ts','ts','vob','ogv','rm','rmvb','asf','mxf',
    'mp3','m4a','aac','wav','flac','ogg','oga','opus','wma','alac','aiff',
    'ape','amr','mid','midi','mka','ac3','dts','dsf','dff','ra','caf',
    'pdf','doc','docx','docm','dot','dotx','rtf','txt','md','odt','pages',
    'xls','xlsx','xlsm','xlsb','csv','tsv','ods','numbers','ppt','pptx',
    'pptm','pps','ppsx','odp','key','xml','json','yaml','yml','toml','ini',
    'sql','db','sqlite','sqlite3','html','htm','css','js','ts','dart','java',
    'kt','c','cpp','cs','go','rs','py','php','swift','sh','ps1','bat',
    'epub','mobi','azw','azw3','fb2','djvu','cbz','cbr','cb7','lit','pdb',
    'zip','rar','7z','tar','gz','bz2','xz','zst','tgz','tbz','txz','cab',
    'iso','img','dmg','jar','war','deb','rpm',
    'apk','aab','apks','xapk','exe','msi','msix','appx','ipa','appimage',
    'ttf','otf','woff','woff2','eot','ttc',
    'dwg','dxf','step','stp','iges','igs','obj','stl','fbx','gltf','glb',
  };

  static bool isDirectDownloadUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) return false;
    if (uri.pathSegments.isEmpty) return false;

    final last = uri.pathSegments.last.toLowerCase();
    final dot = last.lastIndexOf('.');
    if (dot >= 0 && dot < last.length - 1) {
      if (_extensions.contains(last.substring(dot + 1))) return true;
    }

    final format = uri.queryParameters['format']?.toLowerCase();
    return format != null && _extensions.contains(format);
  }

  static bool isSupportedSocialPage(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) return false;
    final host = uri.host.toLowerCase();
    return host == 'x.com' ||
        host.endsWith('.x.com') ||
        host == 'twitter.com' ||
        host.endsWith('.twitter.com') ||
        host == 'reddit.com' ||
        host.endsWith('.reddit.com');
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
