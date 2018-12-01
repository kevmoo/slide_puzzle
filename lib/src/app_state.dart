import 'core/puzzle_animator.dart';
import 'flutter.dart';
import 'shared_theme.dart';

abstract class AppState {
  TabController get tabController;

  Animation<Offset> get shuffleOffsetAnimation;

  PuzzleProxy get puzzle;

  bool get autoPlay;

  void setAutoPlay(bool newValue);

  AnimationNotifier get animationNotifier;

  Iterable<SharedTheme> get themeData;

  SharedTheme get currentTheme;

  set currentTheme(SharedTheme theme);
}

abstract class AnimationNotifier implements Listenable {
  void animate();

  void dispose();
}
