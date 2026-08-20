// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:slide_puzzle/src/core/puzzle.dart';
import 'package:test/test.dart';

Puzzle _ordered(int width, int height) {
  final length = width * height;
  final list = List<int>.generate(length, (i) => i);
  return Puzzle.raw(width, list);
}

void main() {
  group('5x5 _PuzzleSimple (25 tiles)', () {
    test('initial solved state metrics', () {
      final puzzle = _ordered(5, 5);

      expect(puzzle.width, 5);
      expect(puzzle.height, 5);
      expect(puzzle.length, 25);
      expect(puzzle.tileCount, 24);
      expect(puzzle.openPosition(), const math.Point(4, 4));

      expect(puzzle.incorrectTiles, 0);
      expect(puzzle.fitness, 0);
      expect(puzzle.lowerBound, 0);
      expect(puzzle.solvable, isTrue);

      expect(
        puzzle.clickableValues(),
        unorderedEquals([20, 21, 22, 23, 4, 9, 14, 19]),
      );
      expect(
        puzzle.clickableValues(vertical: true),
        unorderedEquals([4, 9, 14, 19]),
      );
      expect(
        puzzle.clickableValues(vertical: false),
        unorderedEquals([20, 21, 22, 23]),
      );
    });

    test('single adjacent tile click updates stats correctly', () {
      final puzzle = _ordered(5, 5);
      // Click tile 23 (moves left to open position 4,4)
      final next = puzzle.clickValue(23);
      expect(next, isNotNull);
      expect(next!.openPosition(), const math.Point(3, 4));
      expect(next.valueAt(4, 4), 23);
      expect(next.valueAt(3, 4), 24); // open tile

      expect(next.incorrectTiles, 1);
      expect(next.fitness, 1); // Manhattan = 1, deltaSumSq = 1
      expect(next.lowerBound, 1);
    });

    test('multi-tile horizontal shift updates stats and tiles correctly', () {
      final puzzle = _ordered(5, 5);
      // Click tile 21 at (1, 4) with open spot at (4, 4)
      final next = puzzle.clickValue(21);
      expect(next, isNotNull);
      expect(next!.openPosition(), const math.Point(1, 4));
      expect(next.valueAt(1, 4), 24); // open tile
      expect(next.valueAt(2, 4), 21); // shifted
      expect(next.valueAt(3, 4), 22); // shifted
      expect(next.valueAt(4, 4), 23); // shifted

      expect(next.incorrectTiles, 3);
      expect(next.lowerBound, 3);
    });

    test('multi-tile vertical shift updates stats and tiles correctly', () {
      final puzzle = _ordered(5, 5);
      // Click tile 9 at (4, 1) with open spot at (4, 4)
      final next = puzzle.clickValue(9);
      expect(next, isNotNull);
      expect(next!.openPosition(), const math.Point(4, 1));
      expect(next.valueAt(4, 1), 24); // open tile
      expect(next.valueAt(4, 2), 9);
      expect(next.valueAt(4, 3), 14);
      expect(next.valueAt(4, 4), 19);

      expect(next.incorrectTiles, 3);
      expect(next.lowerBound, 3);
    });

    test('linear conflicts calculated accurately on 5x5 board', () {
      // Create a 5x5 board where tiles 0 and 1 in row 0 are inverted: [1, 0, 2, 3, 4, ...]
      final list = List<int>.generate(25, (i) => i);
      list[0] = 1;
      list[1] = 0;

      final puzzle = Puzzle.raw(5, list);
      expect(puzzle.incorrectTiles, 2);
      // Manhattan = 1 (for tile 0) + 1 (for tile 1) = 2
      // Linear conflict in row 0 adds 2
      expect(puzzle.lowerBound, 4);
    });

    test('equality, hashCode, clone, and indexing on _PuzzleSimple', () {
      final p1 = _ordered(5, 5);
      final p2 = _ordered(5, 5);
      final p3 = p1.clickValue(23)!;

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));

      final clone = p1.clone();
      expect(clone, equals(p1));
      expect(clone.hashCode, equals(p1.hashCode));
      expect(clone.incorrectTiles, p1.incorrectTiles);
      expect(clone.lowerBound, p1.lowerBound);

      for (var i = 0; i < 25; i++) {
        expect(p1[i], i);
        expect(p1.indexOf(i), i);
      }
    });

    test('click invalid non-aligned tile returns null', () {
      final puzzle = _ordered(5, 5);
      // Open is at (4,4), tile 0 is at (0,0) which is not in row 4 or col 4
      expect(puzzle.clickValue(0), isNull);
    });
  });
}
