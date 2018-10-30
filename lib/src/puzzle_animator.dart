import 'dart:math';

import 'body.dart';
import 'puzzle.dart';

class PuzzleAnimator {
  final Puzzle puzzle;
  final List<Body> _locations;

  bool _stable;

  Point<double> location(int index) => _locations[index].location;

  PuzzleAnimator(this.puzzle)
      : _locations = List.generate(puzzle.length, (i) {
          return Body.raw(
              (puzzle.width - 1.0) / 2, (puzzle.height - 1.0) / 2, 0, 0);
        });

  bool get stable => _stable;

  void clickOrShake(int tileValue) {
    if (!puzzle.clickValue(tileValue)) {
      _shake(tileValue);
    }
  }

  void _shake(int tileValue) {
    final delta = puzzle.coordinatesOf(0) - puzzle.coordinatesOf(tileValue);
    final deltaDouble = Point(delta.x.toDouble(), delta.y.toDouble());

    _locations[tileValue].move(deltaDouble * (0.2 / deltaDouble.magnitude));
  }

  void update(Duration timeDelta) {
    assert(!timeDelta.isNegative);
    assert(timeDelta != Duration.zero);

    var animationSeconds = timeDelta.inMilliseconds / 60.0;
    if (animationSeconds == 0) {
      animationSeconds = 0.1;
    }
    assert(animationSeconds > 0);

    _stable = true;
    for (var i = 0; i < puzzle.length; i++) {
      final target = _target(i);
      final body = _locations[i];

      final delta = (target - body.location);
      final force = delta;

      _stable = !body.animate(animationSeconds,
              force: force, drag: .99, maxVelocity: 1.0, snapTo: target) &&
          _stable;
    }
  }

  Point<double> _target(int item) {
    final target = puzzle.coordinatesOf(item);
    return Point(target.x.toDouble(), target.y.toDouble());
  }
}
