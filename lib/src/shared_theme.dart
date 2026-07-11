// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'core/puzzle_proxy.dart';
import 'flutter.dart';
import 'puzzle_controls.dart';
import 'widgets/decoration_image_plus.dart';
import 'widgets/material_interior_alt.dart';

part 'theme_plaster.dart';
part 'theme_seattle.dart';
part 'theme_simple.dart';

final puzzleAnimationDuration = kThemeAnimationDuration * 3;

sealed class SharedTheme {
  const SharedTheme();

  String get name;

  Color get puzzleThemeBackground;

  RoundedRectangleBorder puzzleBorder(bool small);

  Color get puzzleBackgroundColor;

  Color get puzzleAccentColor;

  EdgeInsetsGeometry tilePadding(PuzzleProxy puzzle) => const EdgeInsets.all(6);

  Widget tileButton(int i, PuzzleProxy puzzle, bool small);

  Ink createInk(
    Widget child, {
    DecorationImage? image,
    EdgeInsetsGeometry? padding,
  }) => Ink(
    padding: padding,
    decoration: BoxDecoration(image: image),
    child: child,
  );

  Widget createButton(
    PuzzleProxy puzzle,
    bool small,
    int tileValue,
    Widget content, {
    Color? color,
    RoundedRectangleBorder? shape,
  }) => AnimatedContainer(
    duration: puzzleAnimationDuration,
    padding: tilePadding(puzzle),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        animationDuration: puzzleAnimationDuration,
        shape: shape ?? puzzleBorder(small),
        padding: const EdgeInsets.symmetric(),
        backgroundColor: color,
      ),
      clipBehavior: Clip.hardEdge,
      onPressed: () => puzzle.clickOrShake(tileValue),
      child: content,
    ),
  );

  // Thought about using AnimatedContainer here, but it causes some weird
  // resizing behavior
  Widget styledWrapper(bool small, Widget child) => MaterialInterior(
    duration: puzzleAnimationDuration,
    shape: puzzleBorder(small),
    color: puzzleBackgroundColor,
    child: child,
  );

  TextStyle get _infoStyle =>
      TextStyle(color: puzzleAccentColor, fontWeight: .bold);

  List<Widget> bottomControls(PuzzleControls controls) => <Widget>[
    Tooltip(
      message: 'Reset',
      child: IconButton(
        onPressed: controls.reset,
        color: puzzleAccentColor,
        icon: const Icon(Icons.refresh),
      ),
    ),
    Tooltip(
      message: 'Auto play',
      child: Checkbox(
        value: controls.autoPlay,
        onChanged: controls.setAutoPlayFunction,
        activeColor: puzzleAccentColor,
      ),
    ),
    Tooltip(
      message: 'Hint',
      child: IconButton(
        onPressed: controls.hintFunction,
        color: puzzleAccentColor,
        icon: const Icon(Icons.lightbulb_outline),
      ),
    ),
    Tooltip(
      message: controls.isSolving ? 'Cancel solving' : 'Solve',
      child: IconButton(
        onPressed: controls.solveFunction,
        color: puzzleAccentColor,
        icon: Icon(
          controls.isSolving ? Icons.stop_circle_outlined : Icons.auto_fix_high,
        ),
      ),
    ),
    if (controls.lastSolveSteps != null && controls.lastSolveTime != null) ...[
      Flexible(
        flex: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _formatSolveStats(
              controls.lastSolveSteps!,
              controls.lastSolveTime!,
            ),
            style: _infoStyle.copyWith(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ],
    const Spacer(),
    Flexible(
      flex: 2,
      child: RichText(
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: _infoStyle,
          children: [
            TextSpan(text: controls.clickCount.toString()),
            const TextSpan(text: ' Moves'),
          ],
        ),
      ),
    ),
    SizedBox(
      width: 90,
      child: RichText(
        textAlign: .right,
        text: TextSpan(
          style: _infoStyle,
          children: [
            TextSpan(text: controls.incorrectTiles.toString()),
            const TextSpan(text: ' Tiles left'),
          ],
        ),
      ),
    ),
  ];

  Widget tileButtonCore(int i, PuzzleProxy puzzle, bool small) {
    if (i == puzzle.tileCount && !puzzle.solved) {
      return const Center();
    }

    return tileButton(i, puzzle, small);
  }
}

String _formatSolveStats(int steps, Duration time) {
  final String timeStr;
  if (time.inMilliseconds >= 10) {
    timeStr = '${time.inMilliseconds}ms';
  } else if (time.inMicroseconds >= 1000) {
    timeStr = '${(time.inMicroseconds / 1000).toStringAsFixed(1)}ms';
  } else {
    timeStr = '${time.inMicroseconds}µs';
  }
  return '$steps steps ($timeStr)';
}
