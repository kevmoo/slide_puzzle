import 'package:flutter/material.dart';

import 'src/puzzle.dart';
import 'src/puzzle_home_state.dart';

void main() => runApp(PuzzleApp(4, 4));

class PuzzleApp extends StatelessWidget {
  final int rows, columns;

  String get _title => '${rows * columns - 1} Puzzle';

  PuzzleApp(this.rows, this.columns);

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: _title,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: Text(_title),
          ),
          body: Padding(
            padding: const EdgeInsets.all(6),
            child: _PuzzleHome(rows, columns),
          ),
        ),
      );
}

class _PuzzleHome extends StatefulWidget {
  final int _rows, _columns;

  const _PuzzleHome(this._rows, this._columns, {Key key}) : super(key: key);

  @override
  PuzzleHomeState createState() => PuzzleHomeState(Puzzle(_columns, _rows));
}
