import 'package:flutter/material.dart';

import 'puzzle_animator.dart';

abstract class PuzzleThemeData {
  String get name;
  Widget Function(BuildContext) get build;
  void Function() get select;
  bool get selected;
}

mixin BaseTheme {
  PuzzleThemeData createThemeData(
      String name, Widget Function(BuildContext) build);

  PuzzleProxy get puzzle;

  bool get autoPlay;

  void setAutoPlay(bool newValue);

  AnimationNotifier get animationNotifier;

  String get clickCountText;

  String get tilesLeftText;

  Iterable<PuzzleThemeData> get themeData => List(0);
}

class AnimationNotifier extends ChangeNotifier {
  void animate() {
    notifyListeners();
  }
}
