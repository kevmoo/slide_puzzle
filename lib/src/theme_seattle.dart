import 'base_theme.dart';
import 'decoration_image_plus.dart';
import 'flutter.dart';
import 'shared_theme.dart';

class ThemeSeattle extends SharedTheme {
  @override
  String get name => 'Seattle';

  ThemeSeattle(AppState proxy) : super(proxy);

  @override
  Color get puzzleThemeBackground => const Color.fromARGB(153, 90, 135, 170);

  @override
  Color get puzzleBackgroundColor => Colors.white70;

  @override
  RoundedRectangleBorder get puzzleBorder => const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)));

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
    final content = createInk(
      puzzle.solved
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
                textScaleFactor: 2.8,
              ),
            ),
      image: decorationImage,
      padding: const EdgeInsets.all(32),
    );

    return createButton(i, content);
  }
}
