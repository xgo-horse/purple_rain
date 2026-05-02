import 'dart:async';
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

class _MyHomePageState extends State<MyHomePage> {
  List<RainParticle> particles = [];

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < 50; i++) {
      particles.add(RainParticle.random(widget.size));
    }
    Timer.periodic(Duration(milliseconds: 10), (_) {
      for (var particle in particles) {
        if (particle.y >= 0.8) {
          particle.randomize(widget.size);
        } else {
          particle.step();
        }
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CustomPaint(
          size: widget.size,
          painter: PurpleRainPainter(particles),
        ),
      ),
    );
  }
}

class PurpleRainPainter extends CustomPainter {
  const PurpleRainPainter(this.particles);

  final List<RainParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final grassPaint = Paint()..color = Colors.green;
    canvas.drawRect(
      Rect.fromPoints(
        Offset(size.width, size.height),
        Offset(0, size.height - size.height * 0.2),
      ),
      grassPaint,
    );

    for (var particle in particles) {
      particle.draw(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class RainParticle {
  double z;
  double x;
  double y;

  RainParticle({required this.z, required this.x, required this.y});

  factory RainParticle.random(Size canvasSize) {
    final particle = RainParticle(z: 0, x: 0, y: 0);
    particle.randomize(canvasSize);

    return particle;
  }

  void randomize(Size canvasSize) {
    z = Random().nextDouble() + 0.1;
    x = Random().nextDouble();
    y = -Random().nextDouble();
  }

  void draw(Canvas canvas, Size size) {
    final particleOffset = Offset(size.width * x, size.height * y);

    final paint = Paint()..color = Colors.purple;

    canvas.drawRect(
      Rect.fromCenter(
        center: particleOffset,
        width: 5 * z + 1,
        height: 16 * z + 2,
      ),
      paint,
    );
  }

  void step() {
    y = y + 0.01 * z;
  }
}
