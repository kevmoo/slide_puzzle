import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'base_theme.dart';
import 'frame_nanny.dart';
import 'puzzle_animator.dart';
import 'theme_alpha.dart';

class _ThemePicker implements ThemePicker {
  final PuzzleHomeState _parent;

  @override
  final String name;

  final Widget Function(BuildContext) build;

  _ThemePicker(this._parent, this.name, this.build);

  @override
  void select() => _parent._setTheme(this);

  @override
  bool get selected => _parent._currentTheme == this;
}

class PuzzleHomeState extends State
    with ThemeAlpha, SingleTickerProviderStateMixin {
  @override
  final PuzzleAnimator puzzleAnimator;

  @override
  final animationNotifier = AnimationNotifier();

  final _nanny = FrameNanny();

  _ThemePicker _currentTheme;

  Duration _tickerTimeSinceLastEvent = Duration.zero;
  Ticker _ticker;
  Duration _lastElapsed;
  StreamSubscription sub;

  @override
  bool autoPlay = false;

  @override
  Iterable<_ThemePicker> availableThemes;

  PuzzleHomeState(this.puzzleAnimator) {
    sub = puzzleAnimator.onEvent.listen(_onPuzzleEvent);

    availableThemes = [
      _ThemePicker(this, 'Simple', buildSimple),
      _ThemePicker(this, 'Seattle', buildSeattle)
    ];

    _currentTheme = availableThemes.first;
  }

  void _setTheme(_ThemePicker theme) {
    assert(availableThemes.contains(theme));
    setState(() {
      _currentTheme = theme;
    });
  }

  @override
  void setAutoPlay(bool newValue) {
    if (newValue != autoPlay) {
      setState(() {
        // Only allow enabling autoPlay if the puzzle is not solved
        autoPlay = newValue && !puzzleAnimator.solved;
        if (autoPlay) {
          _ensureTicking();
        }
      });
    }
  }

  @override
  void initState() {
    _ticker ??= createTicker(_onTick);
    _ensureTicking();
    super.initState();
  }

  /// Returns the number of tiles left, but prefixed with enough whitespace
  /// so the string doesn't change length for all valid values for this puzzle
  @override
  String get tilesLeftText => puzzleAnimator.incorrectTiles
      .toString()
      .padLeft(puzzleAnimator.tileCount.toString().length);

  /// Returns the number of tiles left, but prefixed with enough whitespace
  /// so the string doesn't change length for all valid values for this puzzle
  @override
  String get clickCountText => puzzleAnimator.clickCount.toString().padLeft(
      (puzzleAnimator.tileCount * puzzleAnimator.tileCount).toString().length);

  @override
  Widget build(BuildContext context) => _currentTheme.build(context);

  @override
  void dispose() {
    animationNotifier.dispose();
    _ticker?.dispose();
    sub.cancel();
    super.dispose();
  }

  void _onPuzzleEvent(PuzzleEvent e) {
    _tickerTimeSinceLastEvent = Duration.zero;
    _ensureTicking();
    setState(() {
      // noop
    });
  }

  void _ensureTicking() {
    if (!_ticker.isTicking) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (elapsed == Duration.zero) {
      _lastElapsed = elapsed;
    }
    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    if (delta.inMilliseconds <= 0) {
      // `_delta` may be negative or zero if `elapsed` is zero (first tick)
      // or during a restart. Just ignore this case.
      return;
    }

    _tickerTimeSinceLastEvent += delta;
    puzzleAnimator.update(_nanny.tick(delta));

    if (!puzzleAnimator.stable) {
      animationNotifier.animate();
    } else {
      if (!autoPlay) {
        _ticker.stop();
        _lastElapsed = null;
      }
    }

    if (autoPlay &&
        _tickerTimeSinceLastEvent > const Duration(milliseconds: 200)) {
      puzzleAnimator.playRandom();

      if (puzzleAnimator.solved) {
        setAutoPlay(false);
      }
    }
  }
}
