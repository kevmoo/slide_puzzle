// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:material_ui/material_ui.dart';

import 'src/core/puzzle_animator.dart';
import 'src/puzzle_home_state.dart';

void main() => runApp(const PuzzleApp());

class PuzzleApp extends StatelessWidget {
  const PuzzleApp();

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(title: 'Slide Puzzle', home: _PuzzleHome());
}

class _PuzzleHome extends StatefulWidget {
  const _PuzzleHome();

  @override
  PuzzleHomeState createState() => PuzzleHomeState(PuzzleAnimator.fourByFour());
}
