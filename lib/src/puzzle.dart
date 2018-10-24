import 'dart:math' show Point;

import 'array_2d.dart';
import 'util.dart';

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

  bool correctPosition(int cellValue) {
    return cellValue == _array[cellValue - 1];
  }

  void reset() {
    _randomizeList(_array);
    _clickCount = 0;
  }

  int get incorrectTiles {
    var count = _array.length - 1;
    for (var i = 1; i < _array.length; i++) {
      if (correctPosition(i)) {
        count--;
      }
    }
    return count;
  }

  bool click(int x, int y) {
    requireArgument(x >= 0 && x < width, 'must be >= 0 && < width');
    requireArgument(y >= 0 && y < height, 'must be >= 0 && < height');

    final target = Point<int>(x, y);
    final zeroCoord = coordinatesOf(0);

    if (target == zeroCoord) {
      assert(value(x, y) == 0);
      return false;
    }

    if (zeroCoord.x != x && zeroCoord.y != y) {
      return false;
    }

    _shift(target);
    _clickCount++;
    return true;
  }

  void _shift(Point<int> target) {
    final zeroCoord = coordinatesOf(0);
    final delta = zeroCoord - target;

    if (delta.magnitude.toInt() > 1) {
      final shiftPoint = target + Point<int>(delta.x.sign, delta.y.sign);
      _shift(shiftPoint);
      _swap(target, shiftPoint);
    } else {
      _swap(zeroCoord, target);
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
  do {
    result.shuffle();
  } while (result.any((v) => result[(v - 1) % result.length] == v));
  return result;
}
