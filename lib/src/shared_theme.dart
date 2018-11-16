import 'base_theme.dart';
import 'flutter.dart';
import 'puzzle_flow_delegate.dart';

abstract class SharedTheme extends PuzzleTheme {
  final _paramScale = 1.5;

  SharedTheme(String name, AppState proxy) : super(name, proxy);

  Widget get backgroundChild => null;

  Color get puzzleThemeBackground;

  ShapeBorder get puzzleBorder;

  Color get puzzleBackgroundColor;

  Duration get puzzleAnimationDuration => kThemeAnimationDuration;

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          SizedBox.expand(
            child: FittedBox(fit: BoxFit.cover, child: backgroundChild),
          ),
          Material(
            animationDuration: puzzleAnimationDuration,
            color: puzzleThemeBackground,
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(35),
                        child: Material(
                          shape: puzzleBorder,
                          color: puzzleBackgroundColor,
                          child: Padding(
                            padding: const EdgeInsets.all(25),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                const ListTile(
                                  title: Text(
                                    'Options',
                                    textScaleFactor: 1.3,
                                  ),
                                ),
                                CheckboxListTile(
                                  title: const Text('Auto play'),
                                  value: autoPlay,
                                  onChanged: setAutoPlay,
                                ),
                                FlatButton(
                                  onPressed: puzzle.reset,
                                  child: const Text('Shuffle tiles'),
                                ),
                                const ListTile(
                                  title: Text(
                                    'Themes',
                                    textScaleFactor: 1.3,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: themeData
                                      .map(
                                        (themeData) => ListTile(
                                              onTap: themeData.select,
                                              title: Text(
                                                themeData.name,
                                                style: TextStyle(
                                                    fontWeight: themeData
                                                            .selected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal),
                                              ),
                                            ),
                                      )
                                      .toList(),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(35),
                        child: FittedBox(
                          alignment: Alignment.topLeft,
                          fit: BoxFit.contain,
                          child: Material(
                            animationDuration: puzzleAnimationDuration,
                            shape: puzzleBorder,
                            color: puzzleBackgroundColor,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Flow(
                                delegate: PuzzleFlowDelegate(
                                    puzzle, animationNotifier),
                                children: List<Widget>.generate(
                                    puzzle.length, _widgetForTile),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      );

  Widget tileButton(int i);

  Widget _widgetForTile(int i) => Padding(
        padding: const EdgeInsets.all(4),
        child: tileButton(i),
      );
}
