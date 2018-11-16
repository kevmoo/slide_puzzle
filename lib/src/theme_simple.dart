import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'base_theme.dart';
import 'shared_theme.dart';

class ThemeSimple extends SharedTheme {
  ThemeSimple(AppState proxy) : super('Simple', proxy);

  @override
  Color get puzzleThemeBackground => const Color.fromARGB(255, 54, 81, 102);

  @override
  Color get puzzleBackgroundColor => Colors.white70;

  @override
  RoundedRectangleBorder get puzzleBorder => RoundedRectangleBorder(
      side: const BorderSide(color: Colors.black87, width: 2),
      borderRadius: BorderRadius.circular(5));

  @override
  Widget tileButton(int i) {
    if (i == puzzle.tileCount) {
      if (puzzle.solved) {
        return const Center(
            child: Icon(
          Icons.thumb_up,
          size: 36,
          color: Colors.white,
        ));
      }
      return const Center();
    }

    final correctPosition = puzzle.isCorrectPosition(i);
    return RaisedButton(
      animationDuration: puzzleAnimationDuration,
      elevation: 1,
      child: Text(
        (i + 1).toString(),
        style: TextStyle(
          fontWeight: correctPosition ? FontWeight.bold : FontWeight.normal,
        ),
        textScaleFactor: 1.4,
      ),
      onPressed: tilePress(i),
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(),
      color: Colors.white,
      disabledColor: Colors.white,
    );
  }
}
