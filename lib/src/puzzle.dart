import 'dart:math' show Point, Random;

import 'array_2d.dart';
import 'util.dart';

final _rnd = Random();

class Puzzle {
  final Array2d<int> _array;

  int _clickCount = 0;

  int get clickCount => _clickCount;

  int get width => _array.width;

  int get height => _array.height;

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

  int value(int x, int y) => _array.get(x, y);

  int get length => _array.length;

  int get tileCount => _array.length - 1;

  bool isCorrectPosition(int cellValue) => cellValue == _array[cellValue];

  void reset() {
    _randomizeList(_array);
    _clickCount = 0;
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

  bool clickValue(int value) {
    final point = coordinatesOf(value);
    return click(point.x, point.y);
  }

  List<int> clickRandom(int count) {
    assert(count > 0);
    final clicks = <int>[];
    int lastTarget;
    while (clicks.length < count) {
      final randomTarget = _rnd.nextInt(tileCount) + 1;
      if (randomTarget != lastTarget && clickValue(randomTarget)) {
        clicks.add(randomTarget);
        lastTarget = randomTarget;
      }
    }
    return clicks;
  }

  bool click(int x, int y) {
    requireArgument(x >= 0 && x < width, 'must be >= 0 && < width');
    requireArgument(y >= 0 && y < height, 'must be >= 0 && < height');

    final target = Point<int>(x, y);
    final lastCoord = coordinatesOf(tileCount);

    if (target == lastCoord) {
      assert(value(x, y) == tileCount);
      return false;
    }

    if (lastCoord.x != x && lastCoord.y != y) {
      return false;
    }

    _shift(target);
    _clickCount++;
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
