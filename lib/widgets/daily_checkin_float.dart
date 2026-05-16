import 'package:flutter/material.dart';

class TrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 0.75, size.height);
    path.lineTo(size.width * 0.25, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TrapezoidBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF7924A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 0.75, size.height);
    path.lineTo(size.width * 0.25, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DailyCheckinFloat extends StatelessWidget {
  final VoidCallback onTap;

  const DailyCheckinFloat({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Transform.scale(
        scale: 0.85,

        child: SizedBox(
          width: 140,
          height: 180,

          child: Stack(
            alignment: Alignment.center,

            children: [
              Positioned(
                top: 45,

                child: Stack(
                  children: [
                    // fill
                    ClipPath(
                      clipper: TrapezoidClipper(),
                      child: Container(
                        width: 120,
                        height: 90,
                        color: Colors.white,
                      ),
                    ),

                    // outline
                    CustomPaint(
                      size: const Size(120, 90),
                      painter: TrapezoidBorderPainter(),
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 20,
                left: 6,

                child: Transform.rotate(
                  angle: -0.12,

                  child: Stack(
                    children: [
                      Text(
                        '+XP',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,

                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4
                            ..color = const Color(0xFFFBD2B6),
                        ),
                      ),

                      const Text(
                        '+XP',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: Color(0xFFF7924A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 55,

                child: const Icon(
                  Icons.gps_fixed_rounded,
                  size: 64,
                  color: Color(0xFFF7924A),
                ),
              ),

              // ── BUTTON (OVERLAP BAWAH SHAPE) ─────────
              Positioned(
                top: 120,

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 7,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF7924A),
                    borderRadius: BorderRadius.circular(30),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: const Text(
                    'Masuk Hari Ini',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}