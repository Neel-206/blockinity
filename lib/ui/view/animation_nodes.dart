import 'dart:math';
import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';

/// A background node that creates a dynamic, animated atmosphere
class BackgroundLayerNode extends Node {
  final Size size;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  BackgroundLayerNode(this.size) {
    // Initialize particles
    for (int i = 0; i < 40; i++) {
      _particles.add(
        _Particle(
          pos: Offset(
            _random.nextDouble() * size.width,
            _random.nextDouble() * size.height,
          ),
          velocity: Offset(
            (_random.nextDouble() - 0.5) * 0.2,
            (_random.nextDouble() - 0.5) * 0.2,
          ),
          baseRadius: _random.nextDouble() * 2.0 + 1.0,
          color: const Color(
            0xffCBD5E1,
          ).withOpacity(_random.nextDouble() * 0.4 + 0.1),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    for (var p in _particles) {
      p.pos += p.velocity;

      // Wrap around screen
      if (p.pos.dx < 0) p.pos = Offset(size.width, p.pos.dy);
      if (p.pos.dx > size.width) p.pos = Offset(0, p.pos.dy);
      if (p.pos.dy < 0) p.pos = Offset(p.pos.dx, size.height);
      if (p.pos.dy > size.height) p.pos = Offset(p.pos.dx, 0);

      // Gentle pulsing
      p.orbit += dt * 2;
    }
  }

  @override
  void paint(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in _particles) {
      paint.color = p.color;
      final radius = p.baseRadius + sin(p.orbit) * 0.5;
      canvas.drawCircle(p.pos, radius, paint);
    }
  }
}

class _Particle {
  Offset pos;
  final Offset velocity;
  final double baseRadius;
  final Color color;
  double orbit = 0;

  _Particle({
    required this.pos,
    required this.velocity,
    required this.baseRadius,
    required this.color,
  }) {
    orbit = pos.dx + pos.dy; // Offset start phase
  }
}

// A burst effect node for when blocks are placed or lines cleared
class EffectNode extends Node {
  final Color color;
  double _life = 1.0;
  final List<Offset> _dirs;

  EffectNode(this.color)
    : _dirs = List.generate(8, (i) {
        double angle = i * pi / 4;
        return Offset(cos(angle), sin(angle));
      });

  @override
  void update(double dt) {
    _life -= dt * 2.5;
    if (_life <= 0) removeFromParent();
  }

  @override
  void paint(Canvas canvas) {
    final paint = Paint()
      ..color = color.withOpacity(_life.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    for (var dir in _dirs) {
      double dist = (1.0 - _life) * 100.0;
      canvas.drawCircle(dir * dist, 5.0 * _life, paint);
    }
  }
}
