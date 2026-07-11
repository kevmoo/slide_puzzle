// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show Point;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slide_puzzle/src/core/puzzle_proxy.dart';
import 'package:slide_puzzle/src/puzzle_flow_delegate.dart';

class _MockPuzzleProxy implements PuzzleProxy {
  @override
  final int width;
  @override
  final int height;
  @override
  final int length;

  _MockPuzzleProxy({required this.width, required this.height})
    : length = width * height;

  @override
  bool isCorrectPosition(int value) => true;

  @override
  Point<double> location(int index) =>
      Point((index % width).toDouble(), (index ~/ width).toDouble());

  @override
  bool get solved => true;

  @override
  int get tileCount => length - 1;

  @override
  void clickOrShake(int tileValue) {}
}

void main() {
  group('PuzzleFlowDelegate', () {
    test('getSize calculates correct board dimensions based on proxy grid', () {
      final proxy = _MockPuzzleProxy(width: 4, height: 4);
      final notifier = ValueNotifier(0);
      final delegate = PuzzleFlowDelegate(
        const Size(100, 100),
        proxy,
        notifier,
      );

      final size = delegate.getSize(const BoxConstraints());
      expect(size, equals(const Size(400, 400)));
    });

    test('getConstraintsForChild enforces tight tile size', () {
      final proxy = _MockPuzzleProxy(width: 4, height: 4);
      final notifier = ValueNotifier(0);
      final delegate = PuzzleFlowDelegate(const Size(90, 90), proxy, notifier);

      final constraints = delegate.getConstraintsForChild(
        0,
        const BoxConstraints(),
      );
      expect(constraints, equals(BoxConstraints.tight(const Size(90, 90))));
    });

    test('shouldRepaint returns true when tile size or proxy changes', () {
      final proxy1 = _MockPuzzleProxy(width: 4, height: 4);
      final proxy2 = _MockPuzzleProxy(width: 4, height: 4);
      final notifier = ValueNotifier(0);

      final delegate1 = PuzzleFlowDelegate(
        const Size(100, 100),
        proxy1,
        notifier,
      );
      final delegate2 = PuzzleFlowDelegate(
        const Size(100, 100),
        proxy1,
        notifier,
      );
      final delegateDifferentSize = PuzzleFlowDelegate(
        const Size(120, 120),
        proxy1,
        notifier,
      );
      final delegateDifferentProxy = PuzzleFlowDelegate(
        const Size(100, 100),
        proxy2,
        notifier,
      );

      expect(delegate2.shouldRepaint(delegate1), isFalse);
      expect(delegateDifferentSize.shouldRepaint(delegate1), isTrue);
      expect(delegateDifferentProxy.shouldRepaint(delegate1), isTrue);
    });
  });
}
