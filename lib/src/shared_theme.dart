import 'base_theme.dart';
import 'flutter.dart';
import 'puzzle_flow_delegate.dart';
import 'widgets/material_interior_alt.dart';

abstract class SharedTheme extends PuzzleTheme {
  final _paramScale = 1.5;

  SharedTheme(AppState proxy) : super(proxy);

  final _backgroundChild = const Image(
    image: AssetImage('asset/seattle.jpg'),
  );

  Color get puzzleThemeBackground;

  RoundedRectangleBorder get puzzleBorder;

  Color get puzzleBackgroundColor;

  Duration get puzzleAnimationDuration => kThemeAnimationDuration * 5;

  Widget _styledWrapper(Widget child) => MaterialInterior(
        duration: puzzleAnimationDuration,
        elevation: 5,
        shadowColor: Colors.black,
        shape: puzzleBorder,
        color: puzzleBackgroundColor,
        child: child,
      );

  @override
  Widget build(BuildContext context) => Material(
          child: Stack(
        children: <Widget>[
          SizedBox.expand(
            child: FittedBox(fit: BoxFit.cover, child: _backgroundChild),
          ),
          AnimatedPhysicalModel(
            duration: puzzleAnimationDuration,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: BoxShape.rectangle,
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
                              ListTile(
                                title: Text(
                                  'Tiles left',
                                  textScaleFactor: _paramScale,
                                ),
                                trailing: Text(
                                  tilesLeftText,
                                  textScaleFactor: _paramScale,
                                ),
                              ),
                              const Divider(),
                              CheckboxListTile(
                                title: const Text('Auto play'),
                                value: autoPlay,
                                onChanged: setAutoPlay,
                              ),
                              ListTile(
                                onTap: puzzle.reset,
                                title: const Text('Shuffle tiles'),
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
                        _widgetForTile,
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
          borderRadius: puzzleBorder.borderRadius,
          border: Border.all(
            width: puzzleBorder.side.width,
            color: puzzleBorder.side.color,
          ),
        ),
        child: child,
      );

  RaisedButton createButton(
    int tileValue,
    Widget content, {
    Color color,
    Color disabledColor,
    RoundedRectangleBorder shape,
  }) =>
      RaisedButton(
        // ignored! https://github.com/flutter/flutter/issues/24583
        clipBehavior: Clip.hardEdge,
        animationDuration: puzzleAnimationDuration,
        onPressed: tilePress(tileValue),
        shape: shape ?? puzzleBorder,
        padding: const EdgeInsets.symmetric(),
        child: content,
        color: color,
        disabledColor: disabledColor,
      );

  Widget _widgetForTile(int i) => Padding(
        padding: const EdgeInsets.all(4),
        child: tileButton(i),
      );
}
