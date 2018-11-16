import 'flutter.dart';

import 'puzzle_animator.dart';

class PuzzleFlowDelegate extends FlowDelegate {
  static const _tileSize = 65.0;
  final PuzzleProxy _puzzleAnimator;

  PuzzleFlowDelegate(this._puzzleAnimator, Listenable repaint)
      : super(repaint: repaint);

  @override
  Size getSize(BoxConstraints constraints) => Size(
      _tileSize * _puzzleAnimator.width, _tileSize * _puzzleAnimator.height);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(const Size(_tileSize, _tileSize));

  @override
  void paintChildren(FlowPaintingContext context) {
    for (var i = 0; i < _puzzleAnimator.length; i++) {
      final tileLocation = _puzzleAnimator.location(i);
      context.paintChild(i,
          transform: Matrix4.translationValues(tileLocation.x * _tileSize,
              tileLocation.y * _tileSize, i.toDouble()));
    }
  }

  @override
  bool shouldRepaint(covariant PuzzleFlowDelegate oldDelegate) =>
      !identical(oldDelegate._puzzleAnimator, _puzzleAnimator);
}
