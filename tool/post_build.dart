import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('No arguments passed to script.');
    exit(1);
  }

  final stagingDir = Directory(args[0]);
  if (!stagingDir.existsSync()) {
    print('Staging directory ${stagingDir.path} does not exist.');
    exit(1);
  }

  final isClean = _isWorkingTreeClean();
  if (!isClean) {
    print('WARNING: Working tree is dirty. Generating build info anyway.');
  }

  final currentBranch = _runGit(['branch', '--show-current']);
  if (currentBranch != 'main') {
    print(
      'WARNING: Current branch is "$currentBranch" (expected "main"). '
      'Generating build info anyway.',
    );
  }

  // Extract concise Flutter version (e.g. "Flutter 3.46.0-1.0.pre-530")
  final flutterVersion = _getFlutterVersion();
  final gitInfo = _runGit(['rev-parse', 'HEAD']);

  // Shorten SHA for display
  final shortSha = gitInfo.substring(0, 7);
  final displaySha = isClean ? shortSha : '$shortSha-dirty';
  final commitUrl = 'https://github.com/kevmoo/slide_puzzle/commit/$gitInfo';

  final buildInfoFile = File.fromUri(stagingDir.uri.resolve('build_info.json'));
  final assetsBuildInfoFile = File.fromUri(
    stagingDir.uri.resolve('assets/build_info.json'),
  );
  final jsonContent =
      '''{
  "flutter_version": "$flutterVersion",
  "commit_sha": "$gitInfo",
  "short_sha": "$displaySha",
  "commit_url": "$commitUrl"
}
''';

  buildInfoFile.writeAsStringSync(jsonContent);
  print('Wrote build_info.json to ${buildInfoFile.path}');
  assetsBuildInfoFile.parent.createSync(recursive: true);
  assetsBuildInfoFile.writeAsStringSync(jsonContent);
  print('Wrote build_info.json to ${assetsBuildInfoFile.path}');
}

String _getFlutterVersion() {
  final result = Process.runSync('flutter', ['--version']);
  if (result.exitCode != 0) {
    throw ProcessException(
      'flutter',
      ['--version'],
      result.stderr as String,
      result.exitCode,
    );
  }
  final firstLine = (result.stdout as String).trim().split('\n').first.trim();
  return firstLine.split('•').first.trim();
}

String _runGit(List<String> args) {
  final result = Process.runSync('git', args);

  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      args,
      result.stderr as String,
      result.exitCode,
    );
  }

  return (result.stdout as String).trim();
}

bool _isWorkingTreeClean() => _runGit(['status', '--porcelain']).isEmpty;
