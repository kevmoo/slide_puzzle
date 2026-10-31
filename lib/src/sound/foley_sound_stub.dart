// Copyright 2026, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'foley_sound.dart';

SoundEffectSink createPlatformSoundSink() => const _NoopSoundEffectSink();

final class _NoopSoundEffectSink implements SoundEffectSink {
  const _NoopSoundEffectSink();

  @override
  bool get isSupported => false;

  @override
  void play(
    FoleyCue cue, {
    double pitch = 0,
    double volume = 1,
    double pan = 0,
  }) {}

  @override
  void setMuted(bool muted) {}

  @override
  void setTheme(FoleyTheme theme) {}
}
