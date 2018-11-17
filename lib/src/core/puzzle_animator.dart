import 'dart:async';
import 'dart:math' show Point;

import 'body.dart';
import 'puzzle.dart';

enum PuzzleEvent { click, reset }

abstract class PuzzleProxy {
  int get width;

  int get height;

  int get length;

  bool get solved;

  void reset();

  void clickOrShake(int tileValue);

  int get tileCount;

  Point<double> location(int index);

  bool isCorrectPosition(int value);
}

class PuzzleAnimator implements PuzzleProxy {
  final Puzzle _puzzle;
  final List<Body> _locations;
  final _controller = StreamController<PuzzleEvent>();

  bool _stable;

  bool get stable => _stable;

  @override
  bool get solved => _puzzle.incorrectTiles == 0;

  @override
  int get width => _puzzle.width;

  @override
  int get height => _puzzle.height;

  @override
  int get length => _puzzle.length;

  @override
  int get tileCount => _puzzle.tileCount;

  int get incorrectTiles => _puzzle.incorrectTiles;

  int get clickCount => _puzzle.clickCount;

  @override
  void reset() {
    _puzzle.reset();
    _controller.add(PuzzleEvent.reset);
  }

  Stream<PuzzleEvent> get onEvent => _controller.stream;

  @override
  bool isCorrectPosition(int value) => _puzzle.isCorrectPosition(value);

  @override
  Point<double> location(int index) => _locations[index].location;

  List<int> _lastPlan;

  int _lastBadClick;
  int _badClickCount = 0;

  PuzzleAnimator(int width, int height) : this._(Puzzle(width, height));

  PuzzleAnimator._(this._puzzle)
      : _locations = List.generate(_puzzle.length, (i) {
          return Body.raw(
              (_puzzle.width - 1.0) / 2, (_puzzle.height - 1.0) / 2, 0, 0);
        });

  void playRandom({Duration limit = const Duration(milliseconds: 5)}) {
    if (_puzzle.fitness == 0) {
      return;
    }

    limit ??= const Duration(milliseconds: 5);

    final watch = Stopwatch()..start();

    List<int> bestClicks;
    int bestScore;

    void evaluateClone(Puzzle clone, List<int> clicks) {
      final score = _scorePuzzle(clone);

      if (clone.toString() != _puzzle.toString() &&
          (bestScore == null || bestScore > score)) {
        bestScore = score;
        bestClicks = clicks;
      }
    }

    if (_lastPlan != null) {
      // If we have an existing plan, score it
      final clone = _puzzle.clone();
      for (var click in _lastPlan) {
        clone.clickValue(click);
      }
      evaluateClone(clone, _lastPlan);
      if (bestScore != null) {
        // We want to give `_lastPlan` a handicap to prioritize having a
        // more stable plan
        bestScore -= _puzzle.length;
      }
    }

    do {
      final clone = _puzzle.clone();
      final clicks = clone.clickRandom(_puzzle.tileCount);
      evaluateClone(clone, clicks);
    } while (watch.elapsed < limit);

    // Only playing the first option in the "plan"
    _clickValue(bestClicks.removeAt(0));

    _lastPlan = bestClicks;
  }

  @override
  void clickOrShake(int tileValue) {
    if (!_clickValue(tileValue)) {
      _shake(tileValue);

      // This is logic to allow a user to skip to the end – useful for testing
      // click on 5 un-movable tiles in a row, but not the same tile twice
      // in a row
      if (tileValue != _lastBadClick) {
        _badClickCount++;
        if (_badClickCount >= 5) {
          // Do the reset!
          final newValues = List.generate(_puzzle.length, (i) {
            if (i == _puzzle.tileCount) {
              return _puzzle.tileCount - 1;
            } else if (i == (_puzzle.tileCount - 1)) {
              return _puzzle.tileCount;
            }
            return i;
          });
          _puzzle.reset(source: newValues);
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

  bool _clickValue(int value) {
    _controller.add(PuzzleEvent.click);
    return _puzzle.clickValue(value);
  }

  void _shake(int tileValue) {
    final delta = _puzzle.openPosition() - _puzzle.coordinatesOf(tileValue);
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
    for (var i = 0; i < _puzzle.length; i++) {
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
    final target = _puzzle.coordinatesOf(item);
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
