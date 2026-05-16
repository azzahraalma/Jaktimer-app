import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/database_helper.dart';
import 'login_screen.dart';
import 'starter_screen.dart';
import 'beranda.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreedToTerms   = false;
  bool _isLoading       = false;

  static const _orange      = Color(0xFFFF8C00);
  static const _bgField     = Color(0xFFF5F5F5);
  static const _borderField = Color(0xFFE8E8E8);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _doRegister() async {
    final username = _usernameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty)                    return _showSnack('Username tidak boleh kosong');
    if (email.isEmpty || !email.contains('@')) return _showSnack('Email tidak valid');
    if (password.length < 8)                 return _showSnack('Password minimal 8 karakter');
    if (!_agreedToTerms)                     return _showSnack('Harap setujui Syarat dan Keamanan');

    setState(() => _isLoading = true);

    try {
      final db    = DatabaseHelper();

      final newId = await db.registerUser({
        'username'          : username,
        'email'             : email,
        'password'          : password,
        'level'             : 1,
        'xp'                : 0,
        'level_name'        : 'Explorer Muda',
        'avatar_url'        : 'https://api.dicebear.com/7.x/adventurer/png?seed=$username',
        'image_path'        : null,
        'security_question' : null,
        'security_answer'   : null,
      });

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', newId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (mounted) _showSnack('Email sudah digunakan akun lain.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              _buildHeader('Daftar'),
              const SizedBox(height: 24),
              _buildMascot(),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Username'),
                    _buildTextField(
                      controller: _usernameController,
                      hint: 'username',
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('E-mail'),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'example@email.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Password'),
                    _buildPasswordField(),
                    const SizedBox(height: 14),
                    _buildCheckbox(),
                    const SizedBox(height: 22),
                    _buildSubmitButton(
                      label: 'Daftar',
                      onPressed: _isLoading ? null : _doRegister,
                    ),
                    const SizedBox(height: 20),
                    _buildAltLink(
                      prefix: 'Sudah Punya akun? ',
                      linkText: 'Masuk',
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
            'assets/images/mascot/timo_7.png', // path ke file lokal
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
        hintText: 'minimal 8 karakter',
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

  Widget _buildCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            activeColor: _orange,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
              children: [
                const TextSpan(text: 'Saya setuju dengan '),
                TextSpan(
                  text: 'Syarat',
                  style: const TextStyle(
                      color: _orange, fontWeight: FontWeight.w700),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                const TextSpan(text: ' dan '),
                TextSpan(
                  text: 'Keamanan',
                  style: const TextStyle(
                      color: _orange, fontWeight: FontWeight.w700),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
              ],
            ),
          ),
        ),
      ],
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