// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void requireArgument(bool truth, String argName, [String? message]) {
  if (!truth) {
    if (message == null || message.isEmpty) {
      message = 'value was invalid';
    }
    throw ArgumentError('`$argName` - $message');
  }
}

// Logic from
// https://www.cs.bham.ac.uk/~mdr/teaching/modules04/java2/TilesSolvability.html
// Used with gratitude!
bool isSolvable(int width, List<int> list) {
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

    for (var j = i + 1; j < items.length; j++) {
      final v = items[j];
      if (v != tileCount && v < value) {
        score++;
      }
    }
  }
  return score;
}

int countRemovals(int goalsMask, int goalsCount) {
  if (goalsCount <= 1) return 0;
  var maxLis = 1;
  var dpMask = 1;
  for (var i = 1; i < goalsCount; i++) {
    final goalI = (goalsMask >> (i << 2)) & 0xF;
    var dpI = 1;
    for (var j = 0; j < i; j++) {
      final goalJ = (goalsMask >> (j << 2)) & 0xF;
      final dpJ = (dpMask >> (j << 2)) & 0xF;
      if (goalJ < goalI && dpJ + 1 > dpI) {
        dpI = dpJ + 1;
        if (dpI > maxLis) maxLis = dpI;
      }
    }
    dpMask |= dpI << (i << 2);
  }
  return goalsCount - maxLis;
}
