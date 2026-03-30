import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spritewidget/spritewidget.dart';

class LevelCompleteNode extends NodeWithSize {
  final VoidCallback onComplete;
  final bool isWin;
  double _life = 0;
  bool _finished = false;

  LevelCompleteNode({
    required Size size,
    required this.onComplete,
    this.isWin = true,
  }) : super(size) {
    _initParticles();
  }

  void _initParticles() {
    // Add background dimming
    final dimNode = _DimNode(size);
    addChild(dimNode);

    // Add main text
    final textNode = _TransitionTextNode(
      isWin ? "LEVEL COMPLETE!" : "GAME OVER",
      isWin ? const Color(0xff22C55E) : const Color(0xffEF4444),
    );
    textNode.position = Offset(size.width / 2, size.height / 2);
    addChild(textNode);

    if (isWin) {
      // Add confetti
      for (int i = 0; i < 60; i++) {
        final confetti = _ConfettiParticle(size);
        addChild(confetti);
      }
    }
  }

  @override
  void update(double dt) {
    _life += dt;
    if (_life > 3.0 && !_finished) {
      _finished = true;
      onComplete();
    }
  }
}

class WorldUnlockNode extends NodeWithSize {
  final String worldTitle;
  final VoidCallback onComplete;
  double _life = 0;
  bool _finished = false;

  WorldUnlockNode({
    required Size size,
    required this.worldTitle,
    required this.onComplete,
  }) : super(size) {
    _init();
  }

  void _init() {
    addChild(_DimNode(size));

    // Radial glow
    final glow = _RadialGlowNode(size);
    addChild(glow);

    final titleNode = _TransitionTextNode(
      "WORLD CLEAR!",
      const Color(0xffF59E0B),
      fontSize: 54,
    );
    titleNode.position = Offset(size.width / 2, size.height / 2 - 40);
    addChild(titleNode);

    final subtitleNode = _TransitionTextNode(
      worldTitle.toUpperCase(),
      Colors.white,
      fontSize: 28,
      delay: 0.8,
    );
    subtitleNode.position = Offset(size.width / 2, size.height / 2 + 50);
    addChild(subtitleNode);

    // Initial burst
    for (int i = 0; i < 150; i++) {
      final sparkle = _SparkleParticle(size, isInitialBurst: true);
      addChild(sparkle);
    }

    // Continuous sparkles
    motions.run(
      MotionRepeatForever(
        motion: MotionSequence(
          motions: [
            MotionDelay(delay: 0.1),
            MotionCallFunction(callback: () {
              for (int i = 0; i < 5; i++) {
                addChild(_SparkleParticle(size));
              }
            }),
          ],
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    _life += dt;
    if (_life > 4.0 && !_finished) {
      _finished = true;
      onComplete();
    }
  }
}

class _DimNode extends Node {
  final Size size;
  double _opacity = 0;

  _DimNode(this.size);

  @override
  void update(double dt) {
    if (_opacity < 0.7) {
      _opacity += dt * 2;
    }
  }

  @override
  void paint(Canvas canvas) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withOpacity(_opacity.clamp(0.0, 0.7)),
    );
  }
}

class _TransitionTextNode extends Node {
  final String text;
  final Color color;
  final double fontSize;
  final double delay;
  double _life = 0;

  _TransitionTextNode(this.text, this.color, {this.fontSize = 48, this.delay = 0});

  @override
  void update(double dt) {
    _life += dt;
  }

  @override
  void paint(Canvas canvas) {
    if (_life < delay) return;
    
    double t = (_life - delay).clamp(0.0, 1.0);
    // Bounce in
    double scale = 1.0;
    if (t < 0.5) {
      scale = Curves.elasticOut.transform(t / 0.5);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.sourGummy(
          color: color.withOpacity(t),
          fontSize: fontSize * scale,
          fontWeight: FontWeight.w900,
          shadows: [
            const Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(2, 2)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    
    canvas.save();
    canvas.translate(0, -sin(_life * 2) * 10); // Gentle float
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }
}

class _ConfettiParticle extends Node {
  final Size area;
  late Offset pos;
  late Offset vel;
  late Color color;
  @override
  late double rotation;
  late double rotationVel;
  late double size;

  _ConfettiParticle(this.area) {
    final rand = Random();
    pos = Offset(area.width / 2, area.height / 2);
    double angle = rand.nextDouble() * 2 * pi;
    double speed = rand.nextDouble() * 400 + 200;
    vel = Offset(cos(angle) * speed, sin(angle) * speed);
    color = Colors.primaries[rand.nextInt(Colors.primaries.length)];
    rotation = rand.nextDouble() * 2 * pi;
    rotationVel = (rand.nextDouble() - 0.5) * 10;
    size = rand.nextDouble() * 10 + 5;
  }

  @override
  void update(double dt) {
    vel += const Offset(0, 400) * dt; // Gravity
    pos += vel * dt;
    rotation += rotationVel * dt;
    if (pos.dy > area.height) {
      removeFromParent();
    }
  }

  @override
  void paint(Canvas canvas) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size, height: size / 2),
      Paint()..color = color,
    );
    canvas.restore();
  }
}

class _RadialGlowNode extends Node {
  final Size area;
  double _life = 0;

  _RadialGlowNode(this.area);

  @override
  void update(double dt) {
    _life += dt;
  }

  @override
  void paint(Canvas canvas) {
    double radius = (area.width / 2) * (1.0 + sin(_life * 2) * 0.1);
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(area.width / 2, area.height / 2),
        radius,
        [
          const Color(0xffF59E0B).withOpacity(0.3 * (0.5 + 0.5 * sin(_life * 3))),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(Offset(area.width / 2, area.height / 2), radius, paint);
  }
}

class _SparkleParticle extends Node {
  final Size area;
  final bool isInitialBurst;
  late Offset pos;
  late Offset vel;
  late double life = 1.0;
  late double decay;
  late double size;

  _SparkleParticle(this.area, {this.isInitialBurst = false}) {
    final rand = Random();
    pos = Offset(area.width / 2, area.height / 2);
    
    double angle = rand.nextDouble() * 2 * pi;
    double speed;
    if (isInitialBurst) {
      speed = rand.nextDouble() * 1000 + 200;
    } else {
      speed = rand.nextDouble() * 300 + 50;
      // Start slightly offset from center
      pos += Offset(cos(angle) * 100, sin(angle) * 100);
    }
    
    vel = Offset(cos(angle) * speed, sin(angle) * speed);
    decay = rand.nextDouble() * 0.7 + 0.3;
    size = rand.nextDouble() * 5 + 2;
  }

  @override
  void update(double dt) {
    life -= decay * dt;
    pos += vel * dt;
    vel *= 0.95; // Drag
    if (life <= 0) removeFromParent();
  }

  @override
  void paint(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(life.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(pos, size * life, paint);
    
    // Add a cross glow
    final glowPaint = Paint()
      ..color = Colors.yellowAccent.withOpacity(life * 0.5)
      ..strokeWidth = 1.0;
    
    double s = size * 4 * life;
    canvas.drawLine(pos - Offset(s, 0), pos + Offset(s, 0), glowPaint);
    canvas.drawLine(pos - Offset(0, s), pos + Offset(0, s), glowPaint);
  }
}
