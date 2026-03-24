import 'dart:math';
import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';
import 'package:google_fonts/google_fonts.dart';

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

class BlastEffectNode extends Node {
  final Color color;
  final int intensity; // 1 for small, 2 for big, 3 for super
  double _life = 1.0;
  final List<Offset> _dirs;
  final List<double> _speeds;

  BlastEffectNode(this.color, {this.intensity = 1})
    : _dirs = List.generate(16 * intensity, (i) {
        double angle = (i * 2 * pi) / (16 * intensity);
        return Offset(cos(angle), sin(angle));
      }),
      _speeds = List.generate(
        16 * intensity,
        (i) => Random().nextDouble() * 0.5 + 0.5,
      );

  @override
  void update(double dt) {
    _life -= dt * (1.5 / intensity);
    if (_life <= 0) removeFromParent();
  }

  @override
  void paint(Canvas canvas) {
    final paint = Paint()
      ..color = color.withOpacity(_life.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < _dirs.length; i++) {
      double dist = (1.0 - _life) * 250.0 * intensity * _speeds[i];
      canvas.drawCircle(
        _dirs[i] * dist,
        (intensity == 3 ? 12.0 : 8.0) * _life,
        paint,
      );
    }

    // Add a central flash for high intensity
    if (intensity >= 2) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(_life.clamp(0.0, 0.8))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, 40.0 * _life * intensity, flashPaint);
    }
  }
}

class ComboTextNode extends Node {
  final String text;
  final Color color;
  double _life = 1.0;
  final double _scale;

  ComboTextNode(this.text, this.color, {double scale = 1.0}) : _scale = scale;

  @override
  void update(double dt) {
    _life -= dt * 0.8;
    if (_life <= 0) {
      removeFromParent();
    }
  }

  @override
  void paint(Canvas canvas) {
    if (_life <= 0) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.sourGummy(
          color: color.withOpacity(_life.clamp(0.0, 1.0)),
          fontSize: 34 * _scale,
          fontWeight: FontWeight.w900,
        ).copyWith(
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(_life.clamp(0.0, 0.4)),
              blurRadius: 10,
              offset: const Offset(3, 3),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    canvas.save();
    // Float up
    canvas.translate(0, - (1.0 - _life) * 80);
    
    // Bounce-in scale effect
    double currentScale = 1.0;
    if (_life > 0.85) {
      currentScale = 1.0 + (1.0 - (_life - 0.85) / 0.15) * 0.4;
    }

    canvas.scale(currentScale, currentScale);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }
}
