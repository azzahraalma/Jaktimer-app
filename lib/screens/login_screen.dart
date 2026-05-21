import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'starter_screen.dart';
import 'beranda.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading       = false;
  bool _isSendingReset  = false;

  static const _orange      = Color(0xFFFF8C00);
  static const _bgField     = Color(0xFFF5F5F5);
  static const _borderField = Color(0xFFE8E8E8);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty)    return _showSnack('Email tidak boleh kosong');
    if (password.isEmpty) return _showSnack('Password tidak boleh kosong');

    setState(() => _isLoading = true);

    try {
      await AuthService.loginUser(email: email, password: password);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          _showSnack('Email atau password salah!');
          break;
        case 'user-disabled':
          _showSnack('Akun ini telah dinonaktifkan.');
          break;
        case 'too-many-requests':
          _showSnack('Terlalu banyak percobaan. Coba lagi nanti.');
          break;
        default:
          _showSnack('Login gagal. Coba lagi.');
      }
    } catch (_) {
      if (mounted) _showSnack('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendResetPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showSnack('Masukkan email terlebih dahulu');
      return;
    }
    
    if (!email.contains('@')) {
      _showSnack('Format email tidak valid');
      return;
    }

    setState(() => _isSendingReset = true);

    try {
      await AuthService.sendPasswordResetEmail(email);
      if (mounted) {
        _showSnack('Cek $email inbox atau folder spam untuk link reset password ');
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Gagal mengirim email reset password.';
        if (e.toString().contains('user-not-found')) {
          errorMsg = 'Email tidak terdaftar. Periksa kembali email Anda.';
        }
        _showSnack(errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader('Masuk'),
              const SizedBox(height: 24),
              _buildMascot(),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Email'),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'example@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Password'),
                    _buildPasswordField(),
                    const SizedBox(height: 8),
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSendingReset ? null : _sendResetPassword,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: _isSendingReset
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _orange,
                                ),
                              )
                            : const Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _orange,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    _buildSubmitButton(
                      label: 'Masuk',
                      onPressed: _isLoading ? null : _doLogin,
                    ),
                    const SizedBox(height: 20),
                    _buildAltLink(
                      prefix: 'Belum Punya akun? ',
                      linkText: 'Daftar',
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StarterScreen()),
            ),
            child: const Icon(Icons.chevron_left, color: _orange, size: 36),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascot() {
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/mascot/timo_1.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF222222),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
        filled: true,
        fillColor: _bgField,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderField, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _orange, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
        filled: true,
        fillColor: _bgField,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFFBDBDBD),
            size: 20,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderField, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _orange, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitButton({
    required String label,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          disabledBackgroundColor: _orange.withOpacity(0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildAltLink({
    required String prefix,
    required String linkText,
    required VoidCallback onTap,
  }) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Color(0xFF777777)),
          children: [
            TextSpan(text: prefix),
            TextSpan(
              text: linkText,
              style: const TextStyle(
                  color: _orange, fontWeight: FontWeight.w700),
              recognizer: TapGestureRecognizer()..onTap = onTap,
            ),
          ],
        ),
      ),
    );
  }
}