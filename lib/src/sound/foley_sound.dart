// Copyright 2026, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'foley_sound_stub.dart'
    if (dart.library.js_interop) 'foley_sound_web.dart';

enum FoleyCue {
  tick('tick'),
  pop('pop'),
  tap('tap'),
  thock('thock'),
  on('on'),
  off('off'),
  modeSwitch('switch'),
  latch('latch'),
  denied('denied'),
  ping('ping'),
  swoosh('swoosh'),
  ready('ready'),
  complete('complete'),
  sparkle('sparkle');

  final String id;

  const FoleyCue(this.id);
}

enum FoleyTheme {
  standard('default'),
  soft('soft'),
  mechanical('mechanical'),
  glass('glass');

  final String id;

  const FoleyTheme(this.id);
}

abstract interface class SoundEffectSink {
  bool get isSupported;

  void play(
    FoleyCue cue, {
    double pitch = 0,
    double volume = 1,
    double pan = 0,
  });

  void setMuted(bool muted);

  void setTheme(FoleyTheme theme);
}

SoundEffectSink createDefaultSoundSink() => createPlatformSoundSink();
