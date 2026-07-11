import 'dart:math' show Random;
import 'package:slide_puzzle/src/core/puzzle.dart';

import 'src/shortest_path.dart';

void main(List<String> args) {
  int? seed;
  var easy = false;
  for (final arg in args) {
    if (arg.startsWith('--seed=')) {
      seed = int.tryParse(arg.substring('--seed='.length));
    } else if (arg == '--easy') {
      easy = true;
    }
  }

  final watch = Stopwatch()..start();
  final random = seed != null ? Random(seed) : null;
  final puzzle = Puzzle(4, 4, random: random, easy: easy);
  print('Puzzle (seed: $seed, easy: $easy):');
  print(puzzle);

  if (!puzzle.solvable) {
    throw UnsupportedError('must be solvable!');
  }

  final solvedConfig = Puzzle.raw(
    puzzle.width,
    List.generate(puzzle.length, (i) => i),
  );

  var count = 0;
  late List<Puzzle> bestSolution;
  for (var solution in shortestPaths<Puzzle>(
    puzzle,
    solvedConfig,
    _allMovable,
    compare: _compare,
    minDistanceToSolution: _minDistanceToSolution,
  )) {
    count++;
    print('solution #$count - ${solution.length}');
    bestSolution = solution;
  }
  print('Time to create shortest path: ${watch.elapsed}');

  print(bestSolution.length);
}

Iterable<Puzzle> _allMovable(Puzzle entry) => entry.allMovable();

int _compare(Puzzle a, Puzzle b) => a.fitness.compareTo(b.fitness);

int _minDistanceToSolution(Puzzle p) => p.lowerBound;
