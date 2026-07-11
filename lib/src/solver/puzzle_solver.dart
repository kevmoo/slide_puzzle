// Copyright 2026, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' show max;

import '../core/puzzle.dart';
import 'shortest_path.dart';

class SolveResult {
  final List<Puzzle> path;
  final Duration solverTime;

  int get steps => max(0, path.length - 1);

  const SolveResult({required this.path, required this.solverTime});
}

class PuzzleSolver {
  /// Returns the target solved configuration for a given puzzle width & length.
  static Puzzle solvedConfigFor(Puzzle puzzle) =>
      Puzzle.raw(puzzle.width, List.generate(puzzle.length, (i) => i));

  /// Helper functions encapsulated cleanly from tool/solve.dart
  static Iterable<Puzzle> allMovable(Puzzle entry) => entry.allMovable();

  static int compare(Puzzle a, Puzzle b) => a.fitness.compareTo(b.fitness);

  static int minDistanceToSolution(Puzzle p) => p.lowerBound;

  /// Runs the solver synchronously and returns all intermediate shortest paths.
  static Iterable<List<Puzzle>> solve(Puzzle puzzle) => shortestPaths<Puzzle>(
    puzzle,
    solvedConfigFor(puzzle),
    allMovable,
    compare: compare,
    minDistanceToSolution: minDistanceToSolution,
  );

  /// Runs the solver asynchronously across frames, yielding [SolveResult] with
  /// accurate solver-only execution time excluding UI yield delays.
  static Stream<SolveResult> solveStream(
    Puzzle puzzle, {
    Duration frameBudget = const Duration(milliseconds: 5),
    int batchSize = 100,
  }) async* {
    final solverWatch = Stopwatch()..start();
    await for (final path in shortestPathsStream<Puzzle>(
      puzzle,
      solvedConfigFor(puzzle),
      allMovable,
      compare: compare,
      minDistanceToSolution: minDistanceToSolution,
      frameBudget: frameBudget,
      batchSize: batchSize,
      solverWatch: solverWatch,
    )) {
      yield SolveResult(
        path: [puzzle, ...path],
        solverTime: solverWatch.elapsed,
      );
    }
  }
}
