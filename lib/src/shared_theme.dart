import 'base_theme.dart';
import 'flutter.dart';
import 'puzzle_flow_delegate.dart';
import 'widgets/material_interior_alt.dart';

abstract class SharedTheme extends PuzzleTheme {
  double get _paramScale => 1.5;

  SharedTheme(AppState proxy) : super(proxy);

  Color get puzzleThemeBackground;

  RoundedRectangleBorder get puzzleBorder;

  Color get puzzleBackgroundColor;

  Duration get puzzleAnimationDuration => kThemeAnimationDuration * 3;

  EdgeInsetsGeometry get tilePadding => const EdgeInsets.all(4);

  // Thought about using AnimatedContainer here, but it causes some weird
  // resizing behavior
  Widget _styledWrapper(Widget child) => MaterialInterior(
        duration: puzzleAnimationDuration,
        elevation: 5,
        shadowColor: Colors.black,
        shape: puzzleBorder,
        color: puzzleBackgroundColor,
        child: child,
      );

  TextStyle get _tilesLeftStyle =>
      puzzle.solved ? const TextStyle(fontWeight: FontWeight.bold) : null;

  @override
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
            duration: puzzleAnimationDuration,
            color: puzzleThemeBackground,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints.tightFor(width: 320),
                      child: _styledWrapper(
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(0),
                            children: <Widget>[
                              ListTile(
                                title: Text(
                                  'Moves',
                                  textScaleFactor: _paramScale,
                                ),
                                trailing: Text(
                                  clickCountText,
                                  textScaleFactor: _paramScale,
                                ),
                              ),
                              SlideTransition(
                                position: shuffleOffsetAnimation,
                                child: ListTile(
                                  title: Text(
                                    'Tiles left',
                                    textScaleFactor: _paramScale,
                                    style: _tilesLeftStyle,
                                  ),
                                  trailing: Text(
                                    tilesLeftText,
                                    textScaleFactor: _paramScale,
                                    style: _tilesLeftStyle,
                                  ),
                                ),
                              ),
                              const Divider(),
                              CheckboxListTile(
                                title: const Text('Auto play'),
                                value: autoPlay,
                                onChanged: setAutoPlay,
                              ),
                              SlideTransition(
                                position: shuffleOffsetAnimation,
                                child: ListTile(
                                  onTap: puzzle.reset,
                                  title: const Text('Shuffle tiles'),
                                ),
                              ),
                              const Divider(),
                            ]..addAll(
                                themeData.map(
                                  (themeData) =>
                                      RadioListTile<PuzzleThemeOption>(
                                        title: Text(themeData.name),
                                        onChanged: selectTheme,
                                        value: themeData,
                                        groupValue: currentTheme,
                                      ),
                                ),
                              ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 40,
                  ),
                  _styledWrapper(Container(
                    constraints: const BoxConstraints.tightForFinite(),
                    padding: const EdgeInsets.all(10),
                    child: Flow(
                      delegate: PuzzleFlowDelegate(puzzle, animationNotifier),
                      children: List<Widget>.generate(
                        puzzle.length,
                        tileButton,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          )
        ],
      ));

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
    Color disabledColor,
    RoundedRectangleBorder shape,
  }) =>
      AnimatedContainer(
        duration: puzzleAnimationDuration,
        padding: tilePadding,
        child: RaisedButton(
          // ignored! https://github.com/flutter/flutter/issues/24583
          clipBehavior: Clip.hardEdge,
          animationDuration: puzzleAnimationDuration,
          onPressed: () => tilePress(tileValue),
          shape: shape ?? puzzleBorder,
          padding: const EdgeInsets.symmetric(),
          child: content,
          color: color,
          disabledColor: disabledColor,
        ),
      );
}
