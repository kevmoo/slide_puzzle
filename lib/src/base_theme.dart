import 'package:flutter/material.dart';

import 'puzzle_animator.dart';

abstract class PuzzleThemeOption {
  String get name;

  void Function() get select;

  bool get selected;
}

class PuzzleThemeData {
  final String name;
  final Widget Function(BuildContext) build;

  PuzzleThemeData(this.name, this.build);
}

mixin BaseTheme {
  PuzzleAnimator get puzzleAnimator;

  bool get autoPlay;

  void setAutoPlay(bool newValue);

  AnimationNotifier get animationNotifier;

  String get clickCountText;

  String get tilesLeftText;

  Iterable<PuzzleThemeOption> get availableThemes;

  Iterable<PuzzleThemeData> get themeData => List(0);
}

class AnimationNotifier extends ChangeNotifier {
  void animate() {
    notifyListeners();
  }
}
