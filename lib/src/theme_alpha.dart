import 'package:flutter/material.dart';

import 'base_theme.dart';
import 'decoration_image_plus.dart';
import 'puzzle_flow_delegate.dart';

abstract class ThemeAlpha implements BaseTheme {
  final _paramScale = 1.5;

  Widget buildSimple(BuildContext context) => _build(context, false);

  Widget buildSeattle(BuildContext context) => _build(context, true);

  Widget _build(BuildContext context, bool fancy) => Stack(
        children: <Widget>[
          const SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image(
                image: AssetImage('asset/seattle.jpg'),
              ),
            ),
          ),
          Material(
            color: const Color.fromARGB(153, 90, 135, 170),
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
                              onChanged:
                                  puzzleAnimator.solved ? null : setAutoPlay,
                            ),
                            FlatButton(
                              onPressed: puzzleAnimator.reset,
                              child: const Text('Shuffle tiles'),
                            ),
                            const ListTile(
                              title: Text(
                                'Themes',
                                textScaleFactor: 1.3,
                              ),
                            ),
                            Column(
                              children: availableThemes.map((themeData) {
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
                      child: Container(
                        margin: const EdgeInsets.all(35),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          color: Colors.white70,
                        ),
                        child: FittedBox(
                          alignment: Alignment.center,
                          fit: BoxFit.contain,
                          child: Flow(
                            delegate: PuzzleFlowDelegate(
                                puzzleAnimator, animationNotifier),
                            children: List<Widget>.generate(
                                puzzleAnimator.length,
                                (index) => _widgetForTile(fancy, index)),
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

  Widget _widgetForTile(bool fancy, int i) {
    final tilePress = puzzleAnimator.solved
        ? null
        : () {
            setAutoPlay(false);
            puzzleAnimator.clickOrShake(i);
          };

    final correctPosition = puzzleAnimator.isCorrectPosition(i);

    if (fancy) {
      if (i == puzzleAnimator.tileCount && !puzzleAnimator.solved) {
        return const Center();
      }

      final decorationImage = DecorationImagePlus(
          puzzleWidth: puzzleAnimator.width,
          puzzleHeight: puzzleAnimator.height,
          pieceIndex: i,
          fit: BoxFit.cover,
          image: const AssetImage('asset/seattle.jpg'));

      final content = Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          image: decorationImage,
        ),
        child: puzzleAnimator.solved
            ? Container()
            : Container(
                decoration: ShapeDecoration(
                  shape: const CircleBorder(),
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
      if (i == puzzleAnimator.tileCount) {
        if (puzzleAnimator.solved) {
          return const Center(
              child: Icon(
            Icons.thumb_up,
            size: 36,
            color: Colors.white,
          ));
        }
        return const Center();
      }

      final child = RaisedButton(
        elevation: 1,
        child: Text(
          (i + 1).toString(),
          style: TextStyle(
            fontWeight: correctPosition ? FontWeight.bold : FontWeight.normal,
          ),
          textScaleFactor: 1.4,
        ),
        onPressed: tilePress,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(),
        color: Colors.white,
        disabledColor: Colors.white,
      );

      return Padding(
        padding: const EdgeInsets.all(2),
        child: child,
      );
    }
  }
}
