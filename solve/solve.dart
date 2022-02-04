import 'dart:math' show min;

import 'package:slide_puzzle/src/core/puzzle.dart';

import 'src/shortest_path.dart';

void main() {
  final watch = Stopwatch()..start();

  final puzzle = Puzzle(4, 4);
  print(puzzle);

  if (!puzzle.solvable) {
    throw UnsupportedError('must be solvable!');
  }

  final minIncorrect = <int, int>{};

  final solvedConfig =
      Puzzle.raw(puzzle.width, List.generate(puzzle.length, (i) => i));

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

    for (var i = 0; i < min(solution.length, 22); i++) {
      minIncorrect[i] = min(minIncorrect[i] ?? puzzle.length,
          solution[solution.length - (i + 1)].incorrectTiles);
    }

    print(minIncorrect);

    //print(solution.join('\n\n'));

    //print('solution #$count - ${solution.length}');
  }
  print('Time to create shortest path: ${watch.elapsed}');

  print(bestSolution.length);
}

Iterable<Puzzle> _allMovable(Puzzle entry) => entry.allMovable();

int _compare(Puzzle a, Puzzle b) => a.fitness.compareTo(b.fitness);

int _minDistanceToSolution(Puzzle p) {
  final incorrect = p.incorrectTiles;

  const maxThing = 6;
  if (incorrect >= maxThing) {
    return maxThing;
  }
  return incorrect;
}

/*
{loopCount: 43701674, elapsed: 0:05:57.969410, graphSize: 31612001, % max g: 100.4, toVisit: 3835481, % max v: 100.7, bestOption: 27, timeToBest: 0:00:03.867554}
solution #29 - 26
{loopCount: 43819935, elapsed: 0:06:20.178470, graphSize: 19513772, % max g: 61.7, toVisit: 3854953, % max v: 100.5, bestOption: 26, timeToBest: 0:05:59.097826}
 */
