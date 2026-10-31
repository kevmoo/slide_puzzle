import 'dart:convert';

import 'package:flutter/services.dart';

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
    try {
      final content = await rootBundle.loadString('build_info.json');
      final data = jsonDecode(content) as Map<String, dynamic>;
      return VersionInfo.fromJson(data);
    } catch (_) {
      // Return null when running in dev without build_info.json
      return null;
    }
  }
}
