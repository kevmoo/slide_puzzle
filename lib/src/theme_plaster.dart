import 'package:flutter/material.dart';

import 'base_theme.dart';
import 'puzzle_flow_delegate.dart';

const _yellowIsh = Color.fromARGB(255, 248, 244, 233);
const _chocolate = Color.fromARGB(255, 66, 66, 68);
const _orangeIsh = Color.fromARGB(255, 224, 107, 83);

mixin ThemePlaster on BaseTheme {
  final _paramScale = 1.5;

  @override
  Iterable<PuzzleThemeData> get themeData => super.themeData.followedBy([
        createThemeData('Plaster', _build),
      ]);

  Widget _build(BuildContext context) => Stack(
        children: <Widget>[
          Material(
            color: _chocolate,
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
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          color: Colors.white70,
                        ),
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
                              onChanged: puzzle.solved ? null : setAutoPlay,
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
                              children: themeData.map((themeData) {
                                return FlatButton(
                                  onPressed: themeData.select,
                                  child: Text(
                                    themeData.name,
                                    style: TextStyle(
                                        fontWeight: themeData.selected
                                            ? FontWeight.bold
                                            : FontWeight.normal),
                                  ),
                                );
                              }).toList(),
                            )
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(35),
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.contain,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color.fromARGB(255, 103, 103, 105),
                                width: 5,
                              ),
                              color: _yellowIsh,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Flow(
                              delegate:
                                  PuzzleFlowDelegate(puzzle, animationNotifier),
                              children: List<Widget>.generate(
                                  puzzle.length, _widgetForTile),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _widgetForTile(int i) {
    final tilePress = puzzle.solved
        ? null
        : () {
            setAutoPlay(false);
            puzzle.clickOrShake(i);
          };

    final correctColumn = i % puzzle.width;
    final correctRow = i ~/ puzzle.width;

    final primary = (correctColumn + correctRow).isEven;

    if (i == puzzle.tileCount) {
      if (puzzle.solved) {
        return const Center(
            child: Icon(
          Icons.thumb_up,
          size: 36,
          color: _chocolate,
        ));
      }
      return const Center();
    }

    final child = RaisedButton(
      elevation: 1,
      child: Text(
        (i + 1).toString(),
        style: TextStyle(
          color: primary ? _yellowIsh : _chocolate,
          fontFamily: 'Plaster',
        ),
        textScaleFactor: 2.5,
      ),
      onPressed: tilePress,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: primary ? _chocolate : _orangeIsh, width: 3),
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.symmetric(),
      color: primary ? _orangeIsh : _yellowIsh,
      disabledColor: primary ? _orangeIsh : _yellowIsh,
    );

    return Padding(
      padding: const EdgeInsets.all(2),
      child: child,
    );
  }
}
