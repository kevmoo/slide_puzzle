import 'dart:math';

import 'puzzle.dart';

class PuzzleAnimator {
  final Puzzle puzzle;
  final List<Point<double>> _locations;

  bool _stable;

  Point<double> location(int index) => _locations[index];

  PuzzleAnimator(this.puzzle)
      : _locations = List.generate(puzzle.length, (i) {
          return Point((puzzle.width - 1.0) / 2, (puzzle.height - 1.0) / 2);
        });

  bool get stable => _stable;

  Point<double> _target(int item) {
    final target = puzzle.coordinatesOf(item);
    return Point(target.x.toDouble(), target.y.toDouble());
  }

  void update(Duration timeDelta) {
    assert(!timeDelta.isNegative);
    assert(timeDelta != Duration.zero);
    final maxDistance = timeDelta.inMilliseconds / 200.0;

    _stable = true;
    for (var i = 0; i < puzzle.length; i++) {
      final target = _target(i);
      final current = _locations[i];

      if (target != current) {
        _stable = false;

        var locationDelta = target - current;

        if (locationDelta.magnitude > maxDistance) {
          locationDelta *= (maxDistance / locationDelta.magnitude);
        }

        _locations[i] = current + locationDelta;
      }
    }
  }
}
