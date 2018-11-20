import 'core/puzzle_animator.dart';
import 'flutter.dart';

class PuzzleFlowDelegate extends FlowDelegate {
  static const _tileSize = 140.0;
  final PuzzleProxy _puzzleProxy;

  PuzzleFlowDelegate(this._puzzleProxy, Listenable repaint)
      : super(repaint: repaint);

  @override
  Size getSize(BoxConstraints constraints) =>
      Size(_tileSize * _puzzleProxy.width, _tileSize * _puzzleProxy.height);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(const Size(_tileSize, _tileSize));

  @override
  void paintChildren(FlowPaintingContext context) {
    for (var i = 0; i < _puzzleProxy.length; i++) {
      final tileLocation = _puzzleProxy.location(i);
      context.paintChild(i,
          transform: Matrix4.translationValues(tileLocation.x * _tileSize,
              tileLocation.y * _tileSize, i.toDouble()));
    }
  }

  @override
  bool shouldRepaint(covariant PuzzleFlowDelegate oldDelegate) =>
      !identical(oldDelegate._puzzleProxy, _puzzleProxy);
}
