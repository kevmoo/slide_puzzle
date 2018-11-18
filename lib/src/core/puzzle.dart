import 'dart:convert';
import 'dart:math' show Random, max;
import 'dart:typed_data';

import 'point_int.dart';
import 'util.dart';

final _rnd = Random();

final _spacesRegexp = RegExp(' +');

class Puzzle {
  final Uint8List _source;

  final int width;

  int get height => _source.length ~/ width;

  Puzzle._raw(this.width, this._source);

  Puzzle.raw(this.width, List<int> source)
      : _source = Uint8List.fromList(source) {
    requireArgument(width >= 2, 'width', 'Must be at least 2.');
    requireArgument(_source.length >= 6, 'source', 'Must be at least 6 items');

    _validate(_source);
  }

  Puzzle(int width, int height) : this.raw(width, _randomList(width, height));

  factory Puzzle.parse(String input) {
    final rows = LineSplitter.split(input).map((line) {
      final splits = line.trim().split(_spacesRegexp);
      return splits.map(int.parse).toList();
    }).toList();

    return Puzzle.raw(rows.first.length, rows.expand((row) => row).toList());
  }

  int valueAt(int x, int y) {
    final i = _getIndex(x, y);
    return _source[i];
  }

  int get length => _source.length;

  int get tileCount => _source.length - 1;

  bool isCorrectPosition(int cellValue) => cellValue == _source[cellValue];

  bool get solvable => _solvable(width, _source);

  Puzzle reset({List<int> source}) {
    final data = (source == null)
        ? _randomizeList(width, _source)
        : Uint8List.fromList(source);

    if (data.length != _source.length) {
      throw ArgumentError.value(source, 'source', 'Cannot change the size!');
    }
    _validate(data);
    if (!_solvable(width, data)) {
      throw ArgumentError.value(source, 'source', 'Not a solvable puzzle.');
    }

    return Puzzle._raw(width, data);
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

  Point openPosition() => coordinatesOf(tileCount);

  Puzzle clone() => Puzzle._raw(width, Uint8List.fromList(_source));

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

  Puzzle clickRandom({bool vertical}) {
    final clickable = clickableValues(vertical: vertical).toList();
    return clickValue(clickable[_rnd.nextInt(clickable.length)]);
  }

  Iterable<int> clickableValues({bool vertical}) sync* {
    final open = openPosition();
    if (vertical == null || vertical == false) {
      for (var x = 0; x < width; x++) {
        if (x != open.x) {
          yield valueAt(x, open.y);
        }
      }
    }
    if (vertical == null || vertical) {
      for (var y = 0; y < height; y++) {
        if (y != open.y) {
          yield valueAt(open.x, y);
        }
      }
    }
  }

  bool _movable(int tileValue) {
    if (tileValue == tileCount) {
      return false;
    }

    final target = coordinatesOf(tileValue);
    final lastCoord = openPosition();
    if (lastCoord.x != target.x && lastCoord.y != target.y) {
      return false;
    }
    return true;
  }

  Puzzle clickValue(int tileValue) {
    if (!_movable(tileValue)) {
      return null;
    }
    final target = coordinatesOf(tileValue);

    final newStore = Uint8List.fromList(_source);

    _shift(newStore, target);
    return Puzzle._raw(width, newStore);
  }

  void _shift(Uint8List source, Point target) {
    final lastCoord = openPosition();
    final delta = lastCoord - target;

    void _staticSwap(Point a, Point b) {
      final aIndex = a.x + a.y * width;
      final aValue = source[aIndex];
      final bIndex = b.x + b.y * width;

      source[aIndex] = source[bIndex];
      source[bIndex] = aValue;
    }

    if (delta.magnitude.toInt() > 1) {
      final shiftPoint = target + Point(delta.x.sign, delta.y.sign);
      _shift(source, shiftPoint);
      _staticSwap(target, shiftPoint);
    } else {
      _staticSwap(lastCoord, target);
    }
  }

  Point coordinatesOf(int value) {
    final index = _source.indexOf(value);
    final x = index % width;
    final y = index ~/ width;
    assert(_getIndex(x, y) == index);
    return Point(x, y);
  }

  int _getIndex(int x, int y) {
    assert(x >= 0 && x < width);
    assert(y >= 0 && y < height);
    return x + y * width;
  }

  @override
  bool operator ==(other) {
    if (other is Puzzle && other.width == width && other.length == length) {
      for (var i = 0; i < _source.length; i++) {
        if (other._source[i] != _source[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    var _idCache = 0;
    for (var i = 0; i < _source.length; i++) {
      _idCache = (_idCache << 2) + _source[i];
    }
    _idCache += _idCache << 3;
    _idCache ^= _idCache >> 11;
    _idCache += _idCache << 15;
    return _idCache;
  }

  @override
  String toString() {
    final grid = List<List<String>>.generate(
        height,
        (row) => List<String>.generate(
            width, (col) => valueAt(col, row).toString()));

    final longestLength =
        grid.expand((r) => r).fold(0, (int l, cell) => max(l, cell.length));

    return grid
        .map((r) => r.map((v) => v.padLeft(longestLength)).join(' '))
        .join('\n');
  }
}

Uint8List _randomList(int width, int height) => _randomizeList(
    width, List<int>.generate(width * height, (i) => i, growable: false));

Uint8List _randomizeList(int width, List<int> existing) {
  final copy = Uint8List.fromList(existing);
  do {
    copy.shuffle(_rnd);
  } while (!_solvable(width, copy) ||
      copy.any((v) => copy[v] == v || copy[v] == existing[v]));
  return copy;
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

void _validate(List<int> source) {
  for (var i = 0; i < source.length; i++) {
    requireArgument(
        source.contains(i),
        'source',
        'Must contain each number from 0 to `length - 1` '
        'once and only once.');
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

    for (var j = i + 1; j < items.length; j++) {
      final v = items[j];
      if (v != tileCount && v < value) {
        score++;
      }
    }
  }
  return score;
}
