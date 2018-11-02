import 'dart:async';
import 'dart:convert';
import 'dart:math' show Point, Random;

import 'array_2d.dart';
import 'util.dart';

final _rnd = Random();

final _spacesRegexp = RegExp(' +');

enum PuzzleEvent { click, reset, noopClick }

class Puzzle {
  final Array2d<int> _array;
  final _controller = StreamController<PuzzleEvent>();

  int _clickCount = 0;

  int get clickCount => _clickCount;

  int get width => _array.width;

  int get height => _array.height;

  Stream<PuzzleEvent> get onEvent => _controller.stream;

  Puzzle.raw(int width, Iterable<int> source)
      : _array = Array2d.wrap(width, source.toList()) {
    requireArgument(width >= 2, 'width', 'Must be at least 2.');
    requireArgument(_array.length >= 6, 'source', 'Must be at least 6 items');

    for (var i = 0; i < _array.length; i++) {
      requireArgument(
          _array.contains(i),
          'source',
          'Must contain each number from 0 to `length - 1` '
          'once and only once.');
    }
  }

  Puzzle(int width, int height) : this.raw(width, _randomList(width, height));

  factory Puzzle.parse(String input) {
    var rows = LineSplitter.split(input).map((line) {
      final splits = line.trim().split(_spacesRegexp);
      return splits.map(int.parse).toList();
    }).toList();

    return Puzzle.raw(rows.first.length, rows.expand((row) => row));
  }

  int valueAt(int x, int y) => _array.get(x, y);

  int get length => _array.length;

  int get tileCount => _array.length - 1;

  bool isCorrectPosition(int cellValue) => cellValue == _array[cellValue];

  bool get solvable => _solvable(width, _array);

  void reset() {
    _randomizeList(width, _array);
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
      final randomTarget = _rnd.nextInt(tileCount);
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

List<int> _randomList(int width, int height) =>
    _randomizeList(width, List<int>.generate(width * height, (i) => i));

List<int> _randomizeList(int width, List<int> result) {
  final copy = result.toList();
  do {
    result.shuffle(_rnd);
  } while (!_solvable(width, result) ||
      result.any((v) => result[v] == v || result[v] == copy[v]));
  return result;
}

// Logic from
// https://www.cs.bham.ac.uk/~mdr/teaching/modules04/java2/TilesSolvability.html
// Used with gratitude!
bool _solvable(int width, List<int> list) {
  final height = list.length ~/ width;
  assert(width * height == list.length);
  final inversions = _countInversions(list);

  if (width.isOdd) {
    return inversions.isEven;
  }

  final blankRow = list.indexOf(list.length - 1) ~/ width;

  if ((height - blankRow).isEven) {
    return inversions.isOdd;
  } else {
    return inversions.isEven;
  }
}

int _countInversions(List<int> items) {
  final tileCount = items.length - 1;
  var score = 0;
  for (var i = 0; i < items.length; i++) {
    final value = items[i];
    if (value == tileCount) {
      continue;
    }
    score += items
        .skip(i + 1)
        .where((v) => v != tileCount)
        .where((v) => v < value)
        .length;
  }
  return score;
}
