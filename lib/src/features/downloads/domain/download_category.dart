enum DownloadCategory { image, video, audio, document, archive, app, other }

DownloadCategory detectDownloadCategory(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final ext = dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : '';

  const images = {'jpg','jpeg','png','gif','webp','bmp','svg','heic'};
  const videos = {'mp4','mkv','webm','mov','avi','m4v','3gp'};
  const audio = {'mp3','m4a','aac','wav','flac','ogg','opus'};
  const docs = {'pdf','doc','docx','xls','xlsx','ppt','pptx','txt','csv','epub'};
  const archives = {'zip','rar','7z','tar','gz','bz2','xz'};
  const apps = {'apk','aab'};

  if (images.contains(ext)) return DownloadCategory.image;
  if (videos.contains(ext)) return DownloadCategory.video;
  if (audio.contains(ext)) return DownloadCategory.audio;
  if (docs.contains(ext)) return DownloadCategory.document;
  if (archives.contains(ext)) return DownloadCategory.archive;
  if (apps.contains(ext)) return DownloadCategory.app;
  return DownloadCategory.other;
}

String categoryFolderName(DownloadCategory category) => switch (category) {
  DownloadCategory.image => 'Images',
  DownloadCategory.video => 'Videos',
  DownloadCategory.audio => 'Audio',
  DownloadCategory.document => 'Documents',
  DownloadCategory.archive => 'Archives',
  DownloadCategory.app => 'Apps',
  DownloadCategory.other => 'Other',
};

String categoryLabelFa(DownloadCategory category) => switch (category) {
  DownloadCategory.image => 'تصویر',
  DownloadCategory.video => 'ویدیو',
  DownloadCategory.audio => 'صوت',
  DownloadCategory.document => 'سند',
  DownloadCategory.archive => 'آرشیو',
  DownloadCategory.app => 'برنامه',
  DownloadCategory.other => 'سایر',
};