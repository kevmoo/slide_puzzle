// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:slide_puzzle/main.dart';
import 'package:slide_puzzle/src/flutter.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    const width = 4, height = 4;
    const tiles = width * height - 1;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const PuzzleApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    // expect(find.text('Clicks: 0'), findsOneWidget);
    expect(find.text('$tiles'), findsNWidgets(2));
    for (var i = 1; i < tiles; i++) {
      await tester.tap(find.widgetWithText(ElevatedButton, '1'));
      expect(find.widgetWithText(ElevatedButton, i.toString()),
          i != 15 ? findsOneWidget : findsNWidgets(2));
    }
  });
}
