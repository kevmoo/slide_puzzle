import 'package:flutter/material.dart';

import 'puzzle_animator.dart';

abstract class ThemePicker {
  String get name;

  void select();

  bool get selected;
}

abstract class BaseTheme {
  PuzzleAnimator get puzzleAnimator;

  bool get autoPlay;

  void setAutoPlay(bool newValue);

  AnimationNotifier get animationNotifier;

  String get clickCountText;

  String get tilesLeftText;

  Iterable<ThemePicker> get availableThemes;
}

class AnimationNotifier extends ChangeNotifier {
  void animate() {
    notifyListeners();
  }
}
