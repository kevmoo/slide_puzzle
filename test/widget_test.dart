// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:slide_puzzle/main.dart';
import 'package:slide_puzzle/src/flutter.dart';

void main() {
  testWidgets('PuzzleApp smoke test', (WidgetTester tester) async {
    const width = 4, height = 4;
    const tiles = width * height - 1;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const PuzzleApp());

    // Verify that initial move counter displays '0 Moves'.
    expect(find.text('0 Moves', findRichText: true), findsOneWidget);

    // Verify that all 15 tile buttons are present on the board.
    expect(find.byType(ElevatedButton), findsNWidgets(tiles));

    // Tap the first tile button and verify no exceptions occur after a frame
    // pump.
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    expect(find.byType(ElevatedButton), findsNWidgets(tiles));
  });
}
