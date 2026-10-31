// Copyright 2026, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'foley_sound.dart';

@JS('_slidePuzzleFoley')
external _FoleyBridge? get _foleyBridge;

extension type _FoleyBridge._(JSObject _) implements JSObject {
  external void play(String cue, double pitch, double volume, double pan);
  external void setMuted(bool muted);
  external void setTheme(String theme);
}

SoundEffectSink createPlatformSoundSink() => _WebSoundEffectSink();

final class _WebSoundEffectSink implements SoundEffectSink {
  FoleyTheme? _pendingTheme;
  bool? _pendingMuted;

  @override
  bool get isSupported => true;

  _FoleyBridge? _readyBridge() {
    final bridge = _foleyBridge;
    if (bridge == null) {
      return null;
    }
    if (_pendingTheme case final theme?) {
      _pendingTheme = null;
      bridge.setTheme(theme.id);
    }
    if (_pendingMuted case final muted?) {
      _pendingMuted = null;
      bridge.setMuted(muted);
    }
    return bridge;
  }

  @override
  void play(
    FoleyCue cue, {
    double pitch = 0,
    double volume = 1,
    double pan = 0,
  }) {
    _readyBridge()?.play(cue.id, pitch, volume, pan);
  }

  @override
  void setMuted(bool muted) {
    final bridge = _foleyBridge;
    if (bridge == null) {
      _pendingMuted = muted;
      return;
    }
    _pendingMuted = null;
    bridge.setMuted(muted);
  }

  @override
  void setTheme(FoleyTheme theme) {
    final bridge = _foleyBridge;
    if (bridge == null) {
      _pendingTheme = theme;
      return;
    }
    _pendingTheme = null;
    bridge.setTheme(theme.id);
  }
}
