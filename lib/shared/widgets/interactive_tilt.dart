import 'package:flutter/material.dart';

/// A lightweight perspective tilt interaction for cards and hero panels.
class InteractiveTilt extends StatefulWidget {
  const InteractiveTilt({
    super.key,
    required this.child,
    this.maxTilt = .075,
    this.hoverScale = 1.018,
  });

  final Widget child;
  final double maxTilt;
  final double hoverScale;

  @override
  State<InteractiveTilt> createState() => _InteractiveTiltState();
}

class _InteractiveTiltState extends State<InteractiveTilt> {
  final _tiltKey = GlobalKey();
  double _tiltX = 0;
  double _tiltY = 0;
  bool _hovered = false;
  bool _pressed = false;

  void _pointAt(Offset globalPosition) {
    final box = _tiltKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final point = box.globalToLocal(globalPosition);
    final size = box.size;
    if (size.width <= 0 || size.height <= 0) return;
    setState(() {
      _tiltX = ((.5 - point.dy / size.height) * widget.maxTilt)
          .clamp(-widget.maxTilt, widget.maxTilt)
          .toDouble();
      _tiltY = ((point.dx / size.width - .5) * widget.maxTilt)
          .clamp(-widget.maxTilt, widget.maxTilt)
          .toDouble();
    });
  }

  void _resetTilt() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  Matrix4 _transform(bool reduceMotion) {
    final isActive = _hovered || _pressed;
    final scale = reduceMotion
        ? 1.0
        : _pressed
            ? .99
            : isActive
                ? widget.hoverScale
                : 1.0;
    return Matrix4.identity()
      ..setEntry(3, 2, .0018)
      ..rotateX(reduceMotion || !isActive ? 0 : _tiltX)
      ..rotateY(reduceMotion || !isActive ? 0 : _tiltY)
      ..scaleByDouble(scale, scale, scale, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (event) {
        setState(() => _hovered = true);
        if (!reduceMotion) _pointAt(event.position);
      },
      onHover: reduceMotion ? null : (event) => _pointAt(event.position),
      onExit: (_) {
        setState(() => _hovered = false);
        _resetTilt();
      },
      child: Listener(
        onPointerDown: reduceMotion
            ? null
            : (event) {
                setState(() => _pressed = true);
                _pointAt(event.position);
              },
        onPointerUp: (_) {
          setState(() => _pressed = false);
          if (!_hovered) _resetTilt();
        },
        onPointerCancel: (_) {
          setState(() => _pressed = false);
          if (!_hovered) _resetTilt();
        },
        child: AnimatedContainer(
          key: _tiltKey,
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: _transform(reduceMotion),
          transformAlignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
