import 'package:flutter/material.dart';
import 'login_screen.dart';

class StarterScreen extends StatelessWidget {
  const StarterScreen({super.key});

  static const _orange = Color(0xFFFF8C00);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _orange,
      body: Column(
        children: [
          // ── TOP ORANGE SECTION ─────────────────────────────────────────────
          Expanded(
            flex: 55,
            child: Stack(
              children: [
                // Orange background
                Container(color: _orange),

                // White wave at the bottom of orange section
                Positioned(
                  bottom: -20, // ← naikin wave ke atas
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, 60),
                    painter: _WavePainter(),
                  ),
                ),

                // Content inside orange
                SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Title ──
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
                        child: Center(
                          child: Text(
                            'Jaktimer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 62,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),

                      // ── Mascot image box ──
                      SizedBox(
                        height: screenHeight * 0.32,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF5ECECA),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  'https://api.dicebear.com/9.x/thumbs/png?seed=Timo&backgroundColor=5ececa&shapeColor=4fc3c8&eyes=variant2W10&mouth=variant1',
                                  fit: BoxFit.contain,
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.sentiment_very_satisfied_rounded,
                                      size: 100,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── BOTTOM WHITE SECTION ───────────────────────────────────────────
          Expanded(
            flex: 45,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  32,
                  screenHeight * 0.01, // dinaikin dikit
                  32,
                  screenHeight * 0.04,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // dinaikin
                  children: [
                    SizedBox(height: 50),
                    // ── Tagline ──
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 28, // lebih gede
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'Yuk, jelajah Jakarta Timur\ndan belajar bareng\n',
                          ),
                          TextSpan(
                            text: 'Si Timo',
                            style: TextStyle(
                              color: _orange,
                              fontWeight: FontWeight.w900,
                              fontSize: 48,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // ── Mulai Button ──
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6, // shadow lebih bagus
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32, // pas ukuran teks
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'Mulai',
                        style: TextStyle(
                          fontSize: 22, // teks lebih gede
                          fontWeight: FontWeight.w900, // lebih bold
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wave painter untuk transisi orange → white ────────────────────────────
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();

    // wave lebih landai (U tipis)
    path.moveTo(0, 0);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.9, // lebih kecil biar ga terlalu lengkung
      size.width,
      0,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}
