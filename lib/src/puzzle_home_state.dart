import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'decoration_image_plus.dart';
import 'puzzle.dart';
import 'puzzle_animator.dart';
import 'puzzle_flow_delegate.dart';

class PuzzleHomeState extends State with SingleTickerProviderStateMixin {
  final PuzzleAnimator _puzzleAnimator;
  final _animationNotifier = _AnimationNotifier();

  Puzzle get _puzzle => _puzzleAnimator.puzzle;

  Ticker _ticker;
  Duration _lastElapsed;
  StreamSubscription sub;
  bool _fancy = false;

  PuzzleHomeState(Puzzle puzzle) : _puzzleAnimator = PuzzleAnimator(puzzle) {
    sub = _puzzleAnimator.puzzle.onEvent.listen(_onPuzzleEvent);
  }

  void _fancySwitch(bool newValue) {
    if (newValue != _fancy) {
      setState(() {
        _fancy = newValue;
      });
    }
  }

  @override
  void initState() {
    _ticker ??= createTicker(_onTick);
    _ensureTicking();
    super.initState();
  }

  void _onPuzzleEvent(PuzzleEvent e) {
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
    var delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    if (delta.inMilliseconds <= 0) {
      // `_delta` may be negative or zero if `elapsed` is zero (first tick)
      // or during a restart. Just ignore this case.
      return;
    }

    _puzzleAnimator.update(delta);

    if (!_puzzleAnimator.stable) {
      _animationNotifier.animate();
    } else {
      _ticker.stop();
      _lastElapsed = null;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Clicks: ${_puzzle.clickCount}',
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Tiles left: ${_puzzle.incorrectTiles}',
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: RaisedButton(
                    onPressed: _puzzle.reset,
                    child: const Text(
                      'New game...',
                    ),
                  ),
                ),
                Expanded(
                  flex: 0,
                  child: Switch.adaptive(
                    value: _fancy,
                    onChanged: _fancySwitch,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Flow(
                  delegate:
                      PuzzleFlowDelegate(_puzzleAnimator, _animationNotifier),
                  children:
                      List<Widget>.generate(_puzzle.length, _widgetForTile)),
            ),
          ),
        ],
      );

  Widget _widgetForTile(int i) {
    if (i == _puzzle.tileCount) {
      return const Center(
          child: Text(
        '🦋',
        style: TextStyle(),
        textScaleFactor: 2.5,
      ));
    }

    final correctPosition = _puzzle.isCorrectPosition(i);

    final text = Text(
      (i + 1).toString(),
      style: TextStyle(
        fontWeight: correctPosition ? FontWeight.bold : FontWeight.normal,
        shadows: [
          const Shadow(
              color: Colors.white, blurRadius: 5, offset: Offset(0.5, 0.5))
        ],
      ),
    );

    if (_fancy) {
      final decorationImage = DecorationImagePlus(
          puzzleWidth: _puzzle.width,
          puzzleHeight: _puzzle.height,
          pieceIndex: i,
          fit: BoxFit.cover,
          image: const AssetImage('asset/seattle.jpg'));

      final content = Ink(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            image: decorationImage,
          ),
          child: Container(
              constraints: const BoxConstraints.expand(),
              alignment: const Alignment(0, 0),
              child: text));

      return FlatButton(
        child: content,
        padding: const EdgeInsets.symmetric(),
        onPressed: () => _puzzleAnimator.clickOrShake(i),
        color: Colors.white,
      );
    } else {
      final child = FlatButton(
        child: text,
        onPressed: () => _puzzleAnimator.clickOrShake(i),
        color: Colors.white,
        shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1),
            borderRadius: BorderRadius.circular(10)),
      );

      return Padding(
        padding: const EdgeInsets.all(3),
        child: child,
      );
    }
  }

  @override
  void dispose() {
    _animationNotifier.dispose();
    _ticker?.dispose();
    sub.cancel();
    super.dispose();
  }
}

class _AnimationNotifier extends ChangeNotifier {
  void animate() {
    notifyListeners();
  }
}
