import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'base_theme.dart';
import 'frame_nanny.dart';
import 'puzzle_animator.dart';
import 'theme_alpha.dart';

class _PuzzleThemeImpl implements PuzzleThemeData {
  final PuzzleHomeState _parent;

  @override
  final String name;

  @override
  final Widget Function(BuildContext) build;

  _PuzzleThemeImpl(this._parent, this.name, this.build);

  @override
  void Function() get select {
    if (selected) {
      return null;
    }

    return _select;
  }

  void _select() => _parent._setTheme(this);

  @override
  bool get selected {
    return _parent._currentTheme == this;
  }
}

class PuzzleHomeState extends State
    with BaseTheme, ThemeAlpha, SingleTickerProviderStateMixin {
  @override
  final PuzzleAnimator puzzle;

  @override
  final animationNotifier = AnimationNotifier();

  final _nanny = FrameNanny();

  PuzzleThemeData _currentTheme;

  Duration _tickerTimeSinceLastEvent = Duration.zero;
  Ticker _ticker;
  Duration _lastElapsed;
  StreamSubscription sub;

  @override
  bool autoPlay = false;

  PuzzleHomeState(this.puzzle) {
    sub = puzzle.onEvent.listen(_onPuzzleEvent);
    _currentTheme = themeData.first;
  }

  List<PuzzleThemeData> _themeDataCache;

  @override
  Iterable<PuzzleThemeData> get themeData =>
      _themeDataCache ??= super.themeData.toList(growable: false);

  @override
  PuzzleThemeData createThemeData(String name, build) =>
      _PuzzleThemeImpl(this, name, build);

  void _setTheme(PuzzleThemeData theme) {
    setState(() {
      assert(themeData.contains(theme));
      _currentTheme = theme;
    });
  }

  @override
  void setAutoPlay(bool newValue) {
    if (newValue != autoPlay) {
      setState(() {
        // Only allow enabling autoPlay if the puzzle is not solved
        autoPlay = newValue && !puzzle.solved;
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
  String get tilesLeftText => puzzle.incorrectTiles
      .toString()
      .padLeft(puzzle.tileCount.toString().length);

  /// Returns the number of tiles left, but prefixed with enough whitespace
  /// so the string doesn't change length for all valid values for this puzzle
  @override
  String get clickCountText => puzzle.clickCount
      .toString()
      .padLeft((puzzle.tileCount * puzzle.tileCount).toString().length);

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
    puzzle.update(_nanny.tick(delta));

    if (!puzzle.stable) {
      animationNotifier.animate();
    } else {
      if (!autoPlay) {
        _ticker.stop();
        _lastElapsed = null;
      }
    }

    if (autoPlay &&
        _tickerTimeSinceLastEvent > const Duration(milliseconds: 200)) {
      puzzle.playRandom();

      if (puzzle.solved) {
        setAutoPlay(false);
      }
    }
  }
}
