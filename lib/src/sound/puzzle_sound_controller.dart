// Copyright 2026, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../core/puzzle_proxy.dart';
import 'foley_sound.dart';

enum AutomatedMoveKind { none, hint, autoSolve }

final class PuzzleSoundController {
  final SoundEffectSink sink;
  final int boardWidth;

  bool _muted = false;
  FoleyTheme? _currentTheme;

  PuzzleSoundController({required this.sink, required this.boardWidth});

  bool get isSupported => sink.isSupported;

  bool get muted => _muted;

  void setMuted(bool value) {
    if (!isSupported || _muted == value) {
      return;
    }
    _muted = value;
    sink.setMuted(value);
    if (!value) {
      sink.play(FoleyCue.on, volume: 0.7);
    }
  }

  void toggleMuted() => setMuted(!_muted);

  void syncTheme(FoleyTheme theme, {required bool playSwitchCue}) {
    if (!isSupported || _currentTheme == theme) {
      return;
    }
    _currentTheme = theme;
    sink.setTheme(theme);
    if (playSwitchCue) {
      sink.play(FoleyCue.modeSwitch, volume: 0.7);
    }
  }

  void onAutoPlayChanged({required bool enabled}) {
    if (!isSupported) {
      return;
    }
    sink.play(enabled ? FoleyCue.on : FoleyCue.off, volume: 0.75);
  }

  void onSolveStarted() {
    if (!isSupported) {
      return;
    }
    sink.play(FoleyCue.ready, volume: 0.7);
  }

  void onSolveCancelled() {
    if (!isSupported) {
      return;
    }
    sink.play(FoleyCue.off, volume: 0.7);
  }

  void onPuzzleAction(
    PuzzleAction action, {
    AutomatedMoveKind automatedKind = AutomatedMoveKind.none,
    double solveProgress = 0,
  }) {
    if (!isSupported) {
      return;
    }
    switch (action) {
      case TileMovedAction():
        _onTileMoved(
          action,
          automatedKind: automatedKind,
          solveProgress: solveProgress,
        );
      case TileBlockedAction(:final tileX):
        sink.play(FoleyCue.denied, volume: 0.8, pan: _panForColumn(tileX));
      case RandomMoveAction(:final tileX, :final solvedNow):
        if (solvedNow) {
          sink.play(FoleyCue.complete);
        } else {
          sink.play(FoleyCue.tick, volume: 0.45, pan: _panForColumn(tileX));
        }
      case PuzzleResetAction(:final easterEgg):
        sink.play(
          easterEgg ? FoleyCue.sparkle : FoleyCue.swoosh,
          volume: easterEgg ? 0.9 : 0.75,
        );
    }
  }

  void _onTileMoved(
    TileMovedAction action, {
    required AutomatedMoveKind automatedKind,
    required double solveProgress,
  }) {
    if (action.solvedNow) {
      sink.play(FoleyCue.complete);
      return;
    }

    final pan = _panForColumn(action.tileX);
    switch (automatedKind) {
      case AutomatedMoveKind.hint:
        sink.play(FoleyCue.ping, volume: 0.75, pan: pan);
      case AutomatedMoveKind.autoSolve:
        final pitch = -2.0 + (solveProgress.clamp(0.0, 1.0) * 7.0);
        sink.play(FoleyCue.tap, pitch: pitch, volume: 0.65, pan: pan);
      case AutomatedMoveKind.none:
        final multiTileLift = (action.movedCount - 1) * 1.5;
        sink.play(
          action.landedCorrect ? FoleyCue.pop : FoleyCue.tap,
          pitch: multiTileLift,
          volume: 0.85,
          pan: pan,
        );
    }
  }

  double _panForColumn(int column) {
    if (boardWidth <= 1) {
      return 0;
    }
    return (((column / (boardWidth - 1)) * 2) - 1) * 0.45;
  }
}
