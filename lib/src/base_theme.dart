import 'core/puzzle_animator.dart';
import 'flutter.dart';

abstract class PuzzleThemeOption {
  String get name;
}

abstract class PuzzleTheme implements PuzzleThemeOption {
  final AppState _appState;

  PuzzleProxy get puzzle => _appState.puzzle;

  String get clickCountText => puzzle.clickCount.toString();

  String get tilesLeftText => puzzle.incorrectTiles.toString();

  Iterable<PuzzleThemeOption> get themeData => _appState.themeData;

  bool get autoPlay => _appState.autoPlay;

  void Function(bool newValue) get setAutoPlay {
    if (puzzle.solved) {
      return null;
    }
    return _appState.setAutoPlay;
  }

  void tilePress(int tileValue) {
    _appState.setAutoPlay(false);
    _appState.puzzle.clickOrShake(tileValue);
  }

  PuzzleTheme(this._appState);

  AnimationNotifier get animationNotifier => _appState.animationNotifier;

  Widget build(BuildContext context);

  PuzzleTheme get currentTheme => _appState.currentTheme;

  void selectTheme(PuzzleThemeOption thing) {
    _appState.currentTheme = thing as PuzzleTheme;
  }
}

abstract class AppState {
  PuzzleProxy get puzzle;

  bool get autoPlay;

  void setAutoPlay(bool newValue);

  AnimationNotifier get animationNotifier;

  Iterable<PuzzleThemeOption> get themeData;

  PuzzleTheme get currentTheme;

  set currentTheme(PuzzleTheme theme);
}

class AnimationNotifier extends ChangeNotifier {
  void animate() {
    notifyListeners();
  }
}
