// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show Point;

enum PuzzleEvent { click, random, reset, noop }

sealed class PuzzleAction {
  const PuzzleAction();
}

final class TileMovedAction extends PuzzleAction {
  final int tileValue;
  final int movedCount;
  final int tileX;
  final bool landedCorrect;
  final bool solvedNow;

  const TileMovedAction({
    required this.tileValue,
    required this.movedCount,
    required this.tileX,
    required this.landedCorrect,
    required this.solvedNow,
  });
}

final class TileBlockedAction extends PuzzleAction {
  final int tileValue;
  final int tileX;

  const TileBlockedAction({required this.tileValue, required this.tileX});
}

final class RandomMoveAction extends PuzzleAction {
  final int tileX;
  final bool solvedNow;

  const RandomMoveAction({required this.tileX, required this.solvedNow});
}

final class PuzzleResetAction extends PuzzleAction {
  final bool easterEgg;

  const PuzzleResetAction({required this.easterEgg});
}

abstract interface class PuzzleProxy {
  int get width;

  int get height;

  int get length;

  bool get solved;

  void clickOrShake(int tileValue);

  int get tileCount;

  Point<double> location(int index);

  bool isCorrectPosition(int value);
}
