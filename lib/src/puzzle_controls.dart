// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';

abstract interface class PuzzleControls implements Listenable {
  void reset();

  int get clickCount;

  int get incorrectTiles;

  bool get autoPlay;

  void Function(bool? newValue)? get setAutoPlayFunction;

  bool get isSolving;

  void solveOrCancel();

  VoidCallback? get solveFunction;

  VoidCallback? get solveOrCancelFunction;

  void hint();

  VoidCallback? get hintFunction;

  Duration? get lastSolveTime;

  int? get lastSolveSteps;
}
