import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'puzzle.dart';
import 'puzzle_animator.dart';

class PuzzleFlowDelegate extends FlowDelegate {
  final PuzzleAnimator _puzzleAnimator;

  Puzzle get _puzzle => _puzzleAnimator.puzzle;

  PuzzleFlowDelegate(this._puzzleAnimator, Listenable repaint)
      : super(repaint: repaint);

  @override
  Size getSize(BoxConstraints constraints) => const Size(260, 260);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    final minSquareSize = math.min(260 / _puzzle.width, 260 / _puzzle.height);

    return BoxConstraints.tight(Size(minSquareSize, minSquareSize));
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final minSquareSize = math.min(context.size.width / _puzzle.width,
        context.size.height / _puzzle.height);

    final delta = ((context.size -
            Offset(minSquareSize * _puzzle.width,
                minSquareSize * _puzzle.height)) as Size) *
        0.5;

    final tileSize = context.getChildSize(0);
    for (var i = 0; i < _puzzle.length; i++) {
      final tileLocation = _puzzleAnimator.location(i);
      context.paintChild(i,
          transform: Matrix4.translationValues(
              tileLocation.x * tileSize.width + delta.width,
              tileLocation.y * tileSize.height + delta.height,
              i.toDouble()));
    }
  }

  @override
  bool shouldRepaint(covariant PuzzleFlowDelegate oldDelegate) => true;
}
