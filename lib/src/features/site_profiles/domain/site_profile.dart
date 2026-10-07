import 'dart:convert';

class SiteProfile {
  const SiteProfile({
    required this.id,
    required this.host,
    this.userAgent,
    this.referer,
    this.cookie,
    this.headers = const {},
    this.folderName,
    this.maxSegments,
  });

  final String id;
  final String host;
  final String? userAgent;
  final String? referer;
  final String? cookie;
  final Map<String, String> headers;
  final String? folderName;
  final int? maxSegments;

  Map<String, String> get requestHeaders {
    final result = <String, String>{...headers};
    if (userAgent != null && userAgent!.trim().isNotEmpty) {
      result['User-Agent'] = userAgent!.trim();
    }
    if (referer != null && referer!.trim().isNotEmpty) {
      result['Referer'] = referer!.trim();
    }
    if (cookie != null && cookie!.trim().isNotEmpty) {
      result['Cookie'] = cookie!.trim();
    }
    return result;
  }

  bool matchesHost(String value) {
    final normalized = host.trim().toLowerCase();
    final candidate = value.trim().toLowerCase();
    return candidate == normalized || candidate.endsWith('.$normalized');
  }

  SiteProfile copyWith({
    String? host,
    String? userAgent,
    String? referer,
    String? cookie,
    Map<String, String>? headers,
    String? folderName,
    int? maxSegments,
  }) {
    return SiteProfile(
      id: id,
      host: host ?? this.host,
      userAgent: userAgent ?? this.userAgent,
      referer: referer ?? this.referer,
      cookie: cookie ?? this.cookie,
      headers: headers ?? this.headers,
      folderName: folderName ?? this.folderName,
      maxSegments: maxSegments ?? this.maxSegments,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'host': host,
        'userAgent': userAgent,
        'referer': referer,
        'cookie': cookie,
        'headers': headers,
        'folderName': folderName,
        'maxSegments': maxSegments,
      };

  factory SiteProfile.fromMap(Map<String, dynamic> map) => SiteProfile(
        id: map['id'] as String,
        host: map['host'] as String,
        userAgent: map['userAgent'] as String?,
        referer: map['referer'] as String?,
        cookie: map['cookie'] as String?,
        headers: Map<String, String>.from(
          (map['headers'] as Map?) ?? const <String, String>{},
        ),
        folderName: map['folderName'] as String?,
        maxSegments: (map['maxSegments'] as num?)?.toInt(),
      );

  String toJson() => jsonEncode(toMap());
  factory SiteProfile.fromJson(String source) =>
      SiteProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
