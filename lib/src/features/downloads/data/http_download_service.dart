import 'dart:io';

import 'package:dio/dio.dart';

class HttpDownloadService {
  HttpDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final Map<String, CancelToken> _tokens = {};

  Future<void> download({
    required String id,
    required String url,
    required String savePath,
    required void Function(int received, int total) onProgress,
  }) async {
    final file = File(savePath);
    final existingBytes = await file.exists() ? await file.length() : 0;
    final token = CancelToken();
    _tokens[id] = token;

    try {
      await _dio.download(
        url,
        savePath,
        cancelToken: token,
        deleteOnError: false,
        options: Options(
          headers: existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
        ),
        fileAccessMode: existingBytes > 0
            ? FileAccessMode.append
            : FileAccessMode.write,
        onReceiveProgress: (received, total) {
          final completeReceived = existingBytes + received;
          final completeTotal = total > 0 ? existingBytes + total : 0;
          onProgress(completeReceived, completeTotal);
        },
      );
    } finally {
      _tokens.remove(id);
    }
  }

  void pause(String id) {
    _tokens[id]?.cancel('paused');
  }
}
