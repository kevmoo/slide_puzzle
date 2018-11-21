import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// Copied from
// https://github.com/flutter/flutter/blob/f5b02e3c05ed1ab31e890add84fb56e35de2d392/packages/flutter/lib/src/material/material.dart#L593-L715
// So I could have animated color!
// TODO(kevmoo): file a feature request for this?
class MaterialInterior extends ImplicitlyAnimatedWidget {
  const MaterialInterior({
    Key key,
    @required this.child,
    @required this.shape,
    this.clipBehavior = Clip.none,
    @required this.elevation,
    @required this.color,
    @required this.shadowColor,
    Curve curve = Curves.linear,
    @required Duration duration,
  })  : assert(child != null),
        assert(shape != null),
        assert(clipBehavior != null),
        assert(elevation != null),
        assert(color != null),
        assert(shadowColor != null),
        super(key: key, curve: curve, duration: duration);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The border of the widget.
  ///
  /// This border will be painted, and in addition the outer path of the border
  /// determines the physical shape.
  final ShapeBorder shape;

  /// {@macro flutter.widgets.Clip}
  final Clip clipBehavior;

  /// The target z-coordinate at which to place this physical object.
  final double elevation;

  /// The target background color.
  final Color color;

  /// The target shadow color.
  final Color shadowColor;

  @override
  _MaterialInteriorState createState() => _MaterialInteriorState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(DiagnosticsProperty<Color>('color', color));
    properties.add(DiagnosticsProperty<Color>('shadowColor', shadowColor));
  }
}

class _MaterialInteriorState extends AnimatedWidgetBaseState<MaterialInterior> {
  ShapeBorderTween _border;
  ColorTween _color;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _border = visitor(_border, widget.shape,
            (value) => ShapeBorderTween(begin: value as ShapeBorder))
        as ShapeBorderTween;
    _color = visitor(
            _color, widget.color, (value) => ColorTween(begin: value as Color))
        as ColorTween;
  }

  @override
  Widget build(BuildContext context) {
    final shape = _border.evaluate(animation);
    return PhysicalShape(
      child: _ShapeBorderPaint(
        child: widget.child,
        shape: shape,
      ),
      clipper: ShapeBorderClipper(
          shape: shape, textDirection: Directionality.of(context)),
      clipBehavior: widget.clipBehavior,
      elevation: widget.elevation,
      color: _color.evaluate(animation),
      shadowColor: widget.shadowColor,
    );
  }
}

class _ShapeBorderPaint extends StatelessWidget {
  const _ShapeBorderPaint({
    @required this.child,
    @required this.shape,
  });

  final Widget child;
  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      child: child,
      foregroundPainter: _ShapeBorderPainter(shape, Directionality.of(context)),
    );
  }
}

class _ShapeBorderPainter extends CustomPainter {
  _ShapeBorderPainter(this.border, this.textDirection);

  final ShapeBorder border;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    border.paint(canvas, Offset.zero & size, textDirection: textDirection);
  }

  @override
  bool shouldRepaint(_ShapeBorderPainter oldDelegate) {
    return oldDelegate.border != border;
  }
}
