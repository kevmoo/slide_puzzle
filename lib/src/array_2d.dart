import 'dart:math' as math;
import 'dart:typed_data';

import 'util.dart';

class Array2d {
  final int width;

  int get height => _source.length ~/ width;
  final Uint8List _source;

  UnmodifiableUint8ListView get dataView => UnmodifiableUint8ListView(_source);

  Array2d._raw(this.width, this._source);

  Array2d.wrap(this.width, this._source) {
    requireArgumentNotNull(width, 'width');
    requireArgumentNotNull(_source, 'source');
    requireArgument(width >= 0, 'width', 'width must be non-zero');

    if (width * height == 0) {
      requireArgument(_source.isEmpty, 'width',
          'width must be greater than zero if the source is non-empty');
    } else {
      requireArgument(_source.isNotEmpty, 'source',
          'if width is non-zero, source must be non-empty');
      requireArgument(_source.length % width == 0, 'width',
          'width must evenly divide the source');
    }
  }

  Array2d clone() => Array2d._raw(width, Uint8List.fromList(_source));

  int get length => _source.length;

  int operator [](int index) => _source[index];

  int getValueAtLocation(int x, int y) {
    final i = _getIndex(x, y);
    return _source[i];
  }

  void swap(math.Point<int> a, math.Point<int> b) {
    final aIndex = _getIndex(a.x, a.y);
    final aValue = _source[aIndex];
    final bIndex = _getIndex(b.x, b.y);

    _source[aIndex] = _source[bIndex];
    _source[bIndex] = aValue;
  }

  math.Point<int> coordinatesOfValue(int value) {
    final index = _source.indexOf(value);
    final x = index % width;
    final y = index ~/ width;
    assert(_getIndex(x, y) == index);
    return math.Point<int>(x, y);
  }

  void setValues(List<int> values) {
    assert(values.length == _source.length);
    _source.setRange(0, _source.length, values);
  }

  int _getIndex(int x, int y) {
    assert(x >= 0 && x < width);
    assert(y >= 0 && y < height);
    return x + y * width;
  }

  @override
  String toString() {
    final grid = List<List<String>>.generate(
        height,
        (row) => List<String>.generate(
            width, (col) => getValueAtLocation(col, row).toString()));

    final longestLength = grid
        .expand((r) => r)
        .fold(0, (int l, cell) => math.max(l, cell.length));

    return grid
        .map((r) => r.map((v) => v.padLeft(longestLength)).join(' '))
        .join('\n');
  }
}
