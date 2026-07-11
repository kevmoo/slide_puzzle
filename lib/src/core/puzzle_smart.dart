// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'puzzle.dart';

extension type const _SliceList(Uint32List _data) {
  static const _bitsPerValue = 4;
  static const _maxShift = _valuesPerCell - 1;

  static const _bitsPerCell = 32;
  static const _valuesPerCell = _bitsPerCell ~/ _bitsPerValue;
  static const _valueMask = (1 << _bitsPerValue) - 1;

  int _cellValue(int index) => _data[index >> 3];

  int operator [](int index) =>
      (_cellValue(index) >> ((_maxShift - (index & 7)) << 2)) & _valueMask;

  void operator []=(int index, int value) {
    var cellValue = _cellValue(index);

    final sharedShift = (_maxShift - (index & 7)) << 2;

    final wipeout = _valueMask << sharedShift;

    cellValue &= ~wipeout;

    final newShiftedValue = value << sharedShift;

    cellValue |= newShiftedValue;

    _data[index >> 3] = cellValue;
  }

  int indexOf(Object? value, [int start = 0, int length = 16]) {
    if (value is int) {
      for (var i = 0; i < _data.length; i++) {
        final cellValue = _data[i];
        for (var j = 0; j < _valuesPerCell; j++) {
          final option = (cellValue >> ((_maxShift - j) << 2)) & _valueMask;

          if (value == option) {
            final k = (i << 3) + j;
            if (k < length && (k >= start)) {
              return k;
            }
          }
        }
      }
    }
    return -1;
  }
}

final class _PuzzleSmart extends Puzzle with ListMixin<int> {
  static const _bitsPerValue = 4;
  static const _maxShift = _valuesPerCell - 1;

  static const _bitsPerCell = 32;
  static const _valuesPerCell = _bitsPerCell ~/ _bitsPerValue;

  final Uint32List _data;

  @override
  final int width;

  @override
  final int length;

  @override
  set length(int value) => throw UnsupportedError('immutable, yo!');

  _PuzzleSmart(this.width, List<int> source)
    : length = source.length,
      _data = _create(source),
      super._();

  _PuzzleSmart._direct(this.width, this.length, this._data) : super._();

  _SliceList get _slice => _SliceList(_data);

  @override
  int operator [](int index) => _slice[index];

  @override
  void operator []=(int index, int value) =>
      throw UnsupportedError('immutable, yo!');

  @override
  Point coordinatesOf(int value) {
    final index = indexOf(value);
    if (width == 4) {
      final x = _colLookup[index];
      final y = _rowLookup[index];
      assert(_getIndex(x, y) == index);
      return Point(x, y);
    }
    final (x, y) = (index % width, index ~/ width);
    assert(_getIndex(x, y) == index);
    return Point(x, y);
  }

  @override
  int indexOf(Object? value, [int start = 0]) =>
      _slice.indexOf(value, start, length);

  @override
  List<int> get _intView => this;

  @override
  List<int> _copyData() => Uint32List.fromList(_data);

  @override
  Puzzle _newWithValues(List<int> values) => _PuzzleSmart(width, values);

  @override
  Puzzle clone() =>
      _PuzzleSmart._direct(width, length, Uint32List.fromList(_data));

  @override
  Puzzle _clickValue(int tileValue) {
    assert(_movable(tileValue));
    final target = coordinatesOf(tileValue);

    final newStore = _SliceList(Uint32List.fromList(_data));

    _shiftSlice(newStore, target.x, target.y);
    return _PuzzleSmart._direct(width, length, newStore._data);
  }

  void _shiftSlice(_SliceList source, int targetX, int targetY) {
    final lastCoord = openPosition();
    final (deltaX, deltaY) = (lastCoord.x - targetX, lastCoord.y - targetY);

    if ((deltaX.abs() + deltaY.abs()) > 1) {
      final (shiftPointX, shiftPointY) = (
        targetX + deltaX.sign,
        targetY + deltaY.sign,
      );
      _shiftSlice(source, shiftPointX, shiftPointY);
      _staticSwapSlice(source, targetX, targetY, shiftPointX, shiftPointY);
    } else {
      _staticSwapSlice(source, lastCoord.x, lastCoord.y, targetX, targetY);
    }
  }

  void _staticSwapSlice(_SliceList source, int ax, int ay, int bx, int by) {
    final aIndex = (width == 4) ? ax + (ay << 2) : ax + ay * width;
    final bIndex = (width == 4) ? bx + (by << 2) : bx + by * width;
    final temp = source[aIndex];
    source[aIndex] = source[bIndex];
    source[bIndex] = temp;
  }

  @override
  void _computeStats() {
    var deltaSumSq = 0;
    var incorrect = 0;
    var manhattan = 0;
    final openTile = length - 1;
    final w = width;
    final h = (w == 4) ? length >> 2 : length ~/ w;
    final slice = _slice;

    if (w == 4) {
      for (var pos = 0; pos < length; pos++) {
        final val = slice[pos];
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
          final val = slice[c + rowOffset];
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
          final val = slice[c + (r << 2)];
          if (val != openTile && (val & 3) == c) {
            goalsMask |= (val >> 2) << (goalsCount << 2);
            goalsCount++;
          }
        }
        linearConflicts += countRemovals(goalsMask, goalsCount);
      }

      _incorrectTilesCache = incorrect;
      _fitnessCache = deltaSumSq * incorrect;
      _lowerBoundCache = manhattan + 2 * linearConflicts;
      return;
    }

    for (var pos = 0; pos < length; pos++) {
      final val = slice[pos];
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
        final val = slice[c + r * w];
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
        final val = slice[c + r * w];
        if (val != openTile && val % w == c) {
          goalsMask |= (val ~/ w) << (goalsCount << 2);
          goalsCount++;
        }
      }
      linearConflicts += countRemovals(goalsMask, goalsCount);
    }

    _incorrectTilesCache = incorrect;
    _fitnessCache = deltaSumSq * incorrect;
    _lowerBoundCache = manhattan + 2 * linearConflicts;
  }

  @override
  String toString() => _toString();

  @override
  bool operator ==(Object other) {
    if (other is _PuzzleSmart &&
        other.width == width &&
        other._data.length == _data.length) {
      for (var i = 0; i < _data.length; i++) {
        if (other._data[i] != _data[i]) {
          return false;
        }
      }
      return true;
    }
    if (other is Puzzle && other.width == width && other.length == length) {
      for (var i = 0; i < length; i++) {
        if (other[i] != this[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    var v = 0;
    for (var i = 0; i < _data.length; i++) {
      v = (v << 2) + _data[i];
    }
    v += v << 3;
    v ^= v >> 11;
    v += v << 15;
    return v;
  }

  static Uint32List _create(List<int> source) {
    if (source is Uint32List) {
      return source;
    }

    final data = Uint32List((source.length / _valuesPerCell).ceil());
    for (var i = 0; i < data.length; i++) {
      var value = 0;
      for (var j = 0; j < _valuesPerCell; j++) {
        final k = (i << 3) + j;
        if (k < source.length) {
          // shift the value over 4 bits for item 0, 3 for item 2, etc
          final sourceValue = source[k] << ((_maxShift - j) << 2);
          value |= sourceValue;
        }
      }
      data[i] = value;
    }
    return data;
  }
}
