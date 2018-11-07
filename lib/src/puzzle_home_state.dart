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
  bool _autoPlay = false;
  Duration _tickerTimeSinceLastEvent = Duration.zero;

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

  void _autoPlaySwitch(bool newValue) {
    setState(() {
      // Only allow enabling autoPlay if the puzzle is not solved
      _autoPlay = newValue && !_puzzleAnimator.solved;
      if (_autoPlay) {
        _ensureTicking();
      }
    });
  }

  @override
  void initState() {
    _ticker ??= createTicker(_onTick);
    _ensureTicking();
    super.initState();
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
    _puzzleAnimator.update(delta);

    if (!_puzzleAnimator.stable) {
      _animationNotifier.animate();
    } else {
      if (!_autoPlay) {
        _ticker.stop();
        _lastElapsed = null;
      }
    }

    if (_autoPlay &&
        _tickerTimeSinceLastEvent > const Duration(milliseconds: 200)) {
      _puzzleAnimator.playRandom();

      if (_puzzleAnimator.solved) {
        _autoPlaySwitch(false);
      }
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
                  child: Switch(
                    value: _fancy,
                    onChanged: _fancySwitch,
                  ),
                ),
                Expanded(
                  flex: 0,
                  child: Switch(
                    value: _autoPlay,
                    onChanged: _puzzleAnimator.solved ? null : _autoPlaySwitch,
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
    final tilePress =
        _puzzleAnimator.solved ? null : () => _puzzleAnimator.clickOrShake(i);

    final correctPosition = _puzzle.isCorrectPosition(i);

    if (_fancy) {
      if (i == _puzzle.tileCount && !_puzzleAnimator.solved) {
        return const Center(
            child: Text(
          '🦋',
          textScaleFactor: 2.5,
        ));
      }

      final decorationImage = DecorationImagePlus(
          puzzleWidth: _puzzle.width,
          puzzleHeight: _puzzle.height,
          pieceIndex: i,
          fit: BoxFit.cover,
          image: const AssetImage('asset/seattle.jpg'));

      final content = Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          image: decorationImage,
        ),
        child: _puzzleAnimator.solved
            ? Container()
            : Container(
                decoration: ShapeDecoration(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  color: correctPosition ? Colors.black38 : Colors.white54,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(1),
                child: Text(
                  (i + 1).toString(),
                  style: TextStyle(
                    color: correctPosition ? Colors.white : Colors.black,
                  ),
                ),
              ),
      );

      return FlatButton(
        child: content,
        padding: const EdgeInsets.symmetric(),
        //shape: const Border(),
        onPressed: tilePress,
        color: Colors.grey,
      );
    } else {
      if (i == _puzzle.tileCount) {
        return Center(
            child: Text(
          _puzzleAnimator.solved ? '👍' : '🦋',
          textScaleFactor: 2.5,
        ));
      }

      final child = FlatButton(
        child: Text(
          (i + 1).toString(),
          style: TextStyle(
            fontWeight: correctPosition ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onPressed: tilePress,
        shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1),
            borderRadius: BorderRadius.circular(10)),
        color: Colors.white,
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
