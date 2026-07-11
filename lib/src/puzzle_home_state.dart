// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:provider/provider.dart';

import 'app_state.dart';
import 'core/puzzle.dart';
import 'core/puzzle_animator.dart';
import 'core/puzzle_proxy.dart';
import 'flutter.dart';
import 'puzzle_controls.dart';
import 'puzzle_flow_delegate.dart';
import 'shared_theme.dart';
import 'solver/puzzle_solver.dart';
import 'themes.dart';
import 'value_tab_controller.dart';

class PuzzleViewModel extends ChangeNotifier
    implements AppState, PuzzleControls {
  @override
  final PuzzleAnimator puzzle;

  @override
  final AnimationNotifier animationNotifier = AnimationNotifier();

  Duration _tickerTimeSinceLastEvent = Duration.zero;
  Ticker? _ticker;
  late Duration _lastElapsed;
  late StreamSubscription<PuzzleEvent> _puzzleEventSubscription;

  bool _autoPlay = false;
  bool _isSolving = false;
  StreamSubscription<SolveResult>? _solverSubscription;
  List<Puzzle>? _solutionPath;
  int _solutionStepIndex = 0;
  Duration _timeSinceLastMove = Duration.zero;
  Duration? _lastSolveTime;
  int? _lastSolveSteps;
  bool _isHintMode = false;
  bool _isAutomatedMove = false;

  PuzzleViewModel(this.puzzle) {
    _puzzleEventSubscription = puzzle.onEvent.listen(_onPuzzleEvent);
  }

  void initTicker(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick);
    _lastElapsed = Duration.zero;
    _ensureTicking();
  }

  @override
  bool get autoPlay => _autoPlay;

  @override
  void Function(bool? newValue)? get setAutoPlayFunction {
    if (puzzle.solved) {
      return null;
    }
    return setAutoPlay;
  }

  @override
  int get clickCount => puzzle.clickCount;

  @override
  int get incorrectTiles => puzzle.incorrectTiles;

  @override
  bool get isSolving => _isSolving;

  @override
  Duration? get lastSolveTime => _lastSolveTime;

  @override
  int? get lastSolveSteps => _lastSolveSteps;

  @override
  void reset() {
    _cancelSolveCore(clearStats: true);
    puzzle.reset();
    notifyListeners();
  }

  void setAutoPlay(bool? newValue) {
    if (newValue != _autoPlay && newValue != null) {
      _autoPlay = newValue && !puzzle.solved;
      if (_autoPlay) {
        if (_isSolving) {
          _cancelSolveCore(clearStats: false);
        }
        _ensureTicking();
      }
      notifyListeners();
    }
  }

  @override
  void hint() {
    if (puzzle.solved || _isSolving) {
      return;
    }
    if (_autoPlay) {
      _autoPlay = false;
    }
    _isSolving = true;
    _isHintMode = true;
    _solutionPath = null;
    _lastSolveTime = null;
    _lastSolveSteps = null;
    _ensureTicking();
    notifyListeners();

    _startSolverStream();
  }

  @override
  void solveOrCancel() {
    if (puzzle.solved) {
      return;
    }
    if (_isSolving) {
      _cancelSolveCore(clearStats: false);
      notifyListeners();
      return;
    }
    if (_autoPlay) {
      _autoPlay = false;
    }
    _isSolving = true;
    _isHintMode = false;
    _solutionPath = null;
    _solutionStepIndex = 0;
    _timeSinceLastMove = Duration.zero;
    _lastSolveTime = null;
    _lastSolveSteps = null;
    _ensureTicking();
    notifyListeners();

    _startSolverStream();
  }

  void _startSolverStream() {
    _solverSubscription?.cancel();
    _solverSubscription =
        PuzzleSolver.solveStream(
          puzzle.currentPuzzle,
          frameBudget: const Duration(milliseconds: 5),
          batchSize: 100,
        ).listen(
          _onSolveProgress,
          onDone: _onSolveDone,
          onError: (Object error, StackTrace stack) {
            _cancelSolveCore(clearStats: false);
            notifyListeners();
          },
        );
  }

  void _onSolveProgress(SolveResult result) {
    _lastSolveTime = result.solverTime;
    _lastSolveSteps = result.steps;
    _solutionPath = result.path;
    if (_isHintMode) {
      if (_solutionPath!.length > 1) {
        _performAutomatedMove(_solutionPath![0], _solutionPath![1]);
      }
      _cancelSolveCore(clearStats: false);
      notifyListeners();
    } else {
      _solverSubscription?.cancel();
      _solverSubscription = null;
      _solutionStepIndex = 0;
      _timeSinceLastMove = const Duration(milliseconds: 250);
      _ensureTicking();
      notifyListeners();
    }
  }

  void _onSolveDone() {
    _solverSubscription = null;
    if (_solutionPath == null || _solutionPath!.isEmpty || puzzle.solved) {
      _isSolving = false;
      _isHintMode = false;
      notifyListeners();
      return;
    }

    if (_isHintMode) {
      if (_solutionPath!.length > 1) {
        _performAutomatedMove(_solutionPath![0], _solutionPath![1]);
      }
      _isSolving = false;
      _isHintMode = false;
      notifyListeners();
    } else {
      _solutionStepIndex = 0;
      _timeSinceLastMove = const Duration(milliseconds: 250);
      _ensureTicking();
      notifyListeners();
    }
  }

  void _performAutomatedMove(Puzzle current, Puzzle next) {
    final open = current.openPosition();
    final tileValue = next.valueAt(open.x, open.y);
    if (tileValue != puzzle.tileCount) {
      _isAutomatedMove = true;
      try {
        puzzle.clickOrShake(tileValue);
      } finally {
        _isAutomatedMove = false;
      }
    }
  }

  void _cancelSolveCore({bool clearStats = false}) {
    _solverSubscription?.cancel();
    _solverSubscription = null;
    _isSolving = false;
    _solutionPath = null;
    _solutionStepIndex = 0;
    _isHintMode = false;
    if (clearStats) {
      _lastSolveTime = null;
      _lastSolveSteps = null;
    }
  }

  @override
  void dispose() {
    _cancelSolveCore();
    animationNotifier.dispose();
    _ticker?.dispose();
    _puzzleEventSubscription.cancel();
    super.dispose();
  }

  void _onPuzzleEvent(PuzzleEvent e) {
    if (e != PuzzleEvent.random) {
      _autoPlay = false;
    }
    if (!_isAutomatedMove &&
        (e == PuzzleEvent.click ||
            e == PuzzleEvent.reset ||
            e == PuzzleEvent.random)) {
      _cancelSolveCore(
        clearStats: e == PuzzleEvent.reset || e == PuzzleEvent.random,
      );
    }
    _tickerTimeSinceLastEvent = Duration.zero;
    _ensureTicking();
    notifyListeners();
  }

  void _ensureTicking() {
    if (_ticker != null && !_ticker!.isTicking) {
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (elapsed == Duration.zero) {
      _lastElapsed = elapsed;
    }
    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    if (delta.inMilliseconds <= 0) {
      return;
    }

    _tickerTimeSinceLastEvent += delta;
    puzzle.update(delta > _maxFrameDuration ? _maxFrameDuration : delta);

    if (!puzzle.stable) {
      animationNotifier.animate();
    } else {
      if (!_autoPlay && !_isSolving) {
        _ticker?.stop();
        _lastElapsed = Duration.zero;
      }
    }

    if (_autoPlay &&
        _tickerTimeSinceLastEvent > const Duration(milliseconds: 200)) {
      puzzle.playRandom();

      if (puzzle.solved) {
        _autoPlay = false;
      }
      notifyListeners();
    }

    if (_isSolving &&
        _solverSubscription == null &&
        !_isHintMode &&
        _solutionPath != null) {
      _timeSinceLastMove += delta;
      if (_timeSinceLastMove >= const Duration(milliseconds: 250)) {
        _timeSinceLastMove = Duration.zero;
        if (_solutionStepIndex < _solutionPath!.length - 1 && !puzzle.solved) {
          final current = _solutionPath![_solutionStepIndex];
          final next = _solutionPath![_solutionStepIndex + 1];
          _solutionStepIndex++;
          _performAutomatedMove(current, next);
          if (puzzle.solved ||
              _solutionStepIndex >= _solutionPath!.length - 1) {
            _isSolving = false;
            _solutionPath = null;
          }
          notifyListeners();
        } else {
          _isSolving = false;
          _solutionPath = null;
          notifyListeners();
        }
      }
    }
  }
}

class PuzzleHomeState extends State with SingleTickerProviderStateMixin {
  final PuzzleAnimator puzzleAnimator;
  late final PuzzleViewModel viewModel;

  PuzzleHomeState(this.puzzleAnimator);

  @override
  void initState() {
    super.initState();
    viewModel = PuzzleViewModel(puzzleAnimator);
    viewModel.initTicker(this);
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ListenableProvider<AppState>.value(value: viewModel),
      ListenableProvider<PuzzleControls>.value(value: viewModel),
    ],
    child: const Material(
      child: Stack(
        children: <Widget>[
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image(image: AssetImage('asset/seattle.jpg')),
            ),
          ),
          LayoutBuilder(builder: _doBuild),
        ],
      ),
    ),
  );
}

class AnimationNotifier extends ChangeNotifier {
  void animate() {
    notifyListeners();
  }
}

const _maxFrameDuration = Duration(milliseconds: 34);

Widget _updateConstraints(
  BuildContext context,
  BoxConstraints constraints,
  Widget Function(bool small) builder,
) {
  const smallWidth = 580;

  final constraintWidth = constraints.hasBoundedWidth
      ? constraints.maxWidth
      : MediaQuery.sizeOf(context).width;

  final constraintHeight = constraints.hasBoundedHeight
      ? constraints.maxHeight
      : MediaQuery.sizeOf(context).height;

  return builder(constraintWidth < smallWidth || constraintHeight < 690);
}

Widget _doBuild(BuildContext context, BoxConstraints constraints) =>
    _updateConstraints(context, constraints, _doBuildCore);

Widget _doBuildCore(bool small) => ValueTabController<SharedTheme>(
  values: themes,
  child: Consumer<SharedTheme>(
    builder: (_, theme, _) => AnimatedContainer(
      duration: puzzleAnimationDuration,
      color: theme.puzzleThemeBackground,
      child: Center(
        child: theme.styledWrapper(
          small,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Consumer<AppState>(
              builder: (context, appState, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black26, width: 1),
                      ),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: TabBar(
                      controller: ValueTabController.of(context),
                      labelPadding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
                      labelColor: theme.puzzleAccentColor,
                      indicatorColor: theme.puzzleAccentColor,
                      indicatorWeight: 1.5,
                      unselectedLabelColor: Colors.black.withValues(alpha: 0.6),
                      tabs: themes
                          .map(
                            (st) => Text(
                              st.name.toUpperCase(),
                              style: const TextStyle(letterSpacing: 0.5),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Flow(
                        delegate: PuzzleFlowDelegate(
                          small ? const Size(90, 90) : const Size(140, 140),
                          appState.puzzle,
                          appState.animationNotifier,
                        ),
                        children: List<Widget>.generate(
                          appState.puzzle.length,
                          (i) =>
                              theme.tileButtonCore(i, appState.puzzle, small),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.black26, width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      left: 10,
                      bottom: 6,
                      top: 2,
                      right: 10,
                    ),
                    child: Consumer<PuzzleControls>(
                      builder: (_, controls, _) =>
                          Row(children: theme.bottomControls(controls)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
