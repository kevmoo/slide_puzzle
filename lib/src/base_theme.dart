import 'flutter.dart';

import 'puzzle_animator.dart';

abstract class PuzzleTheme {
  final String name;

  final AppState _appState;

  PuzzleProxy get puzzle => _appState.puzzle;

  String get clickCountText => _appState.clickCountText;

  String get tilesLeftText => _appState.tilesLeftText;

  Iterable<PuzzleTheme> get themeData => _appState.themeData;

  bool get autoPlay => _appState.autoPlay;

  void Function(bool newValue) get setAutoPlay {
    if (puzzle.solved) {
      return null;
    }
    return _appState.setAutoPlay;
  }

  void Function() tilePress(int tileValue) {
    if (puzzle.solved) {
      return null;
    }
    return () {
      _appState.setAutoPlay(false);
      _appState.puzzle.clickOrShake(tileValue);
    };
  }

  PuzzleTheme(this.name, this._appState);

  AnimationNotifier get animationNotifier => _appState.animationNotifier;

  Widget build(BuildContext context);

  void Function() get select {
    if (selected) {
      return null;
    }
    return _select;
  }

  void _select() => _appState.currentTheme = this;

  bool get selected => _appState.currentTheme == this;
}

abstract class AppState {
  PuzzleProxy get puzzle;

  bool get autoPlay;

  void setAutoPlay(bool newValue);

  AnimationNotifier get animationNotifier;

  String get clickCountText;

  String get tilesLeftText;

  Iterable<PuzzleTheme> get themeData;

  PuzzleTheme get currentTheme;

  set currentTheme(PuzzleTheme theme);
}

class AnimationNotifier extends ChangeNotifier {
  void animate() {
    notifyListeners();
  }
}
