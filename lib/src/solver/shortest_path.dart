// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

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
  final finder = _ShortestPathFinder<T>(
    start: start,
    target: target,
    edges: edges,
    equals: equals,
    hashCode: hashCode,
    minDistanceToSolution: minDistanceToSolution,
  );

  if (finder.isTriviallySolved) {
    yield const [];
    return;
  }

  while (finder.hasNext) {
    final next = finder.step();
    if (next != null) {
      yield next;
    }
  }
}

Stream<List<T>> shortestPathsStream<T>(
  T start,
  T target,
  Iterable<T> Function(T) edges, {
  bool Function(T key1, T key2)? equals,
  int Function(T key)? hashCode,
  int Function(T, T)? compare,
  int Function(T)? minDistanceToSolution,
  Duration frameBudget = const Duration(milliseconds: 5),
  int batchSize = 100,
  Stopwatch? solverWatch,
}) async* {
  final watch = solverWatch ?? (Stopwatch()..start());
  if (!watch.isRunning) {
    watch.start();
  }

  final finder = _ShortestPathFinder<T>(
    start: start,
    target: target,
    edges: edges,
    equals: equals,
    hashCode: hashCode,
    minDistanceToSolution: minDistanceToSolution,
  );

  if (finder.isTriviallySolved) {
    yield const [];
    return;
  }

  var batchCount = 0;
  final sliceWatch = Stopwatch()..start();

  while (finder.hasNext) {
    batchCount++;
    if (batchCount >= batchSize) {
      batchCount = 0;
      if (sliceWatch.elapsed >= frameBudget) {
        watch.stop();
        await Future<void>.delayed(Duration.zero);
        watch.start();
        sliceWatch.reset();
      }
    }

    final next = finder.step();
    if (next != null) {
      yield next;
    }
  }
}

class _ShortestPathFinder<T> {
  final T target;
  final Iterable<T> Function(T) edges;
  final bool Function(T, T) equals;
  final int Function(T) minDistanceToSolution;
  final Map<T, LinkedValue<T>> distances;
  final List<List<T>> nodesByLength;
  late final _BucketQueue<T> toVisit;
  final bool isTriviallySolved;

  List<T>? bestOption;

  _ShortestPathFinder({
    required T start,
    required this.target,
    required this.edges,
    bool Function(T, T)? equals,
    int Function(T)? hashCode,
    int Function(T)? minDistanceToSolution,
  }) : equals = equals ?? _defaultEquals,
       minDistanceToSolution =
           minDistanceToSolution ?? _defaultMinDistanceToSolution,
       distances = (equals == null && hashCode == null)
           ? HashMap<T, LinkedValue<T>>()
           : HashMap<T, LinkedValue<T>>(equals: equals, hashCode: hashCode),
       nodesByLength = <List<T>>[
         [start],
       ],
       isTriviallySolved = (equals ?? _defaultEquals)(start, target) {
    if (!isTriviallySolved) {
      distances[start] = LinkedValue.empty();
      toVisit = _BucketQueue<T>(distances, this.minDistanceToSolution)
        ..add(start);
    }
  }

  bool get hasNext => !isTriviallySolved && toVisit.isNotEmpty;

  List<T>? step() {
    final current = toVisit.removeFirst();
    final currentPath = distances[current];
    if (currentPath == null) {
      return null;
    }

    final currentPathMinDistanceToSolution =
        currentPath.length + minDistanceToSolution(current);

    if (bestOption != null &&
        currentPathMinDistanceToSolution >= bestOption!.length) {
      distances.remove(current);
      return null;
    }

    return _expandEdges(current, currentPath, currentPathMinDistanceToSolution);
  }

  List<T>? _expandEdges(
    T current,
    LinkedValue<T> currentPath,
    int currentPathMinDistanceToSolution,
  ) {
    for (final edge in edges(current)) {
      assert(edge != null, '`edges` cannot return null values.');

      final pathToEdge = distances[edge];
      if (pathToEdge != null &&
          pathToEdge.length <= currentPathMinDistanceToSolution) {
        continue;
      }

      final newPathToEdge = currentPath.followedBy(edge);

      if (equals(edge, target)) {
        assert(bestOption == null || bestOption!.length > newPathToEdge.length);
        bestOption = newPathToEdge.toList();
        _doCleanup();
        return bestOption;
      }

      _recordCandidateNode(edge, pathToEdge, newPathToEdge);
    }
    return null;
  }

  void _recordCandidateNode(
    T edge,
    LinkedValue<T>? pathToEdge,
    LinkedValue<T> newPathToEdge,
  ) {
    if (bestOption != null && bestOption!.length <= newPathToEdge.length) {
      return;
    }

    if (pathToEdge != null) {
      assert(newPathToEdge.length < pathToEdge.length);
    }

    distances[edge] = newPathToEdge;
    final len = newPathToEdge.length;
    while (nodesByLength.length <= len) {
      nodesByLength.add([]);
    }
    nodesByLength[len].add(edge);
    toVisit.add(edge);
  }

  void _doCleanup() {
    final bestLen = bestOption!.length;
    for (var l = bestLen; l < nodesByLength.length; l++) {
      final bucket = nodesByLength[l];
      for (var i = 0; i < bucket.length; i++) {
        final k = bucket[i];
        final v = distances.remove(k);
        if (v != null && v.length < bestLen) {
          distances[k] = v;
        }
      }
    }
    if (nodesByLength.length > bestLen) {
      nodesByLength.length = bestLen;
    }
  }
}

bool _defaultEquals(Object? a, Object? b) => a == b;

int _defaultMinDistanceToSolution(Object? a) => 1;

class _BucketQueue<T> {
  final Map<T, LinkedValue<T>> _distances;
  final int Function(T) _minDistanceToSolution;
  final List<Queue<T>> _buckets = List.generate(256, (_) => Queue<T>());
  int _minBucket = 0;
  int _length = 0;

  _BucketQueue(this._distances, this._minDistanceToSolution);

  int get length => _length;
  bool get isNotEmpty => _length > 0;
  bool get isEmpty => _length == 0;

  void add(T element) {
    final fn = _distances[element]!.length + _minDistanceToSolution(element);
    while (_buckets.length <= fn) {
      _buckets.add(Queue<T>());
    }
    _buckets[fn].add(element);
    if (_length == 0 || fn < _minBucket) {
      _minBucket = fn;
    }
    _length++;
  }

  T removeFirst() {
    while (_minBucket < _buckets.length && _buckets[_minBucket].isEmpty) {
      _minBucket++;
    }
    _length--;
    return _buckets[_minBucket].removeFirst();
  }
}
