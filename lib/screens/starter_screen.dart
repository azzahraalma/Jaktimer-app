import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class ConcaveTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double curveDepth = 60.0;

    path.moveTo(0, 0);
    path.cubicTo(
      size.width * 0.25, curveDepth,
      size.width * 0.75, curveDepth,
      size.width, 0,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class StarterScreen extends StatefulWidget {
  const StarterScreen({super.key});

  @override
  State<StarterScreen> createState() => _StarterScreenState();
}

class _StarterScreenState extends State<StarterScreen>
    with SingleTickerProviderStateMixin {
  static const _orange = Color(0xFFFF8C00);

  late final AnimationController _ctrl;

  late final Animation<Offset> _shapeSlide;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;

  late final Animation<Offset> _imageSlide;
  late final Animation<double> _imageFade;

  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineFade;

  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _shapeSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.00, 0.75, curve: Curves.easeOutCubic),
    ));

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.08, 0.60, curve: Curves.easeOutCubic),
    ));
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.08, 0.45, curve: Curves.easeOut)),
    );

    _imageSlide = Tween<Offset>(
      begin: const Offset(0, 0.7),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.18, 0.68, curve: Curves.easeOutCubic),
    ));
    _imageFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.18, 0.50, curve: Curves.easeOut)),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.78, curve: Curves.easeOutCubic),
    ));
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.30, 0.60, curve: Curves.easeOut)),
    );

    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 0.95, curve: Curves.easeOutCubic),
    ));
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.45, 0.75, curve: Curves.easeOut)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _orange,
      body: Column(
        children: [
          Expanded(
            flex: 55,
            child: Stack(
              children: [
                Container(color: _orange),
                SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8), 
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Center(
                              child: Text(
                                'Jaktimer',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 62,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: FadeTransition(
                          opacity: _imageFade,
                          child: SlideTransition(
                            position: _imageSlide,
                            child: Align(
                              alignment: const Alignment(-0.16, 0.0),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Image.asset(
                                  'assets/images/mascot/timo_2.png',
                                  height: screenHeight * 0.42,
                                  fit: BoxFit.contain,
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

          //  BOTTOM WHITE SECTION 
          Expanded(
            flex: 45,
            child: SlideTransition(
              position: _shapeSlide,
              child: ClipPath(
                clipper: ConcaveTopClipper(),
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      32,
                      screenHeight * 0.01,
                      32,
                      screenHeight * 0.04,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 70),

                        // Tagline
                        FadeTransition(
                          opacity: _taglineFade,
                          child: SlideTransition(
                            position: _taglineSlide,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF333333),
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        'Yuk, jelajah Jakarta Timur\ndan belajar bareng\n',
                                  ),
                                  TextSpan(
                                    text: 'Si Timo',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: _orange,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 48,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Tombol Mulai
                        FadeTransition(
                          opacity: _buttonFade,
                          child: SlideTransition(
                            position: _buttonSlide,
                            child: ElevatedButton(
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
                                elevation: 6,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                'Mulai',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}