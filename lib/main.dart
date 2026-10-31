// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:material_ui/material_ui.dart';

import 'src/core/puzzle_animator.dart';
import 'src/puzzle_home_state.dart';
import 'src/sound/foley_sound.dart';

void main() => runApp(const PuzzleApp());

class PuzzleApp extends StatelessWidget {
  final SoundEffectSink? soundSink;

  const PuzzleApp({super.key, this.soundSink});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Slide Puzzle',
    home: _PuzzleHome(soundSink: soundSink),
  );
}

class _PuzzleHome extends StatefulWidget {
  final SoundEffectSink? soundSink;

  const _PuzzleHome({this.soundSink});

  @override
  PuzzleHomeState createState() =>
      PuzzleHomeState(PuzzleAnimator.fourByFour(), soundSink: soundSink);
}
