import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'src/puzzle.dart';
import 'src/puzzle_animator.dart';

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
  static const _textScaleFactor = 1.2;
  final PuzzleAnimator _puzzleAnimator;
  final _animationNotifier = _AnimationNotifier();

  Puzzle get _puzzle => _puzzleAnimator.puzzle;

  Ticker _ticker;
  Duration _lastElapsed;
  Duration _delta;

  _PuzzleHomeState(Puzzle puzzle) : _puzzleAnimator = PuzzleAnimator(puzzle) {
    _puzzleAnimator.puzzle.onEvent.listen(_onPuzzleEvent);
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
      body: MediaQuery(
        data: const MediaQueryData(textScaleFactor: _textScaleFactor),
        child: Padding(
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
                    ))
                  ],
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Flow(
                      delegate:
                          _PuzzleDelegate(_puzzleAnimator, _animationNotifier),
                      children: List<Widget>.generate(
                          _puzzle.length, _widgetForTile)),
                ),
              ),
            ],
          ),
        ),
      ));

  Widget _widgetForTile(int i) {
    if (i == _puzzle.tileCount) {
      return const Center(
          child: Text(
        '🦋',
        style: TextStyle(),
        textScaleFactor: _textScaleFactor * 2.5,
      ));
    }

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
    super.dispose();
  }
}

class _AnimationNotifier extends ChangeNotifier {
  void animate() {
    notifyListeners();
  }
}

class _PuzzleDelegate extends FlowDelegate {
  final PuzzleAnimator _puzzleAnimator;

  Puzzle get _puzzle => _puzzleAnimator.puzzle;

  _PuzzleDelegate(this._puzzleAnimator, Listenable repaint)
      : super(repaint: repaint);

  @override
  Size getSize(BoxConstraints constraints) => const Size(260, 260);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    final minSquareSize = math.min(260 / _puzzle.width, 260 / _puzzle.height);

    return BoxConstraints.tight(Size(minSquareSize, minSquareSize));
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final minSquareSize = math.min(context.size.width / _puzzle.width,
        context.size.height / _puzzle.height);

    final delta = ((context.size -
            Offset(minSquareSize * _puzzle.width,
                minSquareSize * _puzzle.height)) as Size) *
        0.5;

    final tileSize = context.getChildSize(0);
    for (var i = 0; i < _puzzle.length; i++) {
      final tileLocation = _puzzleAnimator.location(i);
      context.paintChild(i,
          transform: Matrix4.translationValues(
              tileLocation.x * tileSize.width + delta.width,
              tileLocation.y * tileSize.height + delta.height,
              i.toDouble()));
    }
  }

  @override
  bool shouldRepaint(covariant _PuzzleDelegate oldDelegate) => true;
}
