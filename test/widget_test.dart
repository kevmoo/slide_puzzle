// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:slide_puzzle/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final width = 4, height = 4;
    final tiles = (width * height - 1);

    // Build our app and trigger a frame.
    await tester.pumpWidget(PuzzleApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsNothing);
    expect(find.text('Clicks: 0'), findsOneWidget);
    expect(find.text('Tiles left: $tiles'), findsOneWidget);

    for (var i = 1; i < tiles; i++) {
      expect(find.text(i.toString()), findsOneWidget);
    }

    /*
    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    */
  });
}
