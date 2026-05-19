import 'dart:math' show sqrt;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/starter_screen.dart';
import 'screens/beranda.dart';
import 'helper/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const JaktimerApp());
}

class JaktimerApp extends StatelessWidget {
  const JaktimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jaktimer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8C00),
          primary: const Color(0xFFFF8C00),
        ),
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: const AnimatedSplashScreen(),
    );
  }
}

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _orange = Color(0xFFFF8C00);

  late final AnimationController _ctrl;
  late final Animation<double> _textOrangeIn;
  late final Animation<double> _dotY;
  late final Animation<double> _dotScale;
  late final Animation<double> _circleRadius;
  late final Animation<double> _textOrangeOut;
  late final Animation<double> _textWhiteIn;

  // ── Audio ─────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Flag biar listener ga trigger play berkali-kali
  bool _audioPlayed = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    // Frame 1 — teks oren fade in
    _textOrangeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.00, 0.18, curve: Curves.easeOut),
      ),
    );

    // Frame 2 — dot jatuh dari atas
    _dotY = Tween<double>(begin: -160, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.22, 0.40, curve: Curves.easeIn),
      ),
    );
    _dotScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.22, 0.40, curve: Curves.easeOut),
      ),
    );

    // Frame 3 — circle expand
    _circleRadius = Tween<double>(begin: 14, end: 110).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.40, 0.60, curve: Curves.easeInOut),
      ),
    );

    // Frame 4 — swap teks oren → putih
    _textOrangeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.38, 0.44, curve: Curves.easeOut),
      ),
    );
    _textWhiteIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.42, 0.50, curve: Curves.easeIn),
      ),
    );

    // ── Listener: play audio tepat saat circle full nutup layar (t >= 0.84)
    _ctrl.addListener(_onAnimationTick);

    _run();
  }

  void _onAnimationTick() {
    if (!_audioPlayed && _ctrl.value >= 0.84) {
      _audioPlayed = true;
      _playSound();
    }
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sound/splash.mp3'));
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await _navigateNext();
  }

  // ── Validasi sesi ─────────────────────────
  // Cek userId di SharedPreferences masih ada di DB.
  // Kalau DB ke-reset (onUpgrade), prefs di-clear → balik ke StarterScreen.
  Future<bool> _isSessionValid(int userId) async {
    try {
      final user = await DatabaseHelper().getUserById(userId);
      return user != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    bool isLoggedIn = false;

    if (userId != null) {
      final valid = await _isSessionValid(userId);
      if (valid) {
        isLoggedIn = true;
      } else {
        await prefs.clear();
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            isLoggedIn ? const HomeScreen() : const StarterScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onAnimationTick);
    _ctrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double fullRadius =
        sqrt(size.width * size.width + size.height * size.height) * 1.3;

    final fillAnim = Tween<double>(
      begin: 110,
      end: fullRadius,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.60, 0.60, curve: Curves.easeInOut),
      ),
    );

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;

        final double radius;
        if (t < 0.22) {
          radius = 0;
        } else if (t < 0.40) {
          radius = 14 * _dotScale.value;
        } else if (t < 0.60) {
          radius = _circleRadius.value;
        } else {
          radius = fillAnim.value;
        }

        final double orangeOp;
        if (t < 0.18) {
          orangeOp = _textOrangeIn.value;
        } else if (t < 0.38) {
          orangeOp = 1.0;
        } else if (t < 0.44) {
          orangeOp = _textOrangeOut.value;
        } else {
          orangeOp = 0.0;
        }

        final double whiteOp = t >= 0.42 ? _textWhiteIn.value : 0.0;

        final bool isFull = t >= 0.84;

        return Scaffold(
          backgroundColor: isFull ? _orange : Colors.white,
          body: SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Teks oren tengah
                if (orangeOp > 0)
                  Opacity(
                    opacity: orangeOp.clamp(0.0, 1.0),
                    child: Text(
                      'Jaktimer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: _orange,
                      ),
                    ),
                  ),

                // 2. Circle oren gerak
                if (radius > 0)
                  Transform.translate(
                    offset: Offset(0, t < 0.40 ? _dotY.value : 0),
                    child: Container(
                      width: radius * 2,
                      height: radius * 2,
                      decoration: const BoxDecoration(
                        color: _orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                // 3. Teks putih
                if (whiteOp > 0)
                  Opacity(
                    opacity: whiteOp.clamp(0.0, 1.0),
                    child: Text(
                      'Jaktimer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}