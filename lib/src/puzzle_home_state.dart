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

  void _setFancy(bool newValue) {
    if (newValue != _fancy) {
      setState(() {
        _fancy = newValue;
      });
    }
  }

  void _setAutoPlay(bool newValue) {
    if (newValue != _autoPlay) {
      setState(() {
        // Only allow enabling autoPlay if the puzzle is not solved
        _autoPlay = newValue && !_puzzleAnimator.solved;
        if (_autoPlay) {
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
        _setAutoPlay(false);
      }
    }
  }

  /// Returns the number of tiles left, but prefixed with enough whitespace
  /// so the string doesn't change length for all valid values for this puzzle
  String get _tilesLeftText => _puzzle.incorrectTiles
      .toString()
      .padLeft(_puzzle.tileCount.toString().length);

  /// Returns the number of tiles left, but prefixed with enough whitespace
  /// so the string doesn't change length for all valid values for this puzzle
  String get _clickCount => _puzzle.clickCount
      .toString()
      .padLeft((_puzzle.tileCount * _puzzle.tileCount).toString().length);

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          const SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image(
                image: AssetImage('asset/seattle.jpg'),
                colorBlendMode: BlendMode.lighten,
                color: Colors.white70,
              ),
            ),
          ),
          Scaffold(
            appBar: AppBar(
              title: const Text('Slide Puzzle'),
            ),
            drawer: Drawer(
                child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  child: Text(
                    'Options',
                    style: Theme.of(context).primaryTextTheme.display1,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                CheckboxListTile(
                  title: const Text('Auto play'),
                  value: _autoPlay,
                  onChanged: _puzzleAnimator.solved ? null : _setAutoPlay,
                ),
                CheckboxListTile(
                  title: const Text('Seattle'),
                  value: _fancy,
                  onChanged: _setFancy,
                ),
              ],
            )),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Clicks: $_clickCount',
                      textScaleFactor: 2.5,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: _puzzle.reset,
                    child: const Icon(Icons.refresh),
                    //label: const Text('New game'),
                  ),
                  Expanded(
                    child: Text(
                      'Tiles left: $_tilesLeftText',
                      textScaleFactor: 2.5,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            body: SizedBox.expand(
              child: FittedBox(
                alignment: Alignment.center,
                fit: BoxFit.contain,
                child: Container(
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 3),
                    color: Theme.of(context).primaryColorDark.withAlpha(100),
                  ),
                  child: Flow(
                    delegate:
                        PuzzleFlowDelegate(_puzzleAnimator, _animationNotifier),
                    children:
                        List<Widget>.generate(_puzzle.length, _widgetForTile),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _widgetForTile(int i) {
    final tilePress = _puzzleAnimator.solved
        ? null
        : () {
            _setAutoPlay(false);
            _puzzleAnimator.clickOrShake(i);
          };

    final correctPosition = _puzzle.isCorrectPosition(i);

    if (_fancy) {
      if (i == _puzzle.tileCount && !_puzzleAnimator.solved) {
        return const Center();
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

      return OutlineButton(
        highlightedBorderColor: Colors.transparent,
        highlightElevation: 0,
        child: content,
        padding: const EdgeInsets.symmetric(),
        onPressed: tilePress,
        color: Colors.grey,
      );
    } else {
      if (i == _puzzle.tileCount) {
        if (_puzzleAnimator.solved) {
          return const Center(
              child: Icon(
            Icons.thumb_up,
            size: 36,
            color: Colors.white,
          ));
        }
        return const Center();
      }

      final child = FlatButton(
        child: Text(
          (i + 1).toString(),
          style: TextStyle(
            fontWeight: correctPosition ? FontWeight.bold : FontWeight.normal,
          ),
          textScaleFactor: 2.5,
        ),
        onPressed: tilePress,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(),
        color: Colors.white,
        disabledColor: Colors.white,
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
