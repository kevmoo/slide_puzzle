// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show Point, sqrt1_2;

import 'package:slide_puzzle/src/core/body.dart';
import 'package:test/test.dart';

Point<double> _point(double x, double y) => Point<double>(x, y);

final _throwsAssertError = throwsA(const TypeMatcher<AssertionError>());

void main() {
  test('defaults', () {
    final body = Body();

    expect(body.velocity, zeroPoint);
    expect(body.location, zeroPoint);
  });

  test('ctor args must be finite', () {
    for (final badValue in [
      double.nan,
      double.negativeInfinity,
      double.infinity
    ]) {
      expect(() => Body(velocity: Point(0, badValue)), _throwsAssertError);
      expect(() => Body(velocity: Point(badValue, 0)), _throwsAssertError);
      expect(() => Body(location: Point(0, badValue)), _throwsAssertError);
      expect(() => Body(location: Point(badValue, 0)), _throwsAssertError);
      expect(
          () => Body(
              location: Point(badValue, badValue),
              velocity: Point(badValue, badValue)),
          _throwsAssertError);
    }
  });

  test('clone', () {
    final body = Body.raw(1, 2, 3, 4);
    final clone = body.clone();
    expect(body, equals(clone));
    expect(body, isNot(same(clone)));
  });

  group('animate', () {
    test('bad args', () {
      final body = Body();

      expect(() => body.animate(0), _throwsAssertError);
      expect(() => body.animate(-1), _throwsAssertError);

      expect(() => body.animate(1, drag: -1), _throwsAssertError);

      expect(() => body.animate(1, maxVelocity: -1), _throwsAssertError);
      expect(
          () => body.animate(1, maxVelocity: double.nan), _throwsAssertError);
      expect(() => body.animate(1, maxVelocity: double.negativeInfinity),
          _throwsAssertError);
      expect(body.animate(1, maxVelocity: double.infinity), isFalse);

      for (final badValue in [
        double.nan,
        double.negativeInfinity,
        double.infinity
      ]) {
        expect(() => body.animate(badValue), _throwsAssertError);
        expect(() => body.animate(1, drag: badValue), _throwsAssertError);
        expect(() => body.animate(1, force: Point(1, badValue)),
            _throwsAssertError);
        expect(() => body.animate(1, force: Point(badValue, 1)),
            _throwsAssertError);
        expect(() => body.animate(1, force: Point(badValue, badValue)),
            _throwsAssertError);
      }
    });

    group('drag', () {
      test('directios', () {
        final bodies = [
          Body(velocity: _point(0, 1)),
          Body(velocity: _point(1, 0)),
          Body(velocity: _point(0, -1)),
          Body(velocity: _point(-1, 0)),
          Body(velocity: _point(sqrt1_2, sqrt1_2)),
          Body(velocity: _point(sqrt1_2, -sqrt1_2)),
          Body(velocity: _point(-sqrt1_2, sqrt1_2)),
          Body(velocity: _point(-sqrt1_2, -sqrt1_2)),
        ];

        for (final b in bodies) {
          expect(b.location.magnitude, 0);
        }

        for (final b in bodies) {
          b.animate(1);
          expect(b.location.magnitude, 1);
        }

        for (final b in bodies) {
          b.animate(1, drag: 0.5);
          expect(b.location.magnitude, closeTo(1.5, 0.0000001));
        }

        for (final b in bodies) {
          b.animate(1, drag: 1);
          expect(b.location.magnitude, closeTo(1.5, 0.0000001));
        }
      });

      test('integration', () {
        final body = Body();
        expect(body.animate(1), isFalse);
        expect(body, Body());

        expect(body.animate(1, force: _point(1, 0)), isTrue);
        expect(body, Body.raw(1, 0, 1, 0));

        // if we animate again, with no force - velocity remains unchanged,
        // but we've moved!
        expect(body.animate(1), isTrue);
        expect(body, Body.raw(2, 0, 1, 0));

        // if we animate again
        expect(body.animate(1, drag: 0.1), isTrue);
        expect(body, Body.raw(2.9, 0, 0.9, 0));

        // if we animate again, with drag at 0.1, velocity should cut in half!
        expect(body.animate(1, drag: 0.1), isTrue);
        expect(body, Body.raw(3.71, 0, 0.81, 0));

        var lastLocation = body.location, lastVelocity = body.velocity;
        var loopCount = 0;
        while (body.animate(1, drag: 0.5)) {
          expect(++loopCount, lessThan(20),
              reason: 'drag + epsilon should stop things pretty quickly');
          expect(body.location.magnitude, greaterThan(lastLocation.magnitude));
          expect(body.velocity.magnitude, lessThan(lastVelocity.magnitude));
          lastLocation = body.location;
          lastVelocity = body.velocity;
        }
        expect(body.velocity, zeroPoint);
      });
    });

    test('terminalVelocity', () {
      final body = Body();
      expect(body.animate(1), isFalse);
      expect(body, Body());

      for (var i = 0; i < 10; i++) {
        expect(
            body.animate(1, force: _point(1, 1), drag: 0.05, maxVelocity: 10),
            isTrue);
        expect(body.location.x, greaterThan(0));
        expect(body.location.y, greaterThan(0));
        expect(body.velocity.x, greaterThan(0));
        expect(body.velocity.y, greaterThan(0));
        expect(body.velocity.magnitude, lessThanOrEqualTo(10));
      }

      expect(body.velocity.magnitude, 10);
    });

    test('spring', () {
      final body = Body();
      final target = _point(10, 1);

      Point<double> force() => target - body.location;

      var count = 0;
      while (body.animate(0.1,
          force: force(), drag: 0.5, maxVelocity: 2, snapTo: target)) {
        count++;
        expect(body.velocity.magnitude, lessThanOrEqualTo(2.0));
        expect(count, lessThan(350),
            reason: 'The system should settle down at ~341 iterations');
      }

      expect(body.location, target,
          reason: 'should snap to this exact location');
      expect(body.velocity.magnitude, 0,
          reason: 'velociy should "snap" to zero, too');
    });
  });
}
