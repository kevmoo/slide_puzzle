import 'app_state.dart';
import 'flutter.dart';
import 'shared_theme.dart';

class ThemeSimple extends SharedTheme {
  @override
  String get name => 'Simple';

  ThemeSimple(AppState proxy) : super(proxy);

  @override
  Color get puzzleThemeBackground => Colors.white;

  @override
  Color get puzzleBackgroundColor => Colors.white70;

  @override
  RoundedRectangleBorder get puzzleBorder => const RoundedRectangleBorder(
        side: BorderSide(color: Colors.black26, width: 1),
        borderRadius: BorderRadius.all(
          Radius.circular(4),
        ),
      );

  @override
  Widget tileButton(int i) {
    if (i == puzzle.tileCount) {
      assert(puzzle.solved);
      return const Center(
        child: Icon(
          Icons.thumb_up,
          size: 72,
          color: Colors.black,
        ),
      );
    }

    final correctPosition = puzzle.isCorrectPosition(i);

    final content = createInk(
      Center(
        child: Text(
          (i + 1).toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: correctPosition ? FontWeight.bold : FontWeight.normal,
            fontSize: 49,
          ),
        ),
      ),
    );

    return createButton(
      i,
      content,
      color: const Color.fromARGB(255, 13, 87, 155),
    );
  }
}
