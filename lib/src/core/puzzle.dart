// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:math' show Random, max;
import 'dart:typed_data';

import 'point_int.dart';
import 'util.dart';

part 'puzzle_simple.dart';
part 'puzzle_smart.dart';

final _rnd = Random();

final _spacesRegexp = RegExp(' +');

const _colLookup = [0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3];

const _rowLookup = [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3];

sealed class Puzzle {
  int get width;

  int get length;

  int operator [](int index);

  int indexOf(int value);

  List<int> get _intView;

  List<int> _copyData();

  Puzzle _newWithValues(List<int> values);

  Puzzle clone();

  int get height => (width == 4) ? length >> 2 : length ~/ width;

  Puzzle._();

  factory Puzzle._raw(int width, List<int> source) {
    if (source.length <= 16) {
      return _PuzzleSmart(width, source);
    }
    return _PuzzleSimple(width, source);
  }

  factory Puzzle.raw(int width, List<int> source) {
    requireArgument(width >= 3, 'width', 'Must be at least 3.');
    requireArgument(source.length >= 6, 'source', 'Must be at least 6 items');
    _validate(source);

    return Puzzle._raw(width, source);
  }

  factory Puzzle(int width, int height, {Random? random, bool easy = false}) =>
      Puzzle.raw(width, _randomList(width, height, random: random, easy: easy));

  factory Puzzle.parse(String input) {
    final rows = LineSplitter.split(input).map((line) {
      final splits = line.trim().split(_spacesRegexp);
      return splits.map(int.parse).toList();
    }).toList();

    return Puzzle.raw(rows.first.length, rows.expand((row) => row).toList());
  }

  int valueAt(int x, int y) {
    final i = _getIndex(x, y);
    return this[i];
  }

  int get tileCount => length - 1;

  bool isCorrectPosition(int cellValue) => cellValue == this[cellValue];

  bool get solvable => isSolvable(width, _intView);

  Puzzle reset({List<int>? source}) {
    final data = (source == null)
        ? _randomizeList(width, _intView)
        : Uint8List.fromList(source);

    if (data.length != length) {
      throw ArgumentError.value(source, 'source', 'Cannot change the size!');
    }
    _validate(data);
    if (!isSolvable(width, data)) {
      throw ArgumentError.value(source, 'source', 'Not a solvable puzzle.');
    }

    return _newWithValues(data);
  }

  int? _fitnessCache;
  int? _incorrectTilesCache;
  int? _lowerBoundCache;

  int? _incorrect;
  int? _deltaSumSq;
  int? _manhattan;
  int? _linearConflicts;

  Puzzle._optionalStats({
    int? incorrect,
    int? deltaSumSq,
    int? manhattan,
    int? linearConflicts,
  }) : _incorrect = incorrect,
       _deltaSumSq = deltaSumSq,
       _manhattan = manhattan,
       _linearConflicts = linearConflicts,
       _incorrectTilesCache = incorrect,
       _fitnessCache = (deltaSumSq != null && incorrect != null)
           ? deltaSumSq * incorrect
           : null,
       _lowerBoundCache = (manhattan != null && linearConflicts != null)
           ? manhattan + 2 * linearConflicts
           : null;

  void _setStats(
    int incorrect,
    int deltaSumSq,
    int manhattan,
    int linearConflicts,
  ) {
    _incorrect = incorrect;
    _deltaSumSq = deltaSumSq;
    _manhattan = manhattan;
    _linearConflicts = linearConflicts;
    _incorrectTilesCache = incorrect;
    _fitnessCache = deltaSumSq * incorrect;
    _lowerBoundCache = manhattan + 2 * linearConflicts;
  }

  int get incorrectTiles {
    if (_incorrectTilesCache != null) return _incorrectTilesCache!;
    _computeStats();
    return _incorrectTilesCache!;
  }

  Point openPosition() => coordinatesOf(tileCount);

  /// A measure of how close the puzzle is to being solved.
  ///
  /// The sum of all of the distances squared `(x + y)^2 ` each tile has to move
  /// to be in the correct position.
  ///
  /// `0` - you've won!
  int get fitness {
    if (_fitnessCache != null) return _fitnessCache!;
    _computeStats();
    return _fitnessCache!;
  }

  int get lowerBound {
    if (_lowerBoundCache != null) return _lowerBoundCache!;
    _computeStats();
    return _lowerBoundCache!;
  }

  void _computeStats() {
    var deltaSumSq = 0;
    var incorrect = 0;
    var manhattan = 0;
    final openTile = length - 1;
    final w = width;
    final h = height;

    if (w == 4) {
      for (var pos = 0; pos < length; pos++) {
        final val = this[pos];
        if (val != pos && val != openTile) {
          incorrect++;
          final correctCol = val & 3;
          final correctRow = val >> 2;
          final currentCol = pos & 3;
          final currentRow = pos >> 2;

          final colDelta = (correctCol - currentCol).abs();
          final rowDelta = (correctRow - currentRow).abs();
          final delta = colDelta + rowDelta;

          deltaSumSq += delta * delta;
          manhattan += delta;
        }
      }

      var linearConflicts = 0;
      for (var r = 0; r < 4; r++) {
        var goalsMask = 0;
        var goalsCount = 0;
        final rowOffset = r << 2;
        for (var c = 0; c < 4; c++) {
          final val = this[c + rowOffset];
          if (val != openTile && (val >> 2) == r) {
            goalsMask |= (val & 3) << (goalsCount << 2);
            goalsCount++;
          }
        }
        linearConflicts += countRemovals(goalsMask, goalsCount);
      }
      for (var c = 0; c < 4; c++) {
        var goalsMask = 0;
        var goalsCount = 0;
        for (var r = 0; r < 4; r++) {
          final val = this[c + (r << 2)];
          if (val != openTile && (val & 3) == c) {
            goalsMask |= (val >> 2) << (goalsCount << 2);
            goalsCount++;
          }
        }
        linearConflicts += countRemovals(goalsMask, goalsCount);
      }

      _setStats(incorrect, deltaSumSq, manhattan, linearConflicts);
      return;
    }

    for (var pos = 0; pos < length; pos++) {
      final val = this[pos];
      if (val != pos && val != openTile) {
        incorrect++;
        final correctCol = val % w;
        final correctRow = val ~/ w;
        final currentCol = pos % w;
        final currentRow = pos ~/ w;

        final colDelta = (correctCol - currentCol).abs();
        final rowDelta = (correctRow - currentRow).abs();
        final delta = colDelta + rowDelta;

        deltaSumSq += delta * delta;
        manhattan += delta;
      }
    }

    var linearConflicts = 0;
    for (var r = 0; r < h; r++) {
      var goalsMask = 0;
      var goalsCount = 0;
      for (var c = 0; c < w; c++) {
        final val = this[c + r * w];
        if (val != openTile && val ~/ w == r) {
          goalsMask |= (val % w) << (goalsCount << 2);
          goalsCount++;
        }
      }
      linearConflicts += countRemovals(goalsMask, goalsCount);
    }
    for (var c = 0; c < w; c++) {
      var goalsMask = 0;
      var goalsCount = 0;
      for (var r = 0; r < h; r++) {
        final val = this[c + r * w];
        if (val != openTile && val % w == c) {
          goalsMask |= (val ~/ w) << (goalsCount << 2);
          goalsCount++;
        }
      }
      linearConflicts += countRemovals(goalsMask, goalsCount);
    }

    _setStats(incorrect, deltaSumSq, manhattan, linearConflicts);
  }

  Puzzle? clickRandom({bool? vertical}) {
    final clickable = clickableValues(vertical: vertical).toList();
    return clickValue(clickable[_rnd.nextInt(clickable.length)]);
  }

  Iterable<Puzzle> allMovable() =>
      (clickableValues()..shuffle(_rnd)).map(_clickValue);

  List<int> clickableValues({bool? vertical}) {
    final open = openPosition();
    final doRow = vertical == null || vertical == false;
    final doColumn = vertical == null || vertical;

    final values = Uint8List(
      (doRow ? (width - 1) : 0) + (doColumn ? (height - 1) : 0),
    );

    var index = 0;

    if (doRow) {
      for (var x = 0; x < width; x++) {
        if (x != open.x) {
          values[index++] = valueAt(x, open.y);
        }
      }
    }
    if (doColumn) {
      for (var y = 0; y < height; y++) {
        if (y != open.y) {
          values[index++] = valueAt(open.x, y);
        }
      }
    }

    return values;
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

  Puzzle? clickValue(int tileValue) {
    if (!_movable(tileValue)) {
      return null;
    }
    return _clickValue(tileValue);
  }

  Puzzle _clickValue(int tileValue) {
    assert(_movable(tileValue));
    final target = coordinatesOf(tileValue);

    if (_incorrect == null) {
      _computeStats();
    }

    final newStore = _copyData();
    final lastCoord = openPosition();
    final (deltaX, deltaY) = (lastCoord.x - target.x, lastCoord.y - target.y);

    final w = width;
    final h = height;
    final openTile = length - 1;

    var newIncorrect = _incorrect!;
    var newDeltaSumSq = _deltaSumSq!;
    var newManhattan = _manhattan!;

    final stepX = deltaX.sign;
    final stepY = deltaY.sign;
    var currX = target.x;
    var currY = target.y;
    while (currX != lastCoord.x || currY != lastCoord.y) {
      final oldPos = (w == 4) ? currX + (currY << 2) : currX + currY * w;
      final val = this[oldPos];
      if (val != openTile) {
        final correctCol = (w == 4) ? val & 3 : val % w;
        final correctRow = (w == 4) ? val >> 2 : val ~/ w;

        final oldColDelta = (correctCol - currX).abs();
        final oldRowDelta = (correctRow - currY).abs();
        final oldDelta = oldColDelta + oldRowDelta;
        final oldInc = (val != oldPos) ? 1 : 0;
        final oldSq = oldInc * (oldDelta * oldDelta);
        final oldMan = oldInc * oldDelta;

        final newX = currX + stepX;
        final newY = currY + stepY;
        final newPos = (w == 4) ? newX + (newY << 2) : newX + newY * w;
        final newColDelta = (correctCol - newX).abs();
        final newRowDelta = (correctRow - newY).abs();
        final newDelta = newColDelta + newRowDelta;
        final newInc = (val != newPos) ? 1 : 0;
        final newSq = newInc * (newDelta * newDelta);
        final newMan = newInc * newDelta;

        newIncorrect += newInc - oldInc;
        newDeltaSumSq += newSq - oldSq;
        newManhattan += newMan - oldMan;
      }
      currX += stepX;
      currY += stepY;
    }

    var newLinearConflicts = _linearConflicts!;
    if (target.y == lastCoord.y) {
      final r = target.y;
      final oldRowConflicts = (w == 4)
          ? _rowConflictsCore4(r, openTile, (i) => this[i])
          : _rowConflictsCore(w, r, w, openTile, (i) => this[i]);
      var oldColConflicts = 0;
      final minC = (target.x < lastCoord.x) ? target.x : lastCoord.x;
      final maxC = (target.x > lastCoord.x) ? target.x : lastCoord.x;
      for (var c = minC; c <= maxC; c++) {
        oldColConflicts += (w == 4)
            ? _colConflictsCore4(c, openTile, (i) => this[i])
            : _colConflictsCore(w, h, c, openTile, (i) => this[i]);
      }

      _shift(newStore, target.x, target.y);

      final newRowConflicts = (w == 4)
          ? _rowConflictsCore4(r, openTile, (i) => newStore[i])
          : _rowConflictsCore(w, r, w, openTile, (i) => newStore[i]);
      var newColConflicts = 0;
      for (var c = minC; c <= maxC; c++) {
        newColConflicts += (w == 4)
            ? _colConflictsCore4(c, openTile, (i) => newStore[i])
            : _colConflictsCore(w, h, c, openTile, (i) => newStore[i]);
      }
      newLinearConflicts +=
          (newRowConflicts - oldRowConflicts) +
          (newColConflicts - oldColConflicts);
    } else {
      final c = target.x;
      final oldColConflicts = (w == 4)
          ? _colConflictsCore4(c, openTile, (i) => this[i])
          : _colConflictsCore(w, h, c, openTile, (i) => this[i]);
      var oldRowConflicts = 0;
      final minR = (target.y < lastCoord.y) ? target.y : lastCoord.y;
      final maxR = (target.y > lastCoord.y) ? target.y : lastCoord.y;
      for (var r = minR; r <= maxR; r++) {
        oldRowConflicts += (w == 4)
            ? _rowConflictsCore4(r, openTile, (i) => this[i])
            : _rowConflictsCore(w, r, w, openTile, (i) => this[i]);
      }

      _shift(newStore, target.x, target.y);

      final newColConflicts = (w == 4)
          ? _colConflictsCore4(c, openTile, (i) => newStore[i])
          : _colConflictsCore(w, h, c, openTile, (i) => newStore[i]);
      var newRowConflicts = 0;
      for (var r = minR; r <= maxR; r++) {
        newRowConflicts += (w == 4)
            ? _rowConflictsCore4(r, openTile, (i) => newStore[i])
            : _rowConflictsCore(w, r, w, openTile, (i) => newStore[i]);
      }
      newLinearConflicts +=
          (newColConflicts - oldColConflicts) +
          (newRowConflicts - oldRowConflicts);
    }

    if (this is _PuzzleSimple) {
      return _PuzzleSimple(
        width,
        newStore,
        incorrect: newIncorrect,
        deltaSumSq: newDeltaSumSq,
        manhattan: newManhattan,
        linearConflicts: newLinearConflicts,
      );
    }
    return _newWithValues(newStore);
  }

  void _shift(List<int> source, int targetX, int targetY) {
    final lastCoord = openPosition();
    final (deltaX, deltaY) = (lastCoord.x - targetX, lastCoord.y - targetY);

    if ((deltaX.abs() + deltaY.abs()) > 1) {
      final (shiftPointX, shiftPointY) = (
        targetX + deltaX.sign,
        targetY + deltaY.sign,
      );
      _shift(source, shiftPointX, shiftPointY);
      _staticSwap(source, targetX, targetY, shiftPointX, shiftPointY);
    } else {
      _staticSwap(source, lastCoord.x, lastCoord.y, targetX, targetY);
    }
  }

  void _staticSwap(List<int> source, int ax, int ay, int bx, int by) {
    final aIndex = (width == 4) ? ax + (ay << 2) : ax + ay * width;
    final bIndex = (width == 4) ? bx + (by << 2) : bx + by * width;
    final temp = source[aIndex];
    source[aIndex] = source[bIndex];
    source[bIndex] = temp;
  }

  static int _rowConflictsCore4(
    int r,
    int openTile,
    int Function(int index) getVal,
  ) {
    var goalsMask = 0;
    var goalsCount = 0;
    final rowOffset = r << 2;
    for (var c = 0; c < 4; c++) {
      final val = getVal(c + rowOffset);
      if (val != openTile && (val >> 2) == r) {
        goalsMask |= (val & 3) << (goalsCount << 2);
        goalsCount++;
      }
    }
    return countRemovals(goalsMask, goalsCount);
  }

  static int _colConflictsCore4(
    int c,
    int openTile,
    int Function(int index) getVal,
  ) {
    var goalsMask = 0;
    var goalsCount = 0;
    for (var r = 0; r < 4; r++) {
      final val = getVal(c + (r << 2));
      if (val != openTile && (val & 3) == c) {
        goalsMask |= (val >> 2) << (goalsCount << 2);
        goalsCount++;
      }
    }
    return countRemovals(goalsMask, goalsCount);
  }

  static int _rowConflictsCore(
    int w,
    int r,
    int rowLen,
    int openTile,
    int Function(int index) getVal,
  ) {
    var goalsMask = 0;
    var goalsCount = 0;
    final rowOffset = r * rowLen;
    for (var c = 0; c < rowLen; c++) {
      final val = getVal(c + rowOffset);
      if (val != openTile && val ~/ w == r) {
        goalsMask |= (val % w) << (goalsCount << 2);
        goalsCount++;
      }
    }
    return countRemovals(goalsMask, goalsCount);
  }

  static int _colConflictsCore(
    int w,
    int h,
    int c,
    int openTile,
    int Function(int index) getVal,
  ) {
    var goalsMask = 0;
    var goalsCount = 0;
    for (var r = 0; r < h; r++) {
      final val = getVal(c + r * w);
      if (val != openTile && val % w == c) {
        goalsMask |= (val ~/ w) << (goalsCount << 2);
        goalsCount++;
      }
    }
    return countRemovals(goalsMask, goalsCount);
  }

  Point coordinatesOf(int value) {
    final index = indexOf(value);
    final int x, y;
    if (width == 4 && index < 16) {
      x = _colLookup[index];
      y = _rowLookup[index];
    } else {
      x = index % width;
      y = index ~/ width;
    }
    assert(_getIndex(x, y) == index);
    return Point(x, y);
  }

  int _getIndex(int x, int y) {
    assert(x >= 0 && x < width);
    assert(y >= 0 && y < height);
    return (width == 4) ? x + (y << 2) : x + y * width;
  }

  @override
  String toString() => _toString();

  String _toString() {
    final grid = List<List<String>>.generate(
      height,
      (row) =>
          List<String>.generate(width, (col) => valueAt(col, row).toString()),
    );

    final longestLength = grid
        .expand((r) => r)
        .fold(0, (int l, cell) => max(l, cell.length));

    return grid
        .map((r) => r.map((v) => v.padLeft(longestLength)).join(' '))
        .join('\n');
  }
}

Uint8List _randomList(
  int width,
  int height, {
  Random? random,
  bool easy = false,
}) => _randomizeList(
  width,
  List<int>.generate(width * height, (i) => i, growable: false),
  random: random,
  easy: easy,
);

Uint8List _randomizeList(
  int width,
  List<int> existing, {
  Random? random,
  bool easy = false,
}) {
  final copy = Uint8List.fromList(existing);
  final rnd = random ?? _rnd;
  final height = (width == 4) ? existing.length >> 2 : existing.length ~/ width;
  do {
    if (easy && width > 2 && height > 2) {
      final activeIndices = <int>[];
      for (var r = 0; r < height - 1; r++) {
        for (var c = 0; c < width - 1; c++) {
          activeIndices.add(r * width + c);
        }
      }
      final activeValues = activeIndices.map((i) => copy[i]).toList();
      activeValues.shuffle(rnd);
      for (var i = 0; i < activeIndices.length; i++) {
        copy[activeIndices[i]] = activeValues[i];
      }
    } else {
      copy.shuffle(rnd);
    }
  } while (!isSolvable(width, copy) ||
      (easy && width > 2 && height > 2
          ? copy[0] == 0 && copy[1] == 1 && copy[width] == width
          : copy.any((v) => copy[v] == v || copy[v] == existing[v])));
  return copy;
}

void _validate(List<int> source) {
  for (var i = 0; i < source.length; i++) {
    requireArgument(
      source.contains(i),
      'source',
      'Must contain each number from 0 to `length - 1` '
          'once and only once.',
    );
  }
}
