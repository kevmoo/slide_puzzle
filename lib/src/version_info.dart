import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class VersionInfo {
  final String flutterVersion;
  final String commitSha;
  final String shortSha;
  final String commitUrl;

  const VersionInfo({
    required this.flutterVersion,
    required this.commitSha,
    required this.shortSha,
    required this.commitUrl,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) => VersionInfo(
    flutterVersion: json['flutter_version'] as String? ?? 'Unknown',
    commitSha: json['commit_sha'] as String? ?? '',
    shortSha: json['short_sha'] as String? ?? '',
    commitUrl: json['commit_url'] as String? ?? '',
  );

  static Future<VersionInfo?> load() async {
    if (kIsWeb) {
      try {
        final response = await http.get(Uri.parse('version.json'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return VersionInfo.fromJson(data);
        }
      } catch (_) {
        // Fall back to asset check or null if HTTP request fails
      }
    }

    try {
      final content = await rootBundle.loadString('version.json');
      final data = jsonDecode(content) as Map<String, dynamic>;
      return VersionInfo.fromJson(data);
    } catch (_) {
      // Return null when running in dev without version.json
      return null;
    }
  }
}
