// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart' show HeapPriorityQueue;

import 'linked_value.dart';

Iterable<List<T>> shortestPaths<T>(
  T start,
  T target,
  Iterable<T> Function(T) edges, {
  bool Function(T key1, T key2)? equals,
  int Function(T key)? hashCode,
  int Function(T, T)? compare,
  int Function(T)? minDistanceToSolution,
}) sync* {
  final distances =
      HashMap<T, LinkedValue<T>>(equals: equals, hashCode: hashCode);

  equals ??= _defaultEquals;
  if (equals(start, target)) {
    yield const [];
    return;
  }

  minDistanceToSolution ??= _defaultMinDistanceToSolution;

  distances[start] = LinkedValue.empty();

  final toVisit = HeapPriorityQueue(compare)..add(start);

  List<T>? bestOption;
  Duration? bestOptionTime;

  var loopCount = 0;

  final watch = Stopwatch()..start();
  final second5 = const Duration(seconds: 5);
  var maxDistancesLength = 0;
  var maxToVisitLength = 0;

  void updateMaxStats() {
    if (distances.length > maxDistancesLength) {
      maxDistancesLength = distances.length;
    }

    if (toVisit.length > maxToVisitLength) {
      maxToVisitLength = toVisit.length;
    }
  }

  var cleanupsPerLoop = 0;
  var replacements = 0;
  var loopsPerLog = 0;

  void debugPrint() {
    final map = <String, dynamic>{
      'loopCount': loopCount.toStringAsExponential(3),
      'elapsed': watch.elapsed,
      'graphSize': distances.length.toStringAsExponential(3),
      '% max g': _pct(distances.length, maxDistancesLength),
      'toVisit': toVisit.length.toStringAsExponential(3),
      '% max v': _pct(toVisit.length, maxToVisitLength),
      'loops per log': loopCount - loopsPerLog,
      'cleanups': cleanupsPerLoop,
      'updates': replacements,
    };

    cleanupsPerLoop = 0;
    replacements = 0;
    loopsPerLog = loopCount;

    updateMaxStats();

    if (bestOption != null) {
      map['bestOption'] = bestOption.length;
      map['timeToBest'] = bestOptionTime;
    }

    print(map);
  }

  void doCleanup() {
    print('CLEAN: start');
    debugPrint();
    distances.removeWhere((k, v) => v.length >= bestOption!.length);

    debugPrint();
    print('CLEAN: end\n');
  }

  var printLog = false;
  final timer = Timer(second5, () {
    printLog = true;
  });

  while (toVisit.isNotEmpty) {
    loopCount++;

    if (printLog) {
      printLog = false;
      debugPrint();
    }

    final current = toVisit.removeFirst();
    final currentPath = distances[current];

    if (currentPath == null) {
      continue;
    }
    final currentPathMinDistanceToSolution =
        currentPath.length + minDistanceToSolution(current);

    if (bestOption != null &&
        currentPathMinDistanceToSolution >= bestOption.length) {
      // Skip any existing `toVisit` items that have no chance of being
      // better than bestOption (if it exists)
      distances.remove(current);
      cleanupsPerLoop++;
      continue;
    }

    for (var edge in edges(current)) {
      assert(edge != null, '`edges` cannot return null values.');

      final pathToEdge = distances[edge];
      // We haven't visited this node yet, or the path to this node is shorter
      // than the one we currently know
      if (pathToEdge == null ||
          pathToEdge.length > currentPathMinDistanceToSolution) {
        final newPathToEdge = currentPath.followedBy(edge);

        if (equals(edge, target)) {
          assert(
              bestOption == null || bestOption.length > newPathToEdge.length);
          bestOption = newPathToEdge.toList();
          bestOptionTime = watch.elapsed;

          yield bestOption;

          doCleanup();
          break;
        }

        if (bestOption == null || bestOption.length > newPathToEdge.length) {
          // Only add a node to visit if it might be a better path to the
          // target node

          if (pathToEdge != null) {
            replacements++;
            assert(newPathToEdge.length < pathToEdge.length);
          }

          distances[edge] = newPathToEdge;
          toVisit.add(edge);
        }
      }
    }
  }

  timer.cancel();

  debugPrint();
}

String _pct(int a, int b) => (100 * (a / b)).toStringAsFixed(1).padLeft(5);

bool _defaultEquals(Object? a, Object? b) => a == b;

int _defaultMinDistanceToSolution(a) => 1;
