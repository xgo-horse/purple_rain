import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purple Rain',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  List<RainParticle> particles = [];
  List<SplashEffect> splashes = [];
  late final AnimationController _controller;
  Duration _lastElapsed = Duration.zero;
  Size _currentSize = Size.zero;

  // Lightning state variables
  double _lightningIntensity = 0.0;
  List<Offset> _lightningPath = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _controller.addListener(() {
      final Duration elapsed = _controller.lastElapsedDuration ?? Duration.zero;
      final deltaTime = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      // Update lightning flash
      if (_lightningIntensity > 0.0) {
        _lightningIntensity -= deltaTime * 3.5; // Fades out in ~0.3s
        if (_lightningIntensity < 0.0) {
          _lightningIntensity = 0.0;
          _lightningPath = [];
        }
      } else {
        // Subtle random chance for lightning (~0.2% per frame)
        if (Random().nextDouble() < 0.002 && _currentSize != Size.zero) {
          _lightningIntensity = 1.0;
          _lightningPath = _generateLightningPath(_currentSize);
        }
      }

      // Update splashes
      for (var i = splashes.length - 1; i >= 0; i--) {
        splashes[i].step(deltaTime);
        if (splashes[i].isExpired) {
          splashes.removeAt(i);
        }
      }

      // Update particles
      for (var particle in particles) {
        if (particle.y >= particle.yLimit ||
            particle.x > 1.1 ||
            particle.x < -0.1) {
          if (particle.y >= particle.yLimit && _currentSize != Size.zero) {
            splashes.add(
              SplashEffect(
                x: particle.x,
                y: particle.yLimit,
                maxRadius: 10.0 * particle.z,
              ),
            );
          }
          particle.randomize(_currentSize);
        } else {
          particle.step(deltaTime, _currentSize);
        }
      }

      setState(() {});
    });
    _controller.repeat();
  }

  List<Offset> _generateLightningPath(Size size) {
    if (size == Size.zero) return [];
    final path = <Offset>[];
    final startX = Random().nextDouble() * size.width;
    path.add(Offset(startX, 0));

    double curX = startX;
    double curY = 0;
    final targetY = size.height * 0.8; // Stop at the ground horizon

    while (curY < targetY) {
      curY += Random().nextDouble() * 30 + 15;
      curX += (Random().nextDouble() - 0.5) * 45;
      path.add(Offset(curX, curY));
    }
    return path;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newSize = MediaQuery.sizeOf(context);
    if (_currentSize != Size.zero &&
        _currentSize.width != newSize.width &&
        newSize.width > 0) {
      final scaleX = _currentSize.width / newSize.width;
      for (var particle in particles) {
        particle.x *= scaleX;
      }
      for (var splash in splashes) {
        splash.x *= scaleX;
      }
      // Scale active lightning bolt paths to preserve horizontal alignment
      for (var i = 0; i < _lightningPath.length; i++) {
        _lightningPath[i] = Offset(
          _lightningPath[i].dx * scaleX,
          _lightningPath[i].dy,
        );
      }
    }
    _currentSize = newSize;
    _adjustParticles(_currentSize);
  }

  void _adjustParticles(Size size) {
    final area = size.width * size.height;
    final targetCount = (area * 0.000416).round().clamp(10, 1500);
    if (particles.length < targetCount) {
      for (var i = particles.length; i < targetCount; i++) {
        particles.add(RainParticle.random(size));
      }
    } else if (particles.length > targetCount) {
      particles.removeRange(targetCount, particles.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RepaintBoundary(
          child: CustomPaint(
            size: _currentSize,
            painter: PurpleRainPainter(
              particles: particles,
              splashes: splashes,
              lightningIntensity: _lightningIntensity,
              lightningPath: _lightningPath,
              repaint: _controller,
            ),
          ),
        ),
      ),
    );
  }
}

class PurpleRainPainter extends CustomPainter {
  PurpleRainPainter({
    required this.particles,
    required this.splashes,
    required this.lightningIntensity,
    required this.lightningPath,
    super.repaint,
  });

  final List<RainParticle> particles;
  final List<SplashEffect> splashes;
  final double lightningIntensity;
  final List<Offset> lightningPath;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw beautiful dark night gradient background
    // Blend with brighter colors during a lightning flash
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(
          const Color(0xFF070214),
          const Color(0xFF4A2574),
          lightningIntensity,
        )!,
        Color.lerp(
          const Color(0xFF140727),
          const Color(0xFF321752),
          lightningIntensity,
        )!,
        Color.lerp(
          const Color(0xFF1D0E3A),
          const Color(0xFF1B0C30),
          lightningIntensity,
        )!,
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = bgGradient.createShader(Offset.zero & size),
    );

    // 2. Draw stylized soft ground gradient with a subtle green and purple hue
    final groundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(
          const Color(0xFF102216),
          const Color(0xFF27442F),
          lightningIntensity,
        )!,
        Color.lerp(
          const Color(0xFF0F091E),
          const Color(0xFF1D1432),
          lightningIntensity,
        )!,
      ],
    );
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.8, size.width, size.height),
      Paint()
        ..shader = groundGradient.createShader(
          Rect.fromLTRB(0, size.height * 0.8, size.width, size.height),
        ),
    );

    // 3. Draw ground horizon line/glow
    final horizonPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF275C34),
        const Color(0xFF5AB66F),
        lightningIntensity,
      )!.withValues(alpha: 0.35 + 0.25 * lightningIntensity)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.8),
      horizonPaint,
    );

    // 3.5. Draw lightning flash overlay and bolt path if active
    if (lightningIntensity > 0.0) {
      // Ambient flash overlay
      final flashPaint = Paint()
        ..color = const Color(
          0xFFE040FB,
        ).withValues(alpha: lightningIntensity * 0.18);
      canvas.drawRect(Offset.zero & size, flashPaint);

      // Jagged bolt
      if (lightningPath.isNotEmpty) {
        final path = Path();
        path.moveTo(lightningPath.first.dx, lightningPath.first.dy);
        for (var i = 1; i < lightningPath.length; i++) {
          path.lineTo(lightningPath[i].dx, lightningPath[i].dy);
        }

        // Draw bolt outer glow
        final glowPaint = Paint()
          ..color = const Color(
            0xFFE040FB,
          ).withValues(alpha: lightningIntensity * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawPath(path, glowPaint);

        // Draw bolt bright core
        final corePaint = Paint()
          ..color = Colors.white.withValues(alpha: lightningIntensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, corePaint);
      }
    }

    // 4. Draw rain particles
    for (var particle in particles) {
      particle.draw(canvas, size);
    }

    // 5. Draw splashes
    for (var splash in splashes) {
      splash.draw(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant PurpleRainPainter oldDelegate) {
    return true;
  }
}

class RainParticle {
  double z;
  double x;
  double y;
  double yLimit = 1.2;

  RainParticle({required this.z, required this.x, required this.y});

  factory RainParticle.random(Size canvasSize) {
    final particle = RainParticle(z: 0, x: 0, y: 0);
    particle.randomize(canvasSize);
    return particle;
  }

  void randomize(Size canvasSize) {
    z = Random().nextDouble() + 0.1;
    x = Random().nextDouble() * 1.2 - 0.1;
    y = -Random().nextDouble();

    final zNormalized = (z - 0.1) / 1.0;
    yLimit = 0.8 + 0.2 * zNormalized;
  }

  void draw(Canvas canvas, Size size) {
    final startX = size.width * x;
    final startY = size.height * y;

    final distanceToLimit = yLimit - y;
    final fade = (distanceToLimit / 0.15).clamp(0.0, 1.0);

    final length = (16 * z + 2) * fade;
    final slantOffset = length * 0.15;

    final endX = startX + slantOffset;
    final endY = startY + length;

    final baseColor = Color.lerp(
      const Color(0xFF9C27B0),
      const Color(0xFFE040FB),
      z.clamp(0.0, 1.0),
    )!;

    final particlePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2 * z + 0.5
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              baseColor.withValues(alpha: 0.0),
              baseColor.withValues(alpha: z.clamp(0.1, 1.0) * fade),
            ],
          ).createShader(
            Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)),
          );

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), particlePaint);
  }

  void step(double deltaTime, Size size) {
    final referenceHeight = 600.0;
    final referenceWidth = 800.0;

    final double dy =
        (referenceHeight * z * deltaTime) /
        (size.height > 0 ? size.height : 600.0);
    final double dx =
        (referenceWidth * 0.15 * z * deltaTime) /
        (size.width > 0 ? size.width : 800.0);

    y = y + dy;
    x = x + dx;
  }
}

class SplashEffect {
  double x; // normalized x
  double y; // normalized y
  final double maxRadius;
  double progress = 0.0;
  final List<Offset> droplets;

  SplashEffect({required this.x, required this.y, required this.maxRadius})
    : droplets = List.generate(4, (index) {
        final angle =
            -pi / 4 - (index * pi / 6) + (Random().nextDouble() * 0.1 - 0.05);
        final speed = Random().nextDouble() * 25 + 15;
        return Offset(cos(angle) * speed, sin(angle) * speed);
      });

  void step(double deltaTime) {
    progress += deltaTime * 2.5; // Complete in ~0.4s
  }

  bool get isExpired => progress >= 1.0;

  void draw(Canvas canvas, Size size) {
    final absX = size.width * x;
    final absY = size.height * y;
    final double radius = maxRadius * progress;
    final double opacity = (1.0 - progress).clamp(0.0, 1.0);

    // 1. Draw ripple ellipse
    final ripplePaint = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(absX, absY),
        width: radius * 2.5,
        height: radius * 0.6,
      ),
      ripplePaint,
    );

    // 2. Draw splash droplets
    final dropletPaint = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: opacity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    for (var droplet in droplets) {
      final double dx = droplet.dx * progress;
      final double dy =
          droplet.dy * progress + 8.0 * progress * progress; // Gravity curve
      canvas.drawCircle(Offset(absX + dx, absY + dy), 1.0, dropletPaint);
    }
  }
}
