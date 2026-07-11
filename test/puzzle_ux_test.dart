// Copyright 2026, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:slide_puzzle/main.dart';
import 'package:slide_puzzle/src/app_state.dart';
import 'package:slide_puzzle/src/puzzle_controls.dart';
import 'package:slide_puzzle/src/value_tab_controller.dart';
import 'package:slide_puzzle/src/widgets/decoration_image_plus.dart';

void main() {
  group('Comprehensive 7-Part UX Suite', () {
    testWidgets('1. Initial Layout & Component Verification', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const PuzzleApp());
      await tester.pumpAndSettle();

      // Verify header tabs
      expect(find.text('SIMPLE'), findsOneWidget);
      expect(find.text('SEATTLE'), findsOneWidget);
      expect(find.text('PLASTER'), findsOneWidget);

      // Verify counters
      expect(find.text('0 Moves', findRichText: true), findsOneWidget);
      expect(find.text('15 Tiles left', findRichText: true), findsOneWidget);

      // Verify bottom controls
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      // Verify all 15 tile buttons are rendered
      expect(find.byType(ElevatedButton), findsNWidgets(15));
    });

    testWidgets('2. Theme Switching Across Tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const PuzzleApp());
      await tester.pumpAndSettle();

      // Switch to SEATTLE
      await tester.tap(find.text('SEATTLE'), warnIfMissed: false);
      await tester.pumpAndSettle();
      final seattleController = ValueTabController.of(
        tester.element(find.byType(TabBar)),
      )!;
      expect(seattleController.index, 1);
      final seattleInks = tester.widgetList<Ink>(find.byType(Ink));
      expect(
        seattleInks.any((ink) {
          final box = ink.decoration as BoxDecoration?;
          return box?.image is DecorationImagePlus;
        }),
        isTrue,
      );

      // Switch to PLASTER
      await tester.tap(find.text('PLASTER'), warnIfMissed: false);
      await tester.pumpAndSettle();
      final plasterController = ValueTabController.of(
        tester.element(find.byType(TabBar)),
      )!;
      expect(plasterController.index, 2);
      final plasterInks = tester.widgetList<Ink>(find.byType(Ink));
      expect(
        plasterInks.any((ink) {
          final box = ink.decoration as BoxDecoration?;
          return box?.image is DecorationImagePlus;
        }),
        isFalse,
      );
      expect(find.byType(ElevatedButton), findsNWidgets(15));

      // Switch back to SIMPLE
      await tester.tap(find.text('SIMPLE'), warnIfMissed: false);
      await tester.pumpAndSettle();
      final simpleController = ValueTabController.of(
        tester.element(find.byType(TabBar)),
      )!;
      expect(simpleController.index, 0);
      final simpleInks = tester.widgetList<Ink>(find.byType(Ink));
      expect(
        simpleInks.any((ink) {
          final box = ink.decoration as BoxDecoration?;
          return box?.image is DecorationImagePlus;
        }),
        isFalse,
      );
    });

    testWidgets('3. Tile Interaction & Valid Moves', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const PuzzleApp());
      await tester.pumpAndSettle();

      final appState = Provider.of<AppState>(
        tester.element(find.byType(TabBar)),
        listen: false,
      );
      final puzzle = appState.puzzle;
      final openLoc = puzzle.location(puzzle.tileCount);

      // Find the first valid movable tile (aligned with openLoc)
      var movableTileIndex = -1;
      for (var i = 0; i < puzzle.tileCount; i++) {
        final tileLoc = puzzle.location(i);
        final isRowAligned = tileLoc.x == openLoc.x && tileLoc.y != openLoc.y;
        final isColAligned = tileLoc.y == openLoc.y && tileLoc.x != openLoc.x;
        if (isRowAligned || isColAligned) {
          movableTileIndex = i;
          break;
        }
      }
      expect(movableTileIndex, isNot(-1));

      // Tap the movable tile button (label is movableTileIndex + 1)
      await tester.tap(
        find.text('${movableTileIndex + 1}').first,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Verify move counter incremented
      expect(find.text('1 Moves', findRichText: true), findsOneWidget);
    });

    testWidgets('4. Invalid Move Shake Animation & Physics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const PuzzleApp());
      await tester.pumpAndSettle();

      final appState = Provider.of<AppState>(
        tester.element(find.byType(TabBar)),
        listen: false,
      );
      final puzzle = appState.puzzle;
      final openLoc = puzzle.location(puzzle.tileCount);

      // Find an unmovable tile (neither row nor col aligned with openLoc)
      var unmovableTileIndex = -1;
      for (var i = 0; i < puzzle.tileCount; i++) {
        final tileLoc = puzzle.location(i);
        if (tileLoc.x != openLoc.x && tileLoc.y != openLoc.y) {
          unmovableTileIndex = i;
          break;
        }
      }
      expect(unmovableTileIndex, isNot(-1));

      // Tap unmovable tile
      await tester.tap(
        find.text('${unmovableTileIndex + 1}').first,
        warnIfMissed: false,
      );
      await tester.pump(); // Pump frame to trigger shake physics

      // Move counter should remain 0
      expect(find.text('0 Moves', findRichText: true), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('5. Auto-Play Toggle & Ticker Continuity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const PuzzleApp());
      await tester.pumpAndSettle();

      final controls = Provider.of<PuzzleControls>(
        tester.element(find.byType(TabBar)),
        listen: false,
      );
      expect(controls.autoPlay, isFalse);

      // Toggle Auto-Play ON
      await tester.tap(find.byType(Checkbox), warnIfMissed: false);
      await tester.pump();
      expect(controls.autoPlay, isTrue);

      // Advance ticker so playRandom() fires multiple times
      await tester.pump(const Duration(milliseconds: 600));
      expect(controls.clickCount, greaterThan(0));

      // Toggle Auto-Play OFF
      await tester.tap(find.byType(Checkbox), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(controls.autoPlay, isFalse);
    });

    testWidgets('6. Puzzle Reset / Refresh Mechanics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const PuzzleApp());
      await tester.pumpAndSettle();

      final appState = Provider.of<AppState>(
        tester.element(find.byType(TabBar)),
        listen: false,
      );
      final puzzle = appState.puzzle;
      final openLoc = puzzle.location(puzzle.tileCount);

      // Make a valid move first
      for (var i = 0; i < puzzle.tileCount; i++) {
        final tileLoc = puzzle.location(i);
        if ((tileLoc.x == openLoc.x && tileLoc.y != openLoc.y) ||
            (tileLoc.y == openLoc.y && tileLoc.x != openLoc.x)) {
          await tester.tap(find.text('${i + 1}').first, warnIfMissed: false);
          break;
        }
      }
      await tester.pumpAndSettle();
      expect(find.text('1 Moves', findRichText: true), findsOneWidget);

      // Tap Reset icon
      await tester.tap(find.byIcon(Icons.refresh), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify counter reset back to 0 Moves
      expect(find.text('0 Moves', findRichText: true), findsOneWidget);
    });

    testWidgets('7. End-to-End Solved State Verification (Easter Egg)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const PuzzleApp());
      await tester.pumpAndSettle();

      final controls = Provider.of<PuzzleControls>(
        tester.element(find.byType(TabBar)),
        listen: false,
      );
      final appState = Provider.of<AppState>(
        tester.element(find.byType(TabBar)),
        listen: false,
      );
      final puzzle = appState.puzzle;
      final openLoc = puzzle.location(puzzle.tileCount);

      // Find at least 2 distinct unmovable tiles to alternate tapping
      final unmovableIndices = <int>[];
      for (var i = 0; i < puzzle.tileCount; i++) {
        final tileLoc = puzzle.location(i);
        if (tileLoc.x != openLoc.x && tileLoc.y != openLoc.y) {
          unmovableIndices.add(i);
        }
      }
      expect(unmovableIndices.length, greaterThanOrEqualTo(2));
      final bad1 = unmovableIndices[0];
      final bad2 = unmovableIndices[1];

      // Tap unmovable tiles 5 times in alternating order to trigger easter egg
      final sequence = [bad1, bad2, bad1, bad2, bad1];
      for (final idx in sequence) {
        await tester.tap(find.text('${idx + 1}').first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      // Verify easter egg triggered in the model
      expect(controls.clickCount, 999);
      expect(controls.incorrectTiles, 1);

      // Verify UI text reflects the 999 / 1 count
      expect(find.text('999 Moves', findRichText: true), findsOneWidget);
      expect(find.text('1 Tiles left', findRichText: true), findsOneWidget);

      // Now click the final tile to solve: tile value 14 (label '15') is right
      // next to the open slot (`_puzzle.tileCount - 1`).
      await tester.tap(find.text('15').first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify puzzle model is solved
      expect(puzzle.solved, isTrue);

      // Because AppState is provided via non-listenable Provider.value,
      // mark Consumer<AppState> elements so they pick up solved == true.
      for (final element in tester.allElements) {
        if (element.widget.runtimeType.toString().contains(
          'Consumer<AppState>',
        )) {
          element.markNeedsBuild();
        }
      }
      await tester.pumpAndSettle();

      // Verify solved state icon is rendered
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    });

    testWidgets(
      '8. UI Solver Hint and Solve Controls Verification (Zero-Jank)',
      (WidgetTester tester) async {
        await tester.pumpWidget(const PuzzleApp());
        await tester.pumpAndSettle();

        final controls =
            Provider.of<AppState>(
                  tester.element(find.byIcon(Icons.refresh)),
                  listen: false,
                )
                as PuzzleControls;

        expect(controls.clickCount, 0);

        // Click the Hint button
        await tester.tap(
          find.byIcon(Icons.lightbulb_outline),
          warnIfMissed: false,
        );

        // Pump for 400ms to allow shortestPathsStream to discover the first
        // optimal solution (~200ms in) and yield to _onSolveProgress.
        await tester.pump(const Duration(milliseconds: 400));

        // With instant hint responsiveness, exactly 1 move must have been
        // performed without waiting seconds for toVisit.isEmpty!
        expect(
          controls.clickCount,
          1,
          reason: 'Hint did not perform 1 automated move within 400ms',
        );
        expect(
          controls.isSolving,
          isFalse,
          reason: 'Hint remained stuck in isSolving == true',
        );
      },
    );
  });
}
