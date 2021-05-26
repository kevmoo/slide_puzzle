// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:slide_puzzle/src/core/puzzle.dart';
import 'package:test/test.dart';

final _rnd = math.Random();

Puzzle _ordered(int width, int height, {int offset = 0}) {
  final length = width * height;
  final list = List<int>.generate(length, (i) {
    return (i - offset) % length;
  });
  return Puzzle.raw(width, list);
}

// printOnFailure trims input – which is weird – so adding a leading line
void _printPuzzleOnFailure(Puzzle puzzle) {
  printOnFailure('* here is the puzzle\n$puzzle');
}

void main() {
  test('must be at least 3 x 2', () {
    expect(() => Puzzle.raw(3, []), throwsArgumentError);
    expect(() => Puzzle.raw(3, [0, 1, 2]), throwsArgumentError);
    expect(Puzzle.raw(3, [0, 1, 2, 3, 4, 5]).incorrectTiles, 0);
  });

  test('initial values must be correct', () {
    expect(
        () => Puzzle.raw(3, [0, 1, 2, 3, 4, 5, 6, 7, 7]), throwsArgumentError);

    const width = 3, height = 3;

    final puzzle = _ordered(width, height);
    expect(puzzle.width, width);
    expect(puzzle.height, height);
    expect(puzzle.length, width * height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        expect(puzzle.valueAt(x, y), x + y * width);
      }
    }
  });

  test('toString', () {
    final puzzle = _ordered(4, 4);
    _printPuzzleOnFailure(puzzle);
    expect(puzzle.toString(), '''
 0  1  2  3
 4  5  6  7
 8  9 10 11
12 13 14 15''');
    expect(Puzzle.parse(puzzle.toString()).toString(), puzzle.toString());
  });

  group('click', () {
    Puzzle? doClick(Puzzle puzzle, int tileValue) {
      final clickResult = puzzle.clickValue(tileValue);
      expect(clickResult.toString(), isNot(puzzle.toString()));
      return clickResult;
    }

    test('click on last tile is a noop', () {
      var puzzle = _ordered(4, 4);
      expect(puzzle.valueAt(0, 0), 0);
      expect(doClick(puzzle, 0), isNull);

      puzzle = _ordered(3, 3, offset: 2);
      expect(puzzle.toString(), '''
7 8 0
1 2 3
4 5 6''');

      expect(puzzle.valueAt(2, 0), 0);
      expect(doClick(puzzle, 1), isNull);

      for (var i = 0; i < 10; i++) {
        puzzle = Puzzle(5, 5);
        expect(doClick(puzzle, 24), isNull,
            reason: 'clicking on the sliding tile is a no-op');
      }
    });

    test('click on a cell not aligned with zero is a noop', () {
      var puzzle = _ordered(4, 4);
      expect(puzzle.valueAt(1, 1), 5);
      expect(doClick(puzzle, 4), isNull);

      puzzle = _ordered(3, 3, offset: 2);
      expect(puzzle.valueAt(0, 1), 1);
      expect(doClick(puzzle, 3), isNull);

      for (var i = 0; i < 10; i++) {
        puzzle = Puzzle(5, 5);
        final zeroLocation = puzzle.coordinatesOf(24);

        for (var j = 0; j < 10; j++) {
          math.Point<int> randomPoint;
          do {
            randomPoint = math.Point(
                _rnd.nextInt(puzzle.width), _rnd.nextInt(puzzle.height));
          } while (randomPoint.x == zeroLocation.x ||
              randomPoint.y == zeroLocation.y);

          expect(doClick(puzzle, puzzle.valueAt(randomPoint.x, randomPoint.y)),
              isNull);
        }
      }
    });

    test('click to shift', () {
      var puzzle = _ordered(4, 4, offset: 1);
      expect(puzzle.incorrectTiles, 15);
      expect(puzzle.toString(), '''
15  0  1  2
 3  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(puzzle.valueAt(1, 0), 0);
      puzzle = doClick(puzzle, 0)!;
      expect(puzzle.toString(), '''
 0 15  1  2
 3  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(doClick(puzzle, 15), isNull);
      puzzle = doClick(puzzle, 0)!;
      expect(puzzle.toString(), '''
15  0  1  2
 3  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(doClick(puzzle, 15), isNull);
      puzzle = doClick(puzzle, 3)!;
      expect(puzzle.toString(), '''
 3  0  1  2
15  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(doClick(puzzle, 15), isNull);
      puzzle = doClick(puzzle, 3)!;
      expect(puzzle.toString(), '''
15  0  1  2
 3  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(doClick(puzzle, 15), isNull);
      puzzle = doClick(puzzle, 2)!;
      expect(puzzle.toString(), '''
 0  1  2 15
 3  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(puzzle.incorrectTiles, 12);
      expect(doClick(puzzle, 15), isNull);
      puzzle = doClick(puzzle, 14)!;
      expect(puzzle.toString(), '''
 0  1  2  6
 3  4  5 10
 7  8  9 14
11 12 13 15''');

      expect(doClick(puzzle, 15), isNull);
      puzzle = doClick(puzzle, 11)!;
      expect(puzzle.toString(), '''
 0  1  2  6
 3  4  5 10
 7  8  9 14
15 11 12 13''');

      expect(doClick(puzzle, 15), isNull);
      puzzle = doClick(puzzle, 0)!;
      expect(puzzle.toString(), '''
15  1  2  6
 0  4  5 10
 3  8  9 14
 7 11 12 13''');

      expect(puzzle.clickableValues(), unorderedEquals([0, 3, 7, 1, 2, 6]));
      expect(
          puzzle.clickableValues(vertical: true), unorderedEquals([0, 3, 7]));
      expect(
          puzzle.clickableValues(vertical: false), unorderedEquals([1, 2, 6]));

      expect(puzzle.incorrectTiles, 13);
    });
  });

  test('new puzzles should have all tiles in incorrect positions', () {
    for (var width = 3; width < 6; width++) {
      for (var height = 3; height < 6; height++) {
        for (var i = 0; i < 10; i++) {
          final puzzle = Puzzle(width, height);
          expect(puzzle.solvable, isTrue);
          expect(puzzle.incorrectTiles, puzzle.tileCount);
          expect(puzzle.fitness, greaterThanOrEqualTo(puzzle.tileCount));
          expect(Puzzle.parse(puzzle.toString()) == puzzle, isTrue);
        }
      }
    }
  });

  test('reset', () {
    var puzzle = Puzzle(4, 4);
    expect(puzzle.incorrectTiles, puzzle.tileCount);
    expect(puzzle.fitness, greaterThanOrEqualTo(puzzle.tileCount));

    do {
      Puzzle? newPuzzle;
      do {
        // click around until one tile is in the right location
        newPuzzle = puzzle.clickValue(_rnd.nextInt(puzzle.tileCount));
      } while (newPuzzle == null);
      puzzle = newPuzzle;
    } while (puzzle.incorrectTiles == puzzle.tileCount);

    expect(puzzle.incorrectTiles, lessThan(puzzle.tileCount));

    puzzle = puzzle.reset();

    expect(puzzle.solvable, isTrue);
    expect(puzzle.incorrectTiles, puzzle.tileCount);
    expect(puzzle.fitness, greaterThanOrEqualTo(puzzle.tileCount));
  });

  test('fitness', () {
    var puzzle = Puzzle.raw(3, [0, 1, 2, 3, 4, 5, 6, 7, 8]);
    expect(puzzle.incorrectTiles, 0);
    expect(puzzle.fitness, 0);
    expect(puzzle.toString(), '''
0 1 2
3 4 5
6 7 8''');

    puzzle = puzzle.clickValue(7)!;
    expect(puzzle.incorrectTiles, 1);
    expect(puzzle.fitness, 1);
    expect(puzzle.toString(), '''
0 1 2
3 4 5
6 8 7''');

    puzzle = puzzle.clickValue(6)!;
    puzzle = puzzle.clickValue(3)!;
    puzzle = puzzle.clickValue(4)!;
    puzzle = puzzle.clickValue(6)!;
    expect(puzzle.toString(), '''
0 1 2
4 6 5
3 8 7''');
    expect(puzzle.incorrectTiles, 4);
    expect(puzzle.fitness, 28);

    final puzzle2 = Puzzle.raw(3, [8, 1, 2, 3, 4, 5, 6, 7, 0]);
    expect(puzzle2.incorrectTiles, 1);
    expect(puzzle2.toString(), '''
8 1 2
3 4 5
6 7 0''');
    expect(puzzle2.fitness, 16);

    final puzzle3 = Puzzle.raw(3, [3, 0, 1, 4, 5, 2, 7, 6, 8]);
    expect(puzzle3.incorrectTiles, 8);
    expect(puzzle3.fitness, 64);
  });

  test('click random', () {
    final puzzle = Puzzle(4, 4);
    final moves = puzzle.clickRandom();
    expect(puzzle, isNot(moves));
  });

  test('clone', () {
    var puzzle = Puzzle(4, 4);
    final clone = puzzle.clone();
    expect(clone, isNot(same(puzzle)));
    expect(clone == puzzle, isTrue);
    expect(clone.incorrectTiles, puzzle.incorrectTiles);

    puzzle = puzzle.clickRandom()!;
    expect(clone, isNot(puzzle));
  });

  test('solvable', () {
    expect(Puzzle.raw(4, _solvable4x4).solvable, isTrue);
    expect(Puzzle.raw(4, _solvable4x4n2).solvable, isTrue);
    expect(Puzzle.raw(4, _unsolvable4x4).solvable, isFalse);
  });
}

// examples from https://www.cs.bham.ac.uk/~mdr/teaching/modules04/java2/TilesSolvability.html
const _solvable4x4 = [11, 0, 9, 1, 6, 10, 3, 13, 4, 15, 8, 14, 7, 12, 5, 2];

const _solvable4x4n2 = [5, 0, 9, 1, 6, 10, 3, 13, 4, 15, 8, 14, 7, 11, 12, 2];

const _unsolvable4x4 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 13, 15];
