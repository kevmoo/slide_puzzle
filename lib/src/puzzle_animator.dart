import 'dart:math';

import 'body.dart';
import 'puzzle.dart';

class PuzzleAnimator {
  final Puzzle puzzle;
  final List<Body> _locations;

  bool _stable;

  bool get stable => _stable;

  bool get solved => puzzle.incorrectTiles == 0;

  Point<double> location(int index) => _locations[index].location;

  List<int> _lastPlan;

  int _lastBadClick;
  int _badClickCount = 0;

  PuzzleAnimator(this.puzzle)
      : _locations = List.generate(puzzle.length, (i) {
          return Body.raw(
              (puzzle.width - 1.0) / 2, (puzzle.height - 1.0) / 2, 0, 0);
        });

  void playRandom({Duration limit = const Duration(milliseconds: 5)}) {
    if (puzzle.fitness == 0) {
      return;
    }

    limit ??= const Duration(milliseconds: 5);

    final watch = Stopwatch()..start();

    List<int> bestClicks;
    int bestScore;

    void evaluateClone(Puzzle clone, List<int> clicks) {
      final score = _scorePuzzle(clone);

      if (clone.toString() != puzzle.toString() &&
          (bestScore == null || bestScore > score)) {
        bestScore = score;
        bestClicks = clicks;
      }
    }

    if (_lastPlan != null) {
      // If we have an existing plan, score it
      final clone = puzzle.clone();
      for (var click in _lastPlan) {
        clone.clickValue(click);
      }
      evaluateClone(clone, _lastPlan);
      if (bestScore != null) {
        // We want to give `_lastPlan` a handicap to prioritize having a
        // more stable plan
        bestScore -= puzzle.length;
      }
    }

    do {
      final clone = puzzle.clone();
      final clicks = clone.clickRandom(puzzle.tileCount);
      evaluateClone(clone, clicks);
    } while (watch.elapsed < limit);

    // Only playing the first option in the "plan"
    puzzle.clickValue(bestClicks.removeAt(0));

    _lastPlan = bestClicks;
  }

  void clickOrShake(int tileValue) {
    if (!puzzle.clickValue(tileValue)) {
      _shake(tileValue);

      // This is logic to allow a user to skip to the end – useful for testing
      // click on 5 un-movable tiles in a row, but not the same tile twice
      // in a row
      if (tileValue != _lastBadClick) {
        _badClickCount++;
        if (_badClickCount >= 5) {
          // Do the reset!
          final newValues = List.generate(puzzle.length, (i) {
            if (i == puzzle.tileCount) {
              return puzzle.tileCount - 1;
            } else if (i == (puzzle.tileCount - 1)) {
              return puzzle.tileCount;
            }
            return i;
          });
          puzzle.reset(source: newValues);
          _lastBadClick = null;
          _badClickCount = 0;
        }
      } else {
        _badClickCount = 0;
      }
      _lastBadClick = tileValue;
    } else {
      _lastBadClick = null;
      _badClickCount = 0;
    }
  }

  void _shake(int tileValue) {
    final delta = puzzle.coordinatesOf(puzzle.tileCount) -
        puzzle.coordinatesOf(tileValue);
    final deltaDouble = Point(delta.x.toDouble(), delta.y.toDouble());

    _locations[tileValue].kick(deltaDouble * (0.5 / deltaDouble.magnitude));
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

      _stable = !body.animate(animationSeconds,
              force: target - body.location,
              drag: .9,
              maxVelocity: 1.0,
              snapTo: target) &&
          _stable;
    }
  }

  Point<double> _target(int item) {
    final target = puzzle.coordinatesOf(item);
    return Point(target.x.toDouble(), target.y.toDouble());
  }
}

int _scorePuzzle(Puzzle puzzle) {
  var score = puzzle.fitness * puzzle.incorrectTiles;
  for (var i = 0; i < puzzle.tileCount; i++) {
    if (puzzle.isCorrectPosition(i)) {
      score -= puzzle.length;
    } else {
      break;
    }
  }
  return score;
}
