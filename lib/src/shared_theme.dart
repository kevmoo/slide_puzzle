import 'app_state.dart';
import 'core/puzzle_animator.dart';
import 'flutter.dart';
import 'puzzle_flow_delegate.dart';
import 'widgets/material_interior_alt.dart';

abstract class SharedTheme {
  SharedTheme(this._appState);

  final AppState _appState;

  PuzzleProxy get puzzle => _appState.puzzle;

  String get name;

  Color get puzzleThemeBackground;

  RoundedRectangleBorder get puzzleBorder;

  Color get puzzleBackgroundColor;

  EdgeInsetsGeometry get tilePadding => const EdgeInsets.all(4);

  Widget build(BuildContext context) => Material(
          child: Stack(
        children: <Widget>[
          const SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image(
                image: AssetImage('asset/seattle.jpg'),
              ),
            ),
          ),
          AnimatedContainer(
            duration: _puzzleAnimationDuration,
            color: puzzleThemeBackground,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: _buildControlsWidget(),
                  ),
                  const SizedBox(
                    width: 40,
                  ),
                  _styledWrapper(Container(
                    constraints: const BoxConstraints.tightForFinite(),
                    padding: const EdgeInsets.all(10),
                    child: Flow(
                      delegate: PuzzleFlowDelegate(
                        _tileSize,
                        puzzle,
                        _appState.animationNotifier,
                      ),
                      children: List<Widget>.generate(
                        puzzle.length,
                        _tileButton,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          )
        ],
      ));

  Duration get _puzzleAnimationDuration => kThemeAnimationDuration * 3;

  // Thought about using AnimatedContainer here, but it causes some weird
  // resizing behavior
  Widget _styledWrapper(Widget child) => MaterialInterior(
        duration: _puzzleAnimationDuration,
        elevation: 5,
        shadowColor: Colors.black,
        shape: puzzleBorder,
        color: puzzleBackgroundColor,
        child: child,
      );

  Size get _tileSize => const Size(140.0, 140.0);

  void Function(bool newValue) get _setAutoPlay {
    if (puzzle.solved) {
      return null;
    }
    return _appState.setAutoPlay;
  }

  void _tilePress(int tileValue) {
    _appState.setAutoPlay(false);
    _appState.puzzle.clickOrShake(tileValue);
  }

  void _selectTheme(SharedTheme thing) {
    _appState.currentTheme = thing;
  }

  ConstrainedBox _buildControlsWidget() {
    const tileTextScale = 1.5;

    ListTile doTile(String title, String trailing) => ListTile(
          title: Text(
            title,
            textScaleFactor: tileTextScale,
          ),
          trailing: Text(
            trailing,
            textScaleFactor: tileTextScale,
          ),
        );

    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 320),
      child: _styledWrapper(
        Padding(
          padding: const EdgeInsets.all(15),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(0),
            children: <Widget>[
              doTile('Moves', puzzle.clickCount.toString()),
              SlideTransition(
                position: _appState.shuffleOffsetAnimation,
                child: doTile('Tiles left', puzzle.incorrectTiles.toString()),
              ),
              const Divider(),
              CheckboxListTile(
                title: const Text('Auto play'),
                value: _appState.autoPlay,
                onChanged: _setAutoPlay,
              ),
              SlideTransition(
                position: _appState.shuffleOffsetAnimation,
                child: ListTile(
                  onTap: puzzle.reset,
                  title: const Text('Shuffle tiles'),
                ),
              ),
              const Divider(),
            ]..addAll(
                _appState.themeData.map(
                  (themeData) => RadioListTile<SharedTheme>(
                        title: Text(themeData.name),
                        onChanged: _selectTheme,
                        value: themeData,
                        groupValue: _appState.currentTheme,
                      ),
                ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _tileButton(int i) {
    if (i == puzzle.tileCount && !puzzle.solved) {
      return const Center();
    }

    return tileButton(i);
  }

  Widget tileButton(int i);

  Ink createInk(
    Widget child, {
    Gradient gradient,
    DecorationImage image,
    EdgeInsetsGeometry padding,
  }) =>
      Ink(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          image: image,
        ),
        child: child,
      );

  Widget createButton(
    int tileValue,
    Widget content, {
    Color color,
    RoundedRectangleBorder shape,
  }) =>
      AnimatedContainer(
        duration: _puzzleAnimationDuration,
        padding: tilePadding,
        child: RaisedButton(
          clipBehavior: Clip.hardEdge,
          animationDuration: _puzzleAnimationDuration,
          onPressed: () => _tilePress(tileValue),
          shape: shape ?? puzzleBorder,
          padding: const EdgeInsets.symmetric(),
          child: content,
          color: color,
        ),
      );
}
