import 'base_theme.dart';
import 'flutter.dart';
import 'shared_theme.dart';

class ThemeSimple extends SharedTheme {
  @override
  String get name => 'Simple';

  ThemeSimple(AppState proxy) : super(proxy);

  @override
  Color get puzzleThemeBackground => const Color.fromARGB(255, 54, 81, 102);

  @override
  Color get puzzleBackgroundColor => Colors.white70;

  @override
  RoundedRectangleBorder get puzzleBorder => const RoundedRectangleBorder(
        side: BorderSide(color: Colors.black87, width: 2),
        borderRadius: BorderRadius.all(
          Radius.circular(5),
        ),
      );

  @override
  Widget tileButton(int i) {
    if (i == puzzle.tileCount) {
      if (puzzle.solved) {
        return const Center(
          child: Icon(
            Icons.thumb_up,
            size: 72,
            color: Colors.white,
          ),
        );
      }
      return const Center();
    }

    final correctPosition = puzzle.isCorrectPosition(i);

    final content = createInk(
      Center(
        child: puzzle.solved
            ? null
            : Text(
                (i + 1).toString(),
                style: TextStyle(
                    fontWeight:
                        correctPosition ? FontWeight.bold : FontWeight.normal),
                textScaleFactor: 3.0,
              ),
      ),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xffcccccc)],
        tileMode: TileMode.clamp, // repeats the gradient over the canvas
      ),
    );

    return createButton(i, content);
  }
}
