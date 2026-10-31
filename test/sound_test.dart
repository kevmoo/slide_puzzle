// Copyright 2026, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:slide_puzzle/main.dart';
import 'package:slide_puzzle/src/app_state.dart';
import 'package:slide_puzzle/src/core/puzzle_proxy.dart';
import 'package:slide_puzzle/src/sound/foley_sound.dart';
import 'package:slide_puzzle/src/sound/puzzle_sound_controller.dart';

final class RecordedCue {
  final FoleyCue cue;
  final double pitch;
  final double volume;
  final double pan;

  const RecordedCue({
    required this.cue,
    required this.pitch,
    required this.volume,
    required this.pan,
  });
}

final class RecordingSoundSink implements SoundEffectSink {
  @override
  final bool isSupported;

  final List<RecordedCue> played = [];
  final List<bool> muteCalls = [];
  final List<FoleyTheme> themeCalls = [];

  RecordingSoundSink({this.isSupported = true});

  @override
  void play(
    FoleyCue cue, {
    double pitch = 0,
    double volume = 1,
    double pan = 0,
  }) {
    played.add(RecordedCue(cue: cue, pitch: pitch, volume: volume, pan: pan));
  }

  @override
  void setMuted(bool muted) {
    muteCalls.add(muted);
  }

  @override
  void setTheme(FoleyTheme theme) {
    themeCalls.add(theme);
  }
}

void main() {
  group('PuzzleSoundController', () {
    test('reports web-only platform support on default sink', () {
      expect(createDefaultSoundSink().isSupported, kIsWeb);
    });

    test(
      'pans left and right columns symmetrically and lifts multi-tile slides',
      () {
        final sink = RecordingSoundSink();
        final controller = PuzzleSoundController(sink: sink, boardWidth: 4);

        controller.onPuzzleAction(
          const TileMovedAction(
            tileValue: 0,
            movedCount: 1,
            tileX: 0,
            landedCorrect: false,
            solvedNow: false,
          ),
        );
        controller.onPuzzleAction(
          const TileMovedAction(
            tileValue: 3,
            movedCount: 3,
            tileX: 3,
            landedCorrect: true,
            solvedNow: false,
          ),
        );

        expect(sink.played, hasLength(2));
        expect(sink.played[0].cue, FoleyCue.tap);
        expect(sink.played[0].pan, closeTo(-0.45, 0.001));
        expect(sink.played[0].pitch, 0);
        expect(sink.played[0].volume, closeTo(0.85, 0.001));

        expect(sink.played[1].cue, FoleyCue.pop);
        expect(sink.played[1].pan, closeTo(0.45, 0.001));
        expect(sink.played[1].pitch, closeTo(3.0, 0.001));
      },
    );

    test(
      'climbs in pitch across auto-solve steps and plays complete on solve',
      () {
        final sink = RecordingSoundSink();
        final controller = PuzzleSoundController(sink: sink, boardWidth: 4);

        controller.onPuzzleAction(
          const TileMovedAction(
            tileValue: 4,
            movedCount: 1,
            tileX: 1,
            landedCorrect: false,
            solvedNow: false,
          ),
          automatedKind: AutomatedMoveKind.autoSolve,
          solveProgress: 0.0,
        );
        controller.onPuzzleAction(
          const TileMovedAction(
            tileValue: 5,
            movedCount: 1,
            tileX: 2,
            landedCorrect: true,
            solvedNow: false,
          ),
          automatedKind: AutomatedMoveKind.autoSolve,
          solveProgress: 0.8,
        );
        controller.onPuzzleAction(
          const TileMovedAction(
            tileValue: 14,
            movedCount: 1,
            tileX: 2,
            landedCorrect: true,
            solvedNow: true,
          ),
          automatedKind: AutomatedMoveKind.autoSolve,
          solveProgress: 1.0,
        );

        expect(sink.played, hasLength(3));
        expect(sink.played[0].cue, FoleyCue.tap);
        expect(sink.played[1].cue, FoleyCue.tap);
        expect(sink.played[1].pitch, greaterThan(sink.played[0].pitch));
        expect(sink.played[2].cue, FoleyCue.complete);
      },
    );
  });

  group('PuzzleApp Foley UX Integration', () {
    testWidgets('stays silent on startup, syncs tab themes, and toggles mute', (
      WidgetTester tester,
    ) async {
      final sink = RecordingSoundSink();
      await tester.pumpWidget(PuzzleApp(soundSink: sink));
      await tester.pumpAndSettle();

      // Startup syncs the initial sonic theme without autoplaying any cue.
      expect(sink.themeCalls, [FoleyTheme.standard]);
      expect(sink.played, isEmpty);

      // Switching tabs updates the Foley theme once per tab and plays switch.
      await tester.tap(find.text('SEATTLE'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(sink.themeCalls.last, FoleyTheme.glass);
      expect(sink.played.map((c) => c.cue), [FoleyCue.modeSwitch]);

      await tester.tap(find.text('PLASTER'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(sink.themeCalls.last, FoleyTheme.mechanical);
      expect(sink.played.map((c) => c.cue), [
        FoleyCue.modeSwitch,
        FoleyCue.modeSwitch,
      ]);

      // Mute button toggles icon and calls setMuted; unmuting plays on.
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      await tester.tap(find.byIcon(Icons.volume_up), warnIfMissed: false);
      await tester.pump();
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      expect(sink.muteCalls, [true]);

      await tester.tap(find.byIcon(Icons.volume_off), warnIfMissed: false);
      await tester.pump();
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(sink.muteCalls, [true, false]);
      expect(sink.played.last.cue, FoleyCue.on);
    });

    testWidgets('emits denied, sparkle, and complete across Easter egg solve', (
      WidgetTester tester,
    ) async {
      final sink = RecordingSoundSink();
      await tester.pumpWidget(PuzzleApp(soundSink: sink));
      await tester.pumpAndSettle();

      final appState = Provider.of<AppState>(
        tester.element(find.byType(TabBar)),
        listen: false,
      );
      final puzzle = appState.puzzle;
      final openLoc = puzzle.location(puzzle.tileCount);

      final unmovable = <int>[];
      for (var i = 0; i < puzzle.tileCount; i++) {
        final loc = puzzle.location(i);
        if (loc.x != openLoc.x && loc.y != openLoc.y) {
          unmovable.add(i);
        }
      }

      final sequence = [
        unmovable[0],
        unmovable[1],
        unmovable[0],
        unmovable[1],
        unmovable[0],
      ];
      for (final idx in sequence) {
        await tester.tap(find.text('${idx + 1}').first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      // 4 blocked taps -> denied x4; 5th triggers Easter egg reset -> sparkle.
      expect(sink.played.map((c) => c.cue).toList(), [
        FoleyCue.denied,
        FoleyCue.denied,
        FoleyCue.denied,
        FoleyCue.denied,
        FoleyCue.sparkle,
      ]);

      // Final winning move plays complete.
      await tester.tap(find.text('15').first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(sink.played.last.cue, FoleyCue.complete);
    });

    testWidgets(
      'hides mute button and skips sound events when sink is unsupported',
      (WidgetTester tester) async {
        final sink = RecordingSoundSink(isSupported: false);
        await tester.pumpWidget(PuzzleApp(soundSink: sink));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.volume_up), findsNothing);
        expect(find.byIcon(Icons.volume_off), findsNothing);
        expect(sink.themeCalls, isEmpty);

        await tester.tap(find.text('SEATTLE'), warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.refresh), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(sink.themeCalls, isEmpty);
        expect(sink.played, isEmpty);
      },
    );

    testWidgets(
      'renders bottom controls without overflow on 360px mobile width',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(PuzzleApp(soundSink: RecordingSoundSink()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.volume_up), findsOneWidget);
      },
    );
  });
}
