import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'src/decoration_image_plus.dart';
import 'src/puzzle.dart';
import 'src/puzzle_animator.dart';
import 'src/puzzle_flow_delegate.dart';

void main() => runApp(PuzzleApp(4, 4));

class PuzzleApp extends StatelessWidget {
  final int rows, columns;

  PuzzleApp(this.rows, this.columns);

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '${rows * columns - 1} Puzzle',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: _PuzzleHome(rows, columns),
      );
}

class _PuzzleHome extends StatefulWidget {
  final int _rows, _columns;

  const _PuzzleHome(this._rows, this._columns, {Key key}) : super(key: key);

  @override
  _PuzzleHomeState createState() => _PuzzleHomeState(Puzzle(_columns, _rows));
}

class _PuzzleHomeState extends State<_PuzzleHome>
    with SingleTickerProviderStateMixin {
  final PuzzleAnimator _puzzleAnimator;
  final _animationNotifier = _AnimationNotifier();

  Puzzle get _puzzle => _puzzleAnimator.puzzle;

  Ticker _ticker;
  Duration _lastElapsed;
  Duration _delta;
  StreamSubscription sub;
  bool _fancy = false;

  _PuzzleHomeState(Puzzle puzzle) : _puzzleAnimator = PuzzleAnimator(puzzle) {
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
    if (!_ticker.isTicking) {
      _ticker.start();
    }
    super.initState();
  }

  void _onPuzzleEvent(PuzzleEvent e) {
    if (!_ticker.isTicking) {
      _ticker.start();
    }
    setState(() {
      // noop
    });
  }

  void _onTick(Duration elapsed) {
    if (elapsed == Duration.zero) {
      elapsed = const Duration(milliseconds: 17);
    }
    if (_lastElapsed != null && elapsed > _lastElapsed) {
      _delta = elapsed - _lastElapsed;
    } else {
      _delta = const Duration(milliseconds: 17);
    }
    _lastElapsed = elapsed;

    _puzzleAnimator.update(_delta);

    if (!_puzzleAnimator.stable) {
      _animationNotifier.animate();
    } else {
      _ticker.stop();
      _lastElapsed = null;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('${_puzzle.tileCount} Puzzle'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
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
                      delegate: PuzzleFlowDelegate(
                          _puzzleAnimator, _animationNotifier),
                      children: List<Widget>.generate(
                          _puzzle.length, _widgetForTile)),
                ),
              ),
            ],
          ),
        ),
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

    if (_fancy) {
      return _fancyWidgetForTile(i);
    } else {
      return _simpleWidgetForTile(i);
    }
  }

  Widget _fancyWidgetForTile(int i) {
    final correctPosition = _puzzle.isCorrectPosition(i);
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
          child: Text(
            (i + 1).toString(),
            style: TextStyle(
                fontWeight:
                    correctPosition ? FontWeight.bold : FontWeight.normal,
                shadows: [
                  const Shadow(
                      color: Colors.white,
                      blurRadius: 5,
                      offset: Offset(0.5, 0.5))
                ]),
          ),
        ));

    return FlatButton(
      child: content,
      padding: const EdgeInsets.symmetric(),
      onPressed: () => _puzzleAnimator.clickOrShake(i),
      color: Colors.white,
    );
  }

  Widget _simpleWidgetForTile(int i) {
    final correctPosition = _puzzle.isCorrectPosition(i);
    final child = FlatButton(
      child: Text(
        (i + 1).toString(),
        style: TextStyle(
            fontWeight: correctPosition ? FontWeight.bold : FontWeight.normal),
      ),
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
