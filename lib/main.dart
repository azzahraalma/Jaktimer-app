import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/starter_screen.dart';
import 'screens/beranda.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const SplashGate(),
    );
  }
}

// ─── Cek session saat app dibuka ─────────────────────────────────────────────
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs  = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId'); // null kalau belum login

    if (!mounted) return;

    if (userId != null) {
      // Sudah login → langsung ke HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Belum login → ke StarterScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StarterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading screen saat ngecek session
    return const Scaffold(
      backgroundColor: Color(0xFFFF8C00),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      ),
    );
  }
}