import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VinylDisc extends StatefulWidget {
  const VinylDisc({
    super.key,
    required this.isPlaying,
    required this.onScrub,
    required this.onScrubStart,
    required this.onScrubEnd,
    this.coverColor,
    this.rate = 1.0,
  });

  final bool isPlaying;

  /// Fired on every drag frame: rotation delta (radians) and a smoothed
  /// angular velocity (radians/sec) used for seeking
  final void Function(double deltaAngle, double angularVelocity) onScrub;
  final VoidCallback onScrubStart;
  final VoidCallback onScrubEnd;

  final Color? coverColor;
  final double rate;

  @override
  State<VinylDisc> createState() => _VinylDiscState();
}

class _VinylDiscState extends State<VinylDisc>
    with SingleTickerProviderStateMixin {
  late final _rotation = AnimationController.unbounded(vsync: this);

  bool _dragging = false;
  double _lastAngle = 0;
  double _angularVelocity = 0; // rad/s
  DateTime _lastSampleTime = DateTime.now();

  double get _spinVelocity => 1.2 * widget.rate; // rad/s
  // static const double _dragCoefficient = 0.03; // closer to 0 = stops faster
  static const double _easeDecay = 0.015;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _easeTo(_spinVelocity);
  }

  @override
  void didUpdateWidget(covariant VinylDisc old) {
    super.didUpdateWidget(old);
    if (_dragging) return;
    if (widget.isPlaying && !old.isPlaying) {
      _easeTo(_spinVelocity);
    } else if (!widget.isPlaying && old.isPlaying) {
      _easeTo(0.0);
    } else if (widget.isPlaying && widget.rate != old.rate) {
      _easeTo(_spinVelocity);
    } else if (!widget.isPlaying && widget.rate != old.rate) {
      _easeTo(0.0);
    }
  }

  void _easeTo(double targetVelocity, {double? fromVelocity}) {
    final startVelocity =
        fromVelocity ?? (_rotation.isAnimating ? _rotation.velocity : 0.0);
    _rotation.animateWith(
      _EaseToVelocity(
        _rotation.value,
        startVelocity,
        targetVelocity,
        _easeDecay,
      ),
    );
  }

  double _angleAt(Offset point, Offset center) {
    final v = point - center;
    return math.atan2(v.dy, v.dx);
  }

  void _onPanStart(DragStartDetails d, Offset center) {
    _dragging = true;
    _rotation.stop();
    widget.onScrubStart();
    _lastAngle = _angleAt(d.localPosition, center);
    _lastSampleTime = DateTime.now();
    _angularVelocity = 0;
  }

  void _onPanUpdate(DragUpdateDetails d, Offset center) {
    final angle = _angleAt(d.localPosition, center);
    var delta = angle - _lastAngle;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    _rotation.value += delta;

    final now = DateTime.now();
    final dt = now.difference(_lastSampleTime).inMicroseconds / 1e6;
    if (dt > 0) {
      final instant = delta / dt;
      _angularVelocity = _angularVelocity * 0.7 + instant * 0.3;
    }
    _lastAngle = angle;
    _lastSampleTime = now;

    widget.onScrub(delta, _angularVelocity);
  }

  void _onPanEnd(DragEndDetails d) {
    _dragging = false;
    widget.onScrubEnd();
    _easeTo(
      widget.isPlaying ? _spinVelocity : 0.0,
      fromVelocity: _angularVelocity,
    );
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final center = constraints.biggest.center(Offset.zero);
        return ClipOval(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onPanStart: (d) => _onPanStart(d, center),
              onPanUpdate: (d) => _onPanUpdate(d, center),
              onPanEnd: _onPanEnd,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _rotation,
                    builder: (context, child) =>
                        Transform.rotate(angle: _rotation.value, child: child),
                    child: Stack(
                      alignment: .center,
                      children: [
                        Image.asset('lib/assets/images/plate.png'),
                        Stack(
                              alignment: .center,
                              children: [
                                Container(
                                  width: 113,
                                  height: 113,
                                  decoration: BoxDecoration(
                                    color:
                                        widget.coverColor ?? Color(0xFF616161),
                                    shape: .circle,
                                  ),
                                ),
                                Image.asset('lib/assets/images/base.png'),
                              ],
                            )
                            .animate(target: widget.coverColor != null ? 1 : 0)
                            .fade()
                            .scaleXY(begin: 1.1),
                      ],
                    ),
                  ),
                  if (widget.coverColor == null)
                    Image.asset('lib/assets/images/plateGlare.png'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EaseToVelocity extends Simulation {
  _EaseToVelocity(this._x0, this._v0, this._target, this._decay)
    : _log = math.log(_decay);

  final double _x0;
  final double _v0;
  final double _target;
  final double _decay;
  final double _log;

  @override
  double x(double time) =>
      _x0 +
      _target * time +
      (_v0 - _target) * (math.pow(_decay, time) - 1) / _log;

  @override
  double dx(double time) => _target + (_v0 - _target) * math.pow(_decay, time);

  @override
  bool isDone(double time) => _target == 0 && dx(time).abs() < 0.001;
}
