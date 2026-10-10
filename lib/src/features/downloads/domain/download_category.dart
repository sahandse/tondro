enum DownloadCategory {
  image,
  video,
  audio,
  document,
  book,
  archive,
  app,
  font,
  other,
}

String fileExtension(String fileName) {
  final clean = fileName.split('?').first.split('#').first;
  final dot = clean.lastIndexOf('.');
  return dot >= 0 ? clean.substring(dot + 1).toLowerCase() : '';
}

DownloadCategory detectDownloadCategory(String fileName) {
  final ext = fileExtension(fileName);

  const images = {
    'jpg','jpeg','jpe','png','gif','webp','bmp','dib','svg','svgz','heic',
    'heif','avif','tif','tiff','ico','icns','raw','dng','cr2','cr3','nef',
    'arw','orf','rw2','raf','psd','xcf','ai','eps','jp2','j2k','jpf','jpx',
  };
  const videos = {
    'mp4','m4v','mkv','webm','mov','avi','3gp','3g2','wmv','flv','f4v',
    'mpeg','mpg','mpe','mpv','m2v','mts','m2ts','ts','vob','ogv','rm','rmvb',
    'asf','divx','mxf','qt',
  };
  const audio = {
    'mp3','m4a','aac','wav','flac','ogg','oga','opus','wma','alac','aiff',
    'aif','aifc','ape','amr','mid','midi','mka','ac3','dts','dsf','dff',
    'ra','caf','pcm',
  };
  const docs = {
    'pdf','doc','docx','docm','dot','dotx','rtf','txt','text','md','markdown',
    'odt','ott','pages','xls','xlsx','xlsm','xlsb','csv','tsv','ods','numbers',
    'ppt','pptx','pptm','pps','ppsx','odp','key','xml','json','yaml','yml',
    'toml','ini','cfg','conf','log','sql','db','sqlite','sqlite3','mdb','accdb',
    'html','htm','xhtml','css','js','mjs','ts','tsx','jsx','dart','java','kt',
    'kts','c','h','cpp','hpp','cc','cs','go','rs','py','rb','php','swift',
    'sh','bash','zsh','ps1','bat','cmd','tex','bib','ics','vcf','eml','msg',
    'dwg','dxf','step','stp','iges','igs','obj','stl','fbx','gltf','glb',
  };
  const books = {
    'epub','mobi','azw','azw3','fb2','djvu','djv','cbz','cbr','cb7','cbt',
    'lit','lrf','pdb','prc',
  };
  const archives = {
    'zip','rar','7z','tar','gz','gzip','bz2','bzip2','xz','lz','lzma','zst',
    'tgz','tbz','tbz2','txz','cab','iso','img','dmg','jar','war','ear','pak',
    'deb','rpm','arj','ace',
  };
  const apps = {
    'apk','aab','apks','xapk','exe','msi','msix','appx','appxbundle','ipa',
    'appimage','flatpak','snap',
  };
  const fonts = {
    'ttf','otf','woff','woff2','eot','ttc','pfb','pfm','fnt',
  };

  if (images.contains(ext)) return DownloadCategory.image;
  if (videos.contains(ext)) return DownloadCategory.video;
  if (audio.contains(ext)) return DownloadCategory.audio;
  if (docs.contains(ext)) return DownloadCategory.document;
  if (books.contains(ext)) return DownloadCategory.book;
  if (archives.contains(ext)) return DownloadCategory.archive;
  if (apps.contains(ext)) return DownloadCategory.app;
  if (fonts.contains(ext)) return DownloadCategory.font;
  return DownloadCategory.other;
}

String categoryFolderName(DownloadCategory category) => switch (category) {
      DownloadCategory.image => 'Images',
      DownloadCategory.video => 'Videos',
      DownloadCategory.audio => 'Music',
      DownloadCategory.document => 'Documents',
      DownloadCategory.book => 'Books',
      DownloadCategory.archive => 'Archives',
      DownloadCategory.app => 'Apps',
      DownloadCategory.font => 'Fonts',
      DownloadCategory.other => 'Other',
    };

String categoryLabelFa(DownloadCategory category) => switch (category) {
      DownloadCategory.image => 'تصاویر',
      DownloadCategory.video => 'ویدیو',
      DownloadCategory.audio => 'موسیقی',
      DownloadCategory.document => 'اسناد',
      DownloadCategory.book => 'کتاب‌ها',
      DownloadCategory.archive => 'آرشیو',
      DownloadCategory.app => 'برنامه‌ها',
      DownloadCategory.font => 'فونت‌ها',
      DownloadCategory.other => 'سایر',
    };

String mimeTypeForFileName(String fileName) {
  final ext = fileExtension(fileName);
  const exact = <String, String>{
    'pdf': 'application/pdf',
    'epub': 'application/epub+zip',
    'json': 'application/json',
    'xml': 'application/xml',
    'csv': 'text/csv',
    'html': 'text/html',
    'htm': 'text/html',
    'txt': 'text/plain',
    'md': 'text/markdown',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'zip': 'application/zip',
    'rar': 'application/vnd.rar',
    '7z': 'application/x-7z-compressed',
    'gz': 'application/gzip',
    'tar': 'application/x-tar',
    'apk': 'application/vnd.android.package-archive',
    'ttf': 'font/ttf',
    'otf': 'font/otf',
    'woff': 'font/woff',
    'woff2': 'font/woff2',
    'svg': 'image/svg+xml',
  };
  final direct = exact[ext];
  if (direct != null) return direct;

  return switch (detectDownloadCategory(fileName)) {
    DownloadCategory.image => 'image/*',
    DownloadCategory.video => 'video/*',
    DownloadCategory.audio => 'audio/*',
    DownloadCategory.document => 'application/octet-stream',
    DownloadCategory.book => 'application/octet-stream',
    DownloadCategory.archive => 'application/octet-stream',
    DownloadCategory.app => 'application/octet-stream',
    DownloadCategory.font => 'application/octet-stream',
    DownloadCategory.other => 'application/octet-stream',
  };
}
