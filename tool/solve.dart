import 'dart:math' show Random;
import 'package:slide_puzzle/src/core/puzzle.dart';
import 'package:slide_puzzle/src/solver/puzzle_solver.dart';

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

  var count = 0;
  late List<Puzzle> bestSolution;
  for (var solution in PuzzleSolver.solve(puzzle)) {
    count++;
    print('solution #$count - ${solution.length}');
    bestSolution = solution;
  }
  print('Time to create shortest path: ${watch.elapsed}');

  print(bestSolution.length);
}
