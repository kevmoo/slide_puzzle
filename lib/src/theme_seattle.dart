import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'base_theme.dart';
import 'decoration_image_plus.dart';
import 'shared_theme.dart';

class ThemeSeattle extends SharedTheme {
  ThemeSeattle(AppState proxy) : super('Seattle', proxy);

  @override
  Color get puzzleThemeBackground => const Color.fromARGB(153, 90, 135, 170);

  @override
  Widget get backgroundChild => const Image(
        image: AssetImage('asset/seattle.jpg'),
      );

  @override
  Color get puzzleBackgroundColor => Colors.white70;

  @override
  final puzzleBorder = RoundedRectangleBorder(
      side: const BorderSide(color: Colors.transparent, width: 5),
      borderRadius: BorderRadius.circular(5));

  @override
  Widget tileButton(int i) {
    if (i == puzzle.tileCount && !puzzle.solved) {
      return const Center();
    }

    final decorationImage = DecorationImagePlus(
        puzzleWidth: puzzle.width,
        puzzleHeight: puzzle.height,
        pieceIndex: i,
        fit: BoxFit.cover,
        image: const AssetImage('asset/seattle.jpg'));

    final correctPosition = puzzle.isCorrectPosition(i);
    final content = Ink(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: decorationImage,
      ),
      child: puzzle.solved
          ? const Center()
          : Container(
              decoration: ShapeDecoration(
                shape: const CircleBorder(),
                color: correctPosition ? Colors.black38 : Colors.white54,
              ),
              alignment: Alignment.center,
              child: Text(
                (i + 1).toString(),
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: correctPosition ? Colors.white : Colors.black,
                ),
                textScaleFactor: 1.4,
              ),
            ),
    );

    return RaisedButton(
      highlightElevation: 0,
      child: content,
      padding: const EdgeInsets.symmetric(),
      onPressed: tilePress(i),
      color: Colors.grey,
    );
  }
}
