import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/database_helper.dart';
import 'login_screen.dart';
import 'starter_screen.dart';
import 'beranda.dart';

// ─────────────────────────────────────────────
//  TERMS DIALOG WIDGET
// ─────────────────────────────────────────────

class TermsDialog extends StatelessWidget {
  const TermsDialog({super.key});

  static const _orange = Color(0xFFFF8C00);

  static const _sections = [
    _TermSection(
      title: '1. Penerimaan Syarat',
      content:
          'Dengan mendaftar dan menggunakan aplikasi ini, kamu menyetujui '
          'seluruh syarat dan ketentuan yang berlaku. Harap baca dengan '
          'seksama sebelum melanjutkan pendaftaran.',
    ),
    _TermSection(
      title: '2. Penggunaan Akun',
      content:
          'Kamu bertanggung jawab penuh atas keamanan akun dan seluruh '
          'aktivitas yang terjadi di dalamnya. Jangan berbagi informasi '
          'login kepada siapa pun demi keamanan bersama.',
    ),
    _TermSection(
      title: '3. Privasi & Data',
      content:
          'Data pribadi kamu kami simpan dengan aman menggunakan enkripsi '
          'standar industri dan tidak akan dibagikan kepada pihak ketiga '
          'tanpa persetujuanmu, kecuali diwajibkan oleh hukum yang berlaku.',
    ),
    _TermSection(
      title: '4. Konten Pengguna',
      content:
          'Kamu setuju untuk tidak mengunggah konten yang melanggar hukum, '
          'bersifat ofensif, mengandung ujaran kebencian, atau melanggar '
          'hak kekayaan intelektual pihak lain.',
    ),
    _TermSection(
      title: '5. Perubahan Layanan',
      content:
          'Kami berhak mengubah, menangguhkan, atau menghentikan layanan '
          'sewaktu-waktu. Perubahan signifikan akan diberitahukan melalui '
          'notifikasi aplikasi atau email terdaftar.',
    ),
    _TermSection(
      title: '6. Batasan Tanggung Jawab',
      content:
          'Aplikasi ini disediakan "sebagaimana adanya". Kami tidak '
          'bertanggung jawab atas kerugian langsung maupun tidak langsung '
          'yang timbul akibat penggunaan atau ketidakmampuan menggunakan '
          'layanan ini.',
    ),
    _TermSection(
      title: '7. Hukum yang Berlaku',
      content:
          'Syarat dan ketentuan ini diatur oleh hukum Republik Indonesia. '
          'Segala sengketa akan diselesaikan melalui jalur musyawarah atau '
          'pengadilan yang berwenang.',
    ),
  ];

  /// Cara pakai: TermsDialog.show(context)
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => const TermsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Syarat & Ketentuan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _orange,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF888888),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            const Text(
              'Terakhir diperbarui: 1 Januari 2025',
              style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 4),

            // ── Scrollable Content ───────────────
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(4),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                  shrinkWrap: true,
                  itemCount: _sections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _SectionTile(section: _sections[i]),
                ),
              ),
            ),

            const SizedBox(height: 4),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),

            // ── CTA Button ───────────────────────
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Saya Mengerti',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PRIVATE HELPER MODELS & WIDGETS
// ─────────────────────────────────────────────

class _TermSection {
  final String title;
  final String content;
  const _TermSection({required this.title, required this.content});
}

class _SectionTile extends StatelessWidget {
  final _TermSection section;
  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          section.content,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF555555),
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  REGISTER SCREEN
// ─────────────────────────────────────────────

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

    if (username.isEmpty)                     return _showSnack('Username tidak boleh kosong');
    if (email.isEmpty || !email.contains('@')) return _showSnack('Email tidak valid');
    if (password.length < 8)                  return _showSnack('Password minimal 8 karakter');
    if (!_agreedToTerms)                      return _showSnack('Harap setujui Syarat dan Keamanan');

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper();

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

  // ── Build ──────────────────────────────────

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

  // ── Header ────────────────────────────────

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

  // ── Mascot ────────────────────────────────

  Widget _buildMascot() {
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/mascot/timo_7.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // ── Form Fields ───────────────────────────

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

  // ── Checkbox + Terms ──────────────────────

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
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
                    color: _orange,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => TermsDialog.show(context),
                ),
                const TextSpan(text: ' dan '),
                TextSpan(
                  text: 'Ketentuan',
                  style: const TextStyle(
                    color: _orange,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => TermsDialog.show(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Submit Button ─────────────────────────

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
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

  // ── Alt Link ──────────────────────────────

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
                color: _orange,
                fontWeight: FontWeight.w700,
              ),
              recognizer: TapGestureRecognizer()..onTap = onTap,
            ),
          ],
        ),
      ),
    );
  }
}