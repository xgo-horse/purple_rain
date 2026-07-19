import 'dart:math';

import 'package:flutter/scheduler.dart';
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
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: MyHomePage(size: MediaQuery.sizeOf(context)),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.size});

  final Size size;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  List<RainParticle> particles = [];
  late final AnimationController _controller;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < 50; i++) {
      particles.add(RainParticle.random(widget.size));
    }
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _controller.addListener((){
        final Duration elapsed = _controller.lastElapsedDuration ?? Duration.zero;
        final deltaTime = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
        _lastElapsed = elapsed;
        for (var particle in particles) {
          if (particle.y >= particle.yLimit || particle.x > 1.1 || particle.x < -0.1) {
            particle.randomize(widget.size);
          } else {
            particle.step(deltaTime);
          }
        } 
      });
    _controller.repeat();

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
        child: RepaintBoundary(child: CustomPaint(
          size: widget.size,
          painter: PurpleRainPainter(particles, repaint: _controller,),
        ),),
      ),
    );
  }
}

class PurpleRainPainter extends CustomPainter {
  PurpleRainPainter(this.particles, {super.repaint});

  final List<RainParticle> particles;

  final Paint rainPaint = Paint()
    ..color = Colors.purple
    ..strokeCap = StrokeCap.round; 

  final Paint grassPaint = Paint()..color = Colors.green;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.8, size.width, size.height),
      grassPaint,
    );

    for (var particle in particles) {
      particle.draw(canvas, size, rainPaint);
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
    // Spawn from -0.1 to 1.1 to accommodate diagonal wind from the left
    x = Random().nextDouble() * 1.2 - 0.1;
    y = -Random().nextDouble();

    // Calculate ground plane yLimit based on depth z.
    // Farther particles (smaller z) hit the ground closer to the horizon (y = 0.8).
    // Closer particles (larger z) fall further down the screen (up to y = 1.0).
    final zNormalized = (z - 0.1) / 1.0; // 0.0 to 1.0
    yLimit = 0.8 + 0.2 * zNormalized;
  }

  void draw(Canvas canvas, Size size, Paint paint) {
    final startX = size.width * x;
    final startY = size.height * y;

    // Fade out as it approaches yLimit (vanishing point on the ground)
    final distanceToLimit = yLimit - y;
    // Fade out in the last 0.15 normalized units before landing
    final fade = (distanceToLimit / 0.15).clamp(0.0, 1.0);

    final length = (16 * z + 2) * fade;

    // Scale color opacity and stroke width based on depth (z) and fade
    paint.color = Colors.purple.withOpacity((z.clamp(0.1, 1.0) * fade).clamp(0.0, 1.0));
    paint.strokeWidth = 2 * z + 0.5;

    // Slant the line to match diagonal movement (blowing to the right)
    final slantOffset = length * 0.15;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX + slantOffset, startY + length),
      paint,
    );
  }

  void step(double deltaTime) {
    y = y + z * deltaTime;
    x = x + 0.15 * z * deltaTime; // Move diagonally to the right
  }
}
