// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helper/database_helper.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
  with WidgetsBindingObserver {
  final DatabaseHelper _db = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();
  

  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _badges = [];
  int _totalTempat = 0;
  int _totalUlasan = 0;
  int _totalArtikel = 0;
  bool _isLoading = true;

  // ── Level & XP thresholds — IDENTIK dengan daily_checkin_screen.dart ────
  static const List<int> _xpThresholds = [0, 1000, 2000, 3000, 5000, 99999];

  static int _levelFromXp(int xp) {
    if (xp >= 5000) return 5;
    if (xp >= 3000) return 4;
    if (xp >= 2000) return 3;
    if (xp >= 1000) return 2;
    return 1;
  }

  static String _levelNameFromLevel(int level) {
    switch (level) {
      case 5:
        return 'Penakluk';
      case 4:
        return 'Penjelajah Sejati';
      case 3:
        return 'Penjelajah';
      case 2:
        return 'Explorer Sejati';
      default:
        return 'Explorer Muda';
    }
  }

  static const List<String> _securityQuestions = [
    'Nama hewan peliharaan pertamamu?',
    'Nama sekolah dasar tempat kamu belajar?',
    'Kota kelahiranmu?',
    'Nama tengah ibumu?',
    'Nama julukan masa kecilmu?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final user = await _db.getUserById(widget.userId);
    final badges = await _db.getUserBadges(widget.userId);
    final totalTempat = await _db.getTotalTempat(widget.userId);
    final totalUlasan = await _db.getTotalUlasan(widget.userId);
    final totalArtikel = await _db.getTotalArtikelDibaca(widget.userId);

    // ── Perbaiki level di DB kalau masih salah akibat bug lama ──────────────
    if (user != null) {
      final xp = user['xp'] as int? ?? 0;
      final correctLevel = _levelFromXp(xp);
      final correctLevelName = _levelNameFromLevel(correctLevel);
      final storedLevel = user['level'] as int? ?? 1;
      if (storedLevel != correctLevel) {
        await _db.updateUserProfile(widget.userId, {
          'level': correctLevel,
          'level_name': correctLevelName,
        });
        final correctedUser = await _db.getUserById(widget.userId);
        setState(() {
          _user = correctedUser;
          _badges = badges;
          _totalTempat = totalTempat;
          _totalUlasan = totalUlasan;
          _totalArtikel = totalArtikel;
          _isLoading = false;
        });
        return;
      }
    }

    setState(() {
      _user = user;
      _badges = badges;
      _totalTempat = totalTempat;
      _totalUlasan = totalUlasan;
      _totalArtikel = totalArtikel;
      _isLoading = false;
    });
  }

  // ── XP helpers — IDENTIK dengan daily_checkin_screen.dart ─────────────────

  double _calcProgress(int xp, int level) {
    final idx = (level - 1).clamp(0, _xpThresholds.length - 2);
    final xpPrev = _xpThresholds[idx];
    final xpNext = _xpThresholds[idx + 1];
    if (xpNext <= xpPrev) return 1.0;
    return ((xp - xpPrev) / (xpNext - xpPrev)).clamp(0.0, 1.0);
  }

  int _xpNeeded(int level) {
    final idx = level.clamp(1, _xpThresholds.length - 1);
    return _xpThresholds[idx];
  }

  int _xpToNextLevel(int xp, int level) {
    if (level >= 5) return 0;
    final nextThreshold = _xpNeeded(level);
    final remaining = nextThreshold - xp;
    return remaining < 0 ? 0 : remaining;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GANTI FOTO PROFIL
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Ganti Foto Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFFF7924A)),
                ),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ambil foto dari album',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEFFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF7C83FD)),
                ),
                title: const Text('Ambil Foto',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Gunakan kamera sekarang',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_user?['image_path'] != null &&
                  (_user?['image_path'] as String).isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFFF4444)),
                  ),
                  title: const Text('Hapus Foto',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF4444))),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removePhoto();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      await _db.updateUserImagePath(widget.userId, picked.path);
      await _load();
      if (mounted) _showSnackBar('Foto profil berhasil diperbarui! 📸');
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memilih foto. Coba lagi.', isError: true);
      }
    }
  }

  Future<void> _removePhoto() async {
    await _db.updateUserImagePath(widget.userId, '');
    await _load();
    if (mounted) _showSnackBar('Foto profil dihapus.');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDIT USERNAME & EMAIL
  // ═══════════════════════════════════════════════════════════════════════════

  void _showEditProfileDialog() {
    final usernameCtrl =
        TextEditingController(text: _user?['username'] as String? ?? '');
    final emailCtrl =
        TextEditingController(text: _user?['email'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
              fontWeight: FontWeight.w800, color: Color(0xFFF7924A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Username',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 74, 74, 74))),
            const SizedBox(height: 6),
            _buildDialogTextField(usernameCtrl, 'Masukkan username'),
            const SizedBox(height: 14),
            const Text('Email',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 74, 74, 74))),
            const SizedBox(height: 6),
            _buildDialogTextField(emailCtrl, 'Masukkan email',
                keyboardType: TextInputType.emailAddress),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = usernameCtrl.text.trim();
              final newEmail = emailCtrl.text.trim();
              if (newUsername.isEmpty || newEmail.isEmpty) {
                _showSnackBar('Username dan email tidak boleh kosong.',
                    isError: true);
                return;
              }
              if (!newEmail.contains('@')) {
                _showSnackBar('Format email tidak valid.', isError: true);
                return;
              }
              try {
                await _db.updateUsernameEmail(
                    widget.userId, newUsername, newEmail);
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
                if (mounted) _showSnackBar('Profil berhasil diperbarui! ✅');
              } catch (e) {
                if (mounted) {
                  _showSnackBar(
                    e.toString().replaceFirst('Exception: ', ''),
                    isError: true,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7924A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 241, 231),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF7924A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF7924A), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UBAH KATA SANDI
  // ═══════════════════════════════════════════════════════════════════════════

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool obscureOld = true;
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Ubah Kata Sandi',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFFF7924A)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(oldCtrl, 'Kata sandi lama',
                    obscure: obscureOld,
                    onToggle: () =>
                        setDialogState(() => obscureOld = !obscureOld)),
                const SizedBox(height: 10),
                _buildField(newCtrl, 'Kata sandi baru',
                    obscure: obscureNew,
                    onToggle: () =>
                        setDialogState(() => obscureNew = !obscureNew)),
                const SizedBox(height: 10),
                _buildField(confirmCtrl, 'Konfirmasi kata sandi baru',
                    obscure: obscureConfirm,
                    onToggle: () => setDialogState(
                        () => obscureConfirm = !obscureConfirm)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showForgotPasswordDialog();
                    },
                    child: const Text(
                      'Lupa kata sandi?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFF7924A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Batal',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (newCtrl.text != confirmCtrl.text) {
                    _showSnackBar('Konfirmasi kata sandi tidak cocok!',
                        isError: true);
                    return;
                  }
                  if (newCtrl.text.length < 6) {
                    _showSnackBar('Kata sandi baru minimal 6 karakter.',
                        isError: true);
                    return;
                  }
                  final ok = await _db.updatePassword(
                      widget.userId, oldCtrl.text, newCtrl.text);
                  if (!ok) {
                    _showSnackBar('Kata sandi lama salah!', isError: true);
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) _showSnackBar('Kata sandi berhasil diubah! 🔐');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7924A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simpan',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text,
      bool obscure = false,
      VoidCallback? onToggle}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 241, 231),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF7924A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF7924A), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFFF7924A),
                  size: 18,
                ),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LUPA KATA SANDI
  // ═══════════════════════════════════════════════════════════════════════════

  void _showForgotPasswordDialog() {
    final emailCtrl =
        TextEditingController(text: _user?['email'] as String? ?? '');
    showDialog(
      context: context,
      builder: (ctx) => _ForgotPasswordDialog(
        db: _db,
        initialEmail: emailCtrl.text,
        securityQuestions: _securityQuestions,
        onSuccess: () {
          if (mounted) _showSnackBar('Kata sandi berhasil direset! 🎉');
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALL BADGES SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAllBadgesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Semua Pencapaian',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_badges.length} badge diraih',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _badges.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🏅',
                                  style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada badge.\nSelesaikan misi untuk mendapatkannya!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          controller: scrollCtrl,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _badges.length,
                          itemBuilder: (_, i) =>
                              _buildBadgeGridItem(_badges[i]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Keluar Akun',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        content: Text(
          'Yakin mau keluar dari akun ${_user?['username'] ?? 'ini'}?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF555555),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFFF4444) : const Color(0xFFF7924A),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFF7924A))),
      );
    }

    final int xp = _user?['xp'] as int? ?? 0;
    final String username = _user?['username'] as String? ?? 'Timo';
    final String email = _user?['email'] as String? ?? '';
    final String avatarUrl = _user?['avatar_url'] as String? ?? '';
    final String imagePath = _user?['image_path'] as String? ?? '';

    // ── Selalu hitung ulang level dari total XP ──────────────────────────────
    final int level = _levelFromXp(xp);
    final String levelName = _levelNameFromLevel(level);
    final int xpNeeded = _xpNeeded(level);
    final int xpKurang = _xpToNextLevel(xp, level);
    final double progress = _calcProgress(xp, level);

    final badgePreview = _badges.take(3).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── HEADER ──────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Profil',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF7924A),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── AVATAR ──────────────────────────────────────────────────
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFF7924A), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF7924A).withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: _buildAvatarWidget(
                            imagePath, avatarUrl, username),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7924A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── USERNAME ─────────────────────────────────────────────────
              GestureDetector(
                onTap: _showEditProfileDialog,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_rounded,
                        size: 16, color: Color(0xFFCCCCCC)),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // ── EMAIL ────────────────────────────────────────────────────
              GestureDetector(
                onTap: _showEditProfileDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFBD2B6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_rounded,
                          size: 13, color: Color(0xFFF7924A)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── LEVEL CARD — identik dengan _buildTimoCard di daily checkin ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFF7924A)),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris atas: level & nama level (kiri), total XP (kanan)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Level $level · $levelName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            '$xp XP',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFFF7924A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Teks kecil info XP — identik dengan daily checkin
                      Text(
                        level < 5
                            ? '$xp XP di level ini · kurang $xpKurang XP ke level berikutnya'
                            : '$xp XP · Level Maksimum 🎉',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Progress bar — identik dengan daily checkin
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (ctx, val, _) => Stack(
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: val,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7924A),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Label bawah progress bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$xp / $xpNeeded XP',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF7924A),
                            ),
                          ),
                          Text(
                            level < 5
                                ? 'Menuju ${_levelNameFromLevel(level + 1)}'
                                : 'Level Maksimum! 🎉',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF999999)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── KEAMANAN AKUN ─────────────────────────────────────────────
              _buildSectionHeader('Keamanan Akun'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: _showChangePasswordDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFEEEEEE), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3EC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.lock_outline_rounded,
                              size: 20, color: Color(0xFFF7924A)),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ubah Kata Sandi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ubah atau reset kata sandi akunmu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFFCCCCCC), size: 22),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── PENCAPAIAN ────────────────────────────────────────────────
              _buildSectionHeader(
                'Pencapaian',
                trailing: GestureDetector(
                  onTap: _showAllBadgesSheet,
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF7924A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: badgePreview.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3EC),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: const Color(0xFFFBD2B6)),
                        ),
                        child: Column(
                          children: [
                            const Text('🏅',
                                style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada badge. Selesaikan misi!',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: List.generate(
                          badgePreview.length.clamp(0, 3),
                          (i) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: i < badgePreview.length - 1
                                      ? 12
                                      : 0),
                              child: _buildBadgeCard(badgePreview[i]),
                            ),
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // ── KONTRIBUSI ────────────────────────────────────────────────
              _buildSectionHeader('Kontribusi Kamu'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'Tempat Ditambahkan',
                        value: '$_totalTempat',
                        color: const Color(0xFFF7924A),
                        bgColor: const Color(0xFFFFF3EC),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Ulasan Ditulis',
                        value: '$_totalUlasan',
                        color: const Color(0xFF7C83FD),
                        bgColor: const Color(0xFFEEEFFF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'Artikel Dibaca',
                        value: '$_totalArtikel',
                        color: const Color(0xFF2ECC71),
                        bgColor: const Color(0xFFE8F8F0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Total Badge',
                        value: '${_badges.length}',
                        color: const Color(0xFFFFB800),
                        bgColor: const Color(0xFFFFF8E0),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── KELUAR AKUN ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: _handleLogout,
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                          color: const Color(0xFFF7924A), width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: Color(0xFFF7924A), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Keluar Akun',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFFF7924A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget helpers ──────────────────────────────────────────────────────────

  Widget _buildAvatarWidget(
      String imagePath, String avatarUrl, String username) {
    if (imagePath.isNotEmpty) {
      return Image.file(File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultAvatar(username));
    }
    if (avatarUrl.isNotEmpty) {
      return Image.network(avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultAvatar(username));
    }
    return _buildDefaultAvatar(username);
  }

  Widget _buildDefaultAvatar(String username) {
    return Container(
      color: const Color(0xFFb6e3f4),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : 'T',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(badge['badge_icon'] ?? '🏅',
                  style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(badge['badge_name'] ?? '',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(badge['deskripsi'] ?? '',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF999999)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFBD2B6), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF7924A).withOpacity(0.15),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Center(
                child: Text(badge['badge_icon'] ?? '🏅',
                    style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                badge['badge_name'] ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGridItem(Map<String, dynamic> badge) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBD2B6), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF7924A).withOpacity(0.15),
                  blurRadius: 8,
                )
              ],
            ),
            child: Center(
              child: Text(badge['badge_icon'] ?? '🏅',
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              badge['badge_name'] ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8))),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FORGOT PASSWORD DIALOG
// ═════════════════════════════════════════════════════════════════════════════

class _ForgotPasswordDialog extends StatefulWidget {
  final DatabaseHelper db;
  final String initialEmail;
  final List<String> securityQuestions;
  final VoidCallback onSuccess;

  const _ForgotPasswordDialog({
    required this.db,
    required this.initialEmail,
    required this.securityQuestions,
    required this.onSuccess,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  int _step = 1;

  final _emailCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String? _securityQuestion;
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _answerCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _findAccount() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Masukkan email terlebih dahulu.');
      return;
    }
    setState(() => _isLoading = true);
    final question = await widget.db.getSecurityQuestion(email);
    setState(() => _isLoading = false);
    if (question == null || question.isEmpty) {
      _showError(
          'Email tidak ditemukan atau tidak memiliki pertanyaan keamanan.');
      return;
    }
    setState(() {
      _securityQuestion = question;
      _step = 2;
    });
  }

  Future<void> _resetPassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showError('Konfirmasi kata sandi tidak cocok.');
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      _showError('Kata sandi baru minimal 6 karakter.');
      return;
    }
    if (_answerCtrl.text.trim().isEmpty) {
      _showError('Jawaban tidak boleh kosong.');
      return;
    }
    setState(() => _isLoading = true);
    final ok = await widget.db.resetPasswordWithSecurityAnswer(
      email: _emailCtrl.text.trim(),
      answer: _answerCtrl.text,
      newPassword: _newPassCtrl.text,
    );
    setState(() => _isLoading = false);
    if (!ok) {
      _showError('Jawaban pertanyaan keamanan salah. Coba lagi.');
      return;
    }
    if (mounted) {
      Navigator.pop(context);
      widget.onSuccess();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF4444),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          if (_step == 2)
            GestureDetector(
              onTap: () => setState(() => _step = 1),
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_back_ios_rounded,
                    size: 18, color: Colors.black),
              ),
            ),
          const Expanded(
            child: Text(
              'Lupa Kata Sandi',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFFF7924A)),
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 80,
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFF7924A))),
            )
          : _step == 1
              ? _buildStep1()
              : _buildStep2(),
      actions: _isLoading
          ? []
          : [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Batal',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _step == 1 ? _findAccount : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7924A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _step == 1 ? 'Cari Akun' : 'Reset Kata Sandi',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
    );
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masukkan email akunmu untuk mencari pertanyaan keamanan.',
          style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
        ),
        const SizedBox(height: 14),
        const Text('Email',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF999999))),
        const SizedBox(height: 6),
        _buildField(_emailCtrl, 'Masukkan email',
            keyboardType: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFBD2B6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pertanyaan Keamanan',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF7924A),
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(_securityQuestion ?? '',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Jawaban',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF999999))),
        const SizedBox(height: 6),
        _buildField(_answerCtrl, 'Masukkan jawaban'),
        const SizedBox(height: 14),
        const Text('Kata Sandi Baru',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF999999))),
        const SizedBox(height: 6),
        _buildField(_newPassCtrl, 'Minimal 6 karakter',
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew)),
        const SizedBox(height: 10),
        _buildField(_confirmPassCtrl, 'Konfirmasi kata sandi baru',
            obscure: _obscureConfirm,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm)),
      ],
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text,
      bool obscure = false,
      VoidCallback? onToggle}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 241, 231),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF7924A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFF7924A), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFFF7924A),
                  size: 18,
                ),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }
}