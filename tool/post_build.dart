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

  final files = stagingDir.listSync(recursive: true);
  var depsFileFound = false;
  for (final file in files) {
    if (file is File && file.path.endsWith('.deps')) {
      print('Deleting ${file.path}...');
      file.deleteSync();
      depsFileFound = true;
    }
  }

  if (!depsFileFound) {
    print('No .deps file found to delete.');
  } else {
    print('Cleanup complete.');
  }

  if (!_isWorkingTreeClean()) {
    print('Skipping build info generation: working tree is dirty.');
    return;
  }

  final currentBranch = _runGit(['branch', '--show-current']);
  if (currentBranch != 'master') {
    print(
      'Skipping build info generation: '
      'current branch is "$currentBranch" (expected "master").',
    );
    return;
  }

  // Extract concise Flutter version (e.g. "Flutter 3.46.0-1.0.pre-530")
  final flutterVersion = _getFlutterVersion();
  final gitInfo = _runGit(['rev-parse', 'HEAD']);

  // Shorten SHA for display
  final shortSha = gitInfo.substring(0, 7);
  final commitUrl = 'https://github.com/kevmoo/slide_puzzle/commit/$gitInfo';

  final versionJsonFile = File.fromUri(stagingDir.uri.resolve('version.json'));
  final jsonContent =
      '''{
  "flutter_version": "$flutterVersion",
  "commit_sha": "$gitInfo",
  "short_sha": "$shortSha",
  "commit_url": "$commitUrl"
}
''';

  versionJsonFile.writeAsStringSync(jsonContent);
  print('Wrote version.json to ${versionJsonFile.path}');
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
