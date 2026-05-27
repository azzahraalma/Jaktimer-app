import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../helper/database_helper.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _db = DatabaseHelper();

  String get _uid => AuthService.currentUid ?? '';

  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _badges = [];
  int _totalTempat = 0;
  int _totalUlasan = 0;
  int _totalArtikel = 0;
  bool _isLoading = true;

  static const List<int> _xpThresholds = [0, 1000, 2000, 3000, 5000, 99999];

  static int _levelFromXp(int xp) => FirestoreService.levelFromXp(xp);
  static String _levelNameFromLevel(int level) => FirestoreService.levelNameFromLevel(level);

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
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    if (_uid.isEmpty) return;
    setState(() => _isLoading = true);

    final userFuture = FirestoreService.getUser(_uid);
    final badgesFuture = FirestoreService.getUserBadges(_uid);

    final user = await userFuture;
    final badges = await badgesFuture;

    int totalTempat = 0;
    int totalUlasan = 0;
    int totalArtikel = 0;

    if (user != null) {
      final email = user['email'] as String? ?? '';
      final db = await _db.database;
      final sqliteUser = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (sqliteUser.isNotEmpty) {
        final sqliteUserId = sqliteUser.first['id'] as int;

        // Query stats langsung dari DatabaseHelper — ini yang fix masalahnya
        final results = await Future.wait([
          _db.getTotalTempat(sqliteUserId),
          _db.getTotalUlasan(sqliteUserId),
          _db.getTotalArtikelDibaca(sqliteUserId),
        ]);

        totalTempat = results[0];
        totalUlasan = results[1];
        totalArtikel = results[2];
      }
    }

    if (user != null) {
      final xp = (user['xp'] as num? ?? 0).toInt();
      final correctLevel = _levelFromXp(xp);
      final storedLevel = (user['level'] as num? ?? 1).toInt();

      if (storedLevel != correctLevel) {
        await FirestoreService.updateUser(_uid, {
          'level': correctLevel,
          'level_name': _levelNameFromLevel(correctLevel),
        });
        final correctedUser = await FirestoreService.getUser(_uid);
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
    final remaining = _xpNeeded(level) - xp;
    return remaining < 0 ? 0 : remaining;
  }

  Widget _buildAvatarWidget() {
    final imagePath = _user?['image_path'] as String?;
    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultAvatarImage(),
      );
    }
    return _buildDefaultAvatarImage();
  }

  Widget _buildDefaultAvatarImage() {
    return Image.asset(
      'assets/images/mascot/timo_9.jpg',
      fit: BoxFit.cover,
    );
  }

  Future<void> _showPhotoOptions() async {
    final hasCustomPhoto = _user?['image_path'] != null &&
        (_user!['image_path'] as String).isNotEmpty;

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
              if (hasCustomPhoto) ...[
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
                  subtitle: const Text('Kembali ke avatar default Timo',
                      style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
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
      await FirestoreService.updateImagePath(_uid, picked.path);
      await _load();
      if (mounted) _showSnackBar('Foto profil berhasil diperbarui! 📸');
    } catch (e) {
      if (mounted) _showSnackBar('Gagal memilih foto. Coba lagi.', isError: true);
    }
  }

  Future<void> _removePhoto() async {
    await FirestoreService.updateImagePath(_uid, null);
    await _load();
    if (mounted) _showSnackBar('Foto profil dihapus. Kembali ke Timo! 🐱');
  }

  void _showEditProfileDialog() {
    final usernameCtrl = TextEditingController(text: _user?['username'] as String? ?? '');
    final emailCtrl = TextEditingController(text: _user?['email'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profil',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF7924A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Username',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
            const SizedBox(height: 6),
            _buildDialogTextField(usernameCtrl, 'Masukkan username'),
            const SizedBox(height: 14),
            const Text('Email',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = usernameCtrl.text.trim();
              final newEmail = emailCtrl.text.trim();
              if (newUsername.isEmpty || newEmail.isEmpty) {
                _showSnackBar('Username dan email tidak boleh kosong.', isError: true);
                return;
              }
              if (!newEmail.contains('@')) {
                _showSnackBar('Format email tidak valid.', isError: true);
                return;
              }
              try {
                await FirestoreService.updateUsernameEmail(_uid, newUsername, newEmail);
                final currentEmail = AuthService.currentUser?.email ?? '';
                if (newEmail != currentEmail) {
                  await AuthService.updateEmail(newEmail);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
                if (mounted) _showSnackBar('Profil berhasil diperbarui! ✅');
              } catch (e) {
                if (mounted) {
                  _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7924A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
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
        fillColor: const Color(0xFFFFF1E7),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF7924A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF7924A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Ubah Kata Sandi',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF7924A))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(oldCtrl, 'Kata sandi lama',
                    obscure: obscureOld,
                    onToggle: () => setDialogState(() => obscureOld = !obscureOld)),
                const SizedBox(height: 10),
                _buildField(newCtrl, 'Kata sandi baru',
                    obscure: obscureNew,
                    onToggle: () => setDialogState(() => obscureNew = !obscureNew)),
                const SizedBox(height: 10),
                _buildField(confirmCtrl, 'Konfirmasi kata sandi baru',
                    obscure: obscureConfirm,
                    onToggle: () => setDialogState(() => obscureConfirm = !obscureConfirm)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showForgotPasswordDialog();
                    },
                    child: const Text('Lupa kata sandi?',
                        style: TextStyle(fontSize: 13, color: Color(0xFFF7924A), fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (newCtrl.text != confirmCtrl.text) {
                    _showSnackBar('Konfirmasi kata sandi tidak cocok!', isError: true);
                    return;
                  }
                  if (newCtrl.text.length < 6) {
                    _showSnackBar('Kata sandi baru minimal 6 karakter.', isError: true);
                    return;
                  }
                  final ok = await AuthService.changePassword(
                    oldPassword: oldCtrl.text,
                    newPassword: newCtrl.text,
                  );
                  if (!ok) {
                    _showSnackBar('Kata sandi lama salah!', isError: true);
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) _showSnackBar('Kata sandi berhasil diubah! 🔐');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7924A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFFF1E7),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF7924A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF7924A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFFF7924A), size: 18),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _user?['email'] as String? ?? '');
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Reset Kata Sandi',
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF7924A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kami akan mengirim link reset kata sandi ke email kamu.',
                style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
              ),
              const SizedBox(height: 14),
              const Text('Email',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
              const SizedBox(height: 6),
              _buildField(emailCtrl, 'Masukkan email',
                  keyboardType: TextInputType.emailAddress),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: isSending ? null : () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        _showSnackBar('Masukkan email yang valid.', isError: true);
                        return;
                      }
                      setDialogState(() => isSending = true);
                      try {
                        await AuthService.sendPasswordResetEmail(email);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          _showSnackBar('Link reset dikirim ke $email 📧');
                        }
                      } catch (e) {
                        setDialogState(() => isSending = false);
                        if (mounted) {
                          _showSnackBar(
                            'Gagal mengirim email. Periksa kembali alamat email.',
                            isError: true,
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7924A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Kirim Link', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

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
                const Text('Semua Pencapaian',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Text('${_badges.length} badge diraih',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF777777))),
                const SizedBox(height: 16),
                Expanded(
                  child: _badges.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🏅', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text('Belum ada badge.\nSelesaikan misi untuk mendapatkannya!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          controller: scrollCtrl,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _badges.length,
                          itemBuilder: (_, i) => _buildBadgeGridItem(_badges[i]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Akun',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        content: Text('Yakin mau keluar dari akun ${_user?['username'] ?? 'ini'}?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Color(0xFF555555))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Batal',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Keluar',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFFF4444) : const Color(0xFFF7924A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF7924A))),
      );
    }

    final int xp = (_user?['xp'] as num? ?? 0).toInt();
    final String username = _user?['username'] as String? ?? 'Timo';
    final String email = _user?['email'] as String? ?? '';

    final int level = _levelFromXp(xp);
    final String levelName = _levelNameFromLevel(level);
    final int xpNeeded = _xpNeeded(level);
    final int xpKurang = _xpToNextLevel(xp, level);
    final double progress = _calcProgress(xp, level);

    final badgePreview = _badges.take(3).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFFF7924A),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Profil',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFF7924A))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                          border: Border.all(color: const Color(0xFFF7924A), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF7924A).withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(borderRadius: BorderRadius.circular(50), child: _buildAvatarWidget()),
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
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                GestureDetector(
                  onTap: _showEditProfileDialog,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(username,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_rounded, size: 16, color: Color(0xFFCCCCCC)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                GestureDetector(
                  onTap: _showEditProfileDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFBD2B6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(email,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF555555))),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_rounded, size: 13, color: Color(0xFFF7924A)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Level $level · $levelName',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A2E))),
                            Text('$xp XP',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFFF7924A))),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          level < 5
                              ? '$xp XP di level ini · kurang $xpKurang XP ke level berikutnya'
                              : '$xp XP · Level Maksimum 🎉',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9E9E9E)),
                        ),
                        const SizedBox(height: 10),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder: (ctx, val, _) => Stack(
                            children: [
                              Container(
                                height: 12,
                                width: double.infinity,
                                decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(99)),
                              ),
                              FractionallySizedBox(
                                widthFactor: val,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(color: const Color(0xFFF7924A), borderRadius: BorderRadius.circular(99)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$xp / $xpNeeded XP',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF7924A))),
                            Text(level < 5 ? 'Menuju ${_levelNameFromLevel(level + 1)}' : 'Level Maksimum! 🎉',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionHeader('Keamanan Akun'),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _showChangePasswordDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(color: const Color(0xFFFFF3EC), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFFF7924A)),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ubah Kata Sandi',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
                                SizedBox(height: 2),
                                Text('Ubah atau reset kata sandi akunmu',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC), size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionHeader(
                  'Pencapaian',
                  trailing: GestureDetector(
                    onTap: _showAllBadgesSheet,
                    child: const Text('Lihat Semua',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF7924A))),
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
                            border: Border.all(color: const Color(0xFFFBD2B6)),
                          ),
                          child: Column(
                            children: [
                              const Text('🏅', style: TextStyle(fontSize: 36)),
                              const SizedBox(height: 8),
                              Text('Belum ada badge. Selesaikan misi!',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                            ],
                          ),
                        )
                      : Row(
                          children: List.generate(
                            badgePreview.length.clamp(0, 3),
                            (i) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: i < badgePreview.length - 1 ? 12 : 0),
                                child: _buildBadgeCard(badgePreview[i]),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),

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
                        border: Border.all(color: const Color(0xFFF7924A), width: 1.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Color(0xFFF7924A), size: 18),
                          SizedBox(width: 8),
                          Text('Keluar Akun',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFFF7924A))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(badge['badge_icon'] ?? '🏅', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(badge['badge_name'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(badge['deskripsi'] ?? '',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
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
                child: Text(badge['badge_icon'] ?? '🏅', style: const TextStyle(fontSize: 26)),
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
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
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
              child: Text(badge['badge_icon'] ?? '🏅', style: const TextStyle(fontSize: 26)),
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
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
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
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}