import 'dart:async';
import 'dart:math' show Point, Random;

import 'array_2d.dart';
import 'util.dart';

final _rnd = Random();

enum PuzzleEvent { click, reset, noopClick }

class Puzzle {
  final Array2d<int> _array;
  final _controller = StreamController<PuzzleEvent>();

  int _clickCount = 0;

  int get clickCount => _clickCount;

  int get width => _array.width;

  int get height => _array.height;

  Stream<PuzzleEvent> get onEvent => _controller.stream;

  Puzzle.raw(int width, List<int> source)
      : _array = Array2d.wrap(width, source) {
    requireArgument(width >= 3, 'width', 'Cannot be less than three.');
    requireArgument(_array.height >= 3, 'height', 'Cannot be less than three.');

    for (var i = 0; i < _array.length; i++) {
      requireArgument(
          _array.contains(i),
          'source',
          'Must contain each number from 0 to `length - 1` '
          'once and only once.');
    }
  }

  Puzzle(int width, int height) : this.raw(width, _randomList(width * height));

  int valueAt(int x, int y) => _array.get(x, y);

  int get length => _array.length;

  int get tileCount => _array.length - 1;

  bool isCorrectPosition(int cellValue) => cellValue == _array[cellValue];

  void reset() {
    _randomizeList(_array);
    _clickCount = 0;
    _controller.add(PuzzleEvent.reset);
  }

  int get incorrectTiles {
    var count = tileCount;
    for (var i = 0; i < tileCount; i++) {
      if (isCorrectPosition(i)) {
        count--;
      }
    }
    return count;
  }

  Puzzle clone() => Puzzle.raw(width, _array.toList());

  /// A measure of how close the puzzle is to being solved.
  ///
  /// The sum of all of the distances squared `(x + y)^2 ` each tile has to move
  /// to be in the correct position.
  ///
  /// `0` - you've won!
  int get fitness {
    var value = 0;
    for (var i = 0; i < tileCount; i++) {
      if (!isCorrectPosition(i)) {
        final correctColumn = i % width;
        final correctRow = i ~/ width;
        final currentLocation = coordinatesOf(i);
        final delta = (correctColumn - currentLocation.x).abs() +
            (correctRow - currentLocation.y).abs();

        value += delta * delta;
      }
    }
    return value;
  }

  List<int> clickRandom(int count) {
    assert(count > 0);
    final clicks = <int>[];
    int lastTarget;
    while (clicks.length < count) {
      final randomTarget = _rnd.nextInt(tileCount) + 1;
      if (randomTarget != lastTarget && movable(randomTarget)) {
        final result = clickValue(randomTarget);
        assert(result);
        clicks.add(randomTarget);
        lastTarget = randomTarget;
      }
    }
    return clicks;
  }

  bool movable(int tileValue) {
    if (tileValue == tileCount) {
      return false;
    }

    final target = coordinatesOf(tileValue);
    final lastCoord = coordinatesOf(tileCount);
    if (lastCoord.x != target.x && lastCoord.y != target.y) {
      return false;
    }
    return true;
  }

  bool clickValue(int tileValue) {
    if (!movable(tileValue)) {
      _controller.add(PuzzleEvent.noopClick);
      return false;
    }
    final target = coordinatesOf(tileValue);

    _shift(target);
    _clickCount++;
    _controller.add(PuzzleEvent.click);
    return true;
  }

  void _shift(Point<int> target) {
    final lastCoord = coordinatesOf(tileCount);
    final delta = lastCoord - target;

    if (delta.magnitude.toInt() > 1) {
      final shiftPoint = target + Point<int>(delta.x.sign, delta.y.sign);
      _shift(shiftPoint);
      _swap(target, shiftPoint);
    } else {
      _swap(lastCoord, target);
    }
  }

  void _swap(Point<int> a, Point<int> b) {
    assert(a != b);
    if (a.x == b.x) {
      assert((a.y - b.y).abs() == 1);
    } else {
      assert(a.y == b.y);
      assert((a.x - b.x).abs() == 1);
    }

    final aValue = _array.get(a.x, a.y);
    _array.set(a.x, a.y, _array.get(b.x, b.y));
    _array.set(b.x, b.y, aValue);
  }

  Point<int> coordinatesOf(int value) => _array.coordinatesOf(value);

  @override
  String toString() => _array.toString();
}

List<int> _randomList(int length) =>
    _randomizeList(List<int>.generate(length, (i) => i));

List<int> _randomizeList(List<int> result) {
  final copy = result.toList();
  do {
    result.shuffle(_rnd);
  } while (result.any((v) => result[v] == v || result[v] == copy[v]));
  return result;
}
