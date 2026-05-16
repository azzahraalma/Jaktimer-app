import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/database_helper.dart';
import '../helper/badge_helper.dart';
import '../widgets/xp_popup.dart';
import '../widgets/badge_popup.dart';
import 'jelajah_kuliner.dart';
import 'jelajah_ruang.dart';

class DailyCheckinScreen extends StatefulWidget {
  final int userId;
  final VoidCallback? onSwitchToUlik;

  const DailyCheckinScreen({
    super.key,
    required this.userId,
    this.onSwitchToUlik,
  });

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _weeklyCheckin = [];
  Map<String, bool> _misiStatus = {};
  bool _isLoading = true;
  bool _showXpPopup = false;
  int _popupXp = 0;
  String _popupLabel = '';

  // Badge popup queue
  final List<Map<String, String>> _pendingBadges = [];
  bool _showingBadge = false;

  static const Map<String, int> _misiXp = {
    'kuis_artikel': 50,
    'baca_artikel': 50,
    'tambah_review_kuliner': 70,
    'tambah_review_ruang': 70,
    'tambah_kuliner': 100,
    'tambah_ruang': 100,
  };

  // XP per hari ke-1..7 dalam streak minggu ini
  static const List<int> _xpPerHari = [10, 15, 20, 25, 30, 35, 50];

  // ── Level & XP thresholds — HARUS IDENTIK dengan profile_screen.dart ────
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

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}_${now.month}_${now.day}';
  }

  String get _keyKuisResult => 'quiz_result_${widget.userId}_$_todayKey';
  String get _keyArtikelXp => 'artikel_xp_${widget.userId}_$_todayKey';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final user = await _db.getUserById(widget.userId);
    final weekly = await _db.getWeeklyCheckin(widget.userId);
    final Map<String, bool> status = {};

    for (final kode in _misiXp.keys) {
      bool done = await _db.isMisiCompleted(widget.userId, kode);

      if (!done && kode == 'kuis_artikel') {
        final prefs = await SharedPreferences.getInstance();
        final savedResult = prefs.getString(_keyKuisResult);
        if (savedResult != null && savedResult.isNotEmpty) {
          await _completeMisiSilent('kuis_artikel', _misiXp['kuis_artikel']!);
          done = true;
        }
      }

      if (!done && kode == 'baca_artikel') {
        final prefs = await SharedPreferences.getInstance();
        final artikelClaimed = prefs.getBool(_keyArtikelXp) ?? false;
        if (artikelClaimed) {
          await _completeMisiSilent('baca_artikel', _misiXp['baca_artikel']!);
          done = true;
        }
      }

      status[kode] = done;
    }

    setState(() {
      _user = user;
      _weeklyCheckin = weekly;
      _misiStatus = status;
      _isLoading = false;
    });
  }

  Future<void> _completeMisiSilent(String kode, int xp) async {
    await _db.completeMisi(widget.userId, kode);
  }

  // ── Badge popup queue management ─────────────────────────────────────────
  void _enqueueBadges(List<Map<String, String>> badges) {
    _pendingBadges.addAll(badges);
    if (!_showingBadge) _showNextBadge();
  }

  void _showNextBadge() {
    if (_pendingBadges.isEmpty) {
      setState(() => _showingBadge = false);
      return;
    }
    setState(() => _showingBadge = true);
    final badge = _pendingBadges.removeAt(0);
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 120,
        left: 0,
        right: 0,
        child: Center(
          child: BadgePopup(
            badgeName: badge['name'] ?? '',
            badgeIcon: badge['icon'] ?? '🏅',
            deskripsi: badge['deskripsi'] ?? '',
            onDismiss: () {
              entry.remove();
              Future.delayed(const Duration(milliseconds: 400), () {
                _showNextBadge();
              });
            },
          ),
        ),
      ),
    );
    overlay.insert(entry);
  }

  Future<void> _handleCheckin() async {
    final success = await _db.dailyCheckin(widget.userId);
    if (success) {
      await _load();
      final streak = await _db.getCurrentStreak(widget.userId);
      final xp = _db.xpForStreak(streak);
      _showXp(xp, 'Daily Check-in!');

      final newBadges = await BadgeHelper.checkAndAwardBadges(widget.userId);
      if (newBadges.isNotEmpty) {
        Future.delayed(const Duration(seconds: 2), () {
          _enqueueBadges(newBadges);
        });
      }
    }
  }

  void _showXp(int xp, String label) {
    setState(() {
      _popupXp = xp;
      _popupLabel = label;
      _showXpPopup = true;
    });
  }

  Future<void> _completeMisi(String kode, int xp) async {
    final alreadyDone = _misiStatus[kode] ?? false;
    if (alreadyDone) return;

    final success = await _db.completeMisi(widget.userId, kode);
    if (success) {
      await _db.updateUserXp(widget.userId, xp);
      await _db.logXp(widget.userId, xp, 'Misi: $kode');
      setState(() => _misiStatus[kode] = true);
      _showXp(xp, _misiLabel(kode));

      final newBadges = await BadgeHelper.checkAndAwardBadges(widget.userId);
      if (newBadges.isNotEmpty) {
        Future.delayed(const Duration(seconds: 2), () {
          _enqueueBadges(newBadges);
        });
      }
    }
  }

  String _misiLabel(String kode) {
    switch (kode) {
      case 'kuis_artikel':
        return 'Kerjakan kuis di artikel';
      case 'baca_artikel':
        return 'Baca artikel hari ini';
      case 'tambah_review_kuliner':
        return 'Tambah review kuliner';
      case 'tambah_review_ruang':
        return 'Tambah review ruang terbuka';
      case 'tambah_kuliner':
        return 'Tambahkan tempat kuliner baru';
      case 'tambah_ruang':
        return 'Tambahkan ruang terbuka baru';
      default:
        return kode;
    }
  }

  int get _xpHariIni {
    int total = 0;
    _misiStatus.forEach((kode, done) {
      if (done) total += (_misiXp[kode] ?? 0);
    });
    final todayLabel = _todayLabel();
    final todayRow = _weeklyCheckin.firstWhere(
      (d) => d['day'] == todayLabel,
      orElse: () => {'checked': false, 'xp': 0},
    );
    if (todayRow['checked'] == true) {
      total += todayRow['xp'] as int;
    }
    return total;
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
    final nextThreshold = _xpNeeded(level);
    final remaining = nextThreshold - xp;
    return remaining < 0 ? 0 : remaining;
  }

  static const List<String> _dayOrder = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'
  ];

  int _hariKeBerapa(String dayLabel) {
    int firstCheckedIdx = -1;
    for (int i = 0; i < _dayOrder.length; i++) {
      final row = _weeklyCheckin.firstWhere(
        (d) => d['day'] == _dayOrder[i],
        orElse: () => {'checked': false},
      );
      if (row['checked'] == true) {
        firstCheckedIdx = i;
        break;
      }
    }

    if (firstCheckedIdx == -1) {
      final todayIdx = _dayOrder.indexOf(_todayLabel());
      final targetIdx = _dayOrder.indexOf(dayLabel);
      if (todayIdx == -1 || targetIdx == -1) return 1;
      return (targetIdx - todayIdx + 7) % 7 + 1;
    }

    final targetIdx = _dayOrder.indexOf(dayLabel);
    if (targetIdx == -1) return 1;
    final diff = (targetIdx - firstCheckedIdx + 7) % 7;
    return diff + 1;
  }

  int _xpUntukHari(String dayLabel) {
    final hariKe = _hariKeBerapa(dayLabel).clamp(1, _xpPerHari.length);
    return _xpPerHari[hariKe - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFF7924A))),
      );
    }

    final xpRaw = _user?['xp'] as int? ?? 0;
    final int xp = xpRaw;
    final int level = _levelFromXp(xp);
    final String levelName = _levelNameFromLevel(level);
    final username = _user?['username'] as String? ?? 'User';
    final xpNeeded = _xpNeeded(level);
    final progress = _calcProgress(xp, level);
    final xpKurang = _xpToNextLevel(xp, level);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFFF7924A), size: 20),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Jelajah Bareng Timo',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: Color(0xFFF7924A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildTimoCard(
                            username, level, levelName, xp, xpNeeded, progress, xpKurang),
                        const SizedBox(height: 20),
                        _buildWeeklyCard(),
                        const SizedBox(height: 20),
                        _buildMisiSection(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showXpPopup)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: XpPopup(
                  xp: _popupXp,
                  label: _popupLabel,
                  onDismiss: () => setState(() => _showXpPopup = false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimoCard(String username, int level, String levelName, int xp,
      int xpNeeded, double progress, int xpKurang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF7924A).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'https://api.dicebear.com/7.x/bottts/png?seed=Timo&backgroundColor=b6e3f4',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFb6e3f4),
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Si Timo',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFFF7924A),
            ),
          ),
          const SizedBox(height: 16),

          // ── XP CARD — layout identik dengan profile_screen.dart ──
          Container(
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
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris atas: "Level X" (kiri, hitam) | "Nama Level" (kanan, orange)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      levelName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFFF7924A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Progress bar
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (context, value, _) {
                    return Stack(
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
                          widthFactor: value,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7924A),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Teks tengah bawah bar
                Center(
                  child: Text(
                    level < 5
                        ? '$xp / $xpNeeded XP ke Level ${level + 1}'
                        : '$xp XP · Level Maksimum 🎉',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF7924A)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Minggu Ini',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Hari ini: +${_xpHariIni} XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFFF7924A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.trending_up_rounded,
                        color: Color(0xFFF7924A), size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weeklyCheckin.map((day) {
                final bool checked = day['checked'] as bool;
                final String dayLabel = day['day'] as String;
                final bool isToday = dayLabel == _todayLabel();
                final int xpHari = _xpUntukHari(dayLabel);
                return _buildDayItem(
                  dayLabel: dayLabel,
                  checked: checked,
                  isToday: isToday,
                  xpHari: xpHari,
                );
              }).toList(),
            ),
            if (!_hasCheckedInToday())
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleCheckin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7924A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Masuk Hari Ini',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasCheckedInToday() {
    final label = _todayLabel();
    final today = _weeklyCheckin.firstWhere(
      (d) => d['day'] == label,
      orElse: () => {'checked': false},
    );
    return today['checked'] as bool;
  }

  String _todayLabel() {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[DateTime.now().weekday - 1];
  }

  Widget _buildDayItem({
    required String dayLabel,
    required bool checked,
    required bool isToday,
    required int xpHari,
  }) {
    return Column(
      children: [
        Text(
          dayLabel,
          style: TextStyle(
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
            fontSize: 12,
            color: isToday ? const Color(0xFFF7924A) : const Color(0xFF000000),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: checked
                ? const Color(0xFFF7924A)
                : isToday
                    ? const Color(0xFFF1F5FD)
                    : const Color(0xFFE3F3FF),
            shape: BoxShape.circle,
            border: isToday && !checked
                ? Border.all(color: const Color(0xFFF7924A), width: 2)
                : null,
          ),
          child: checked
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : Icon(
                  Icons.star_outline_rounded,
                  color: isToday
                      ? const Color(0xFFF7924A)
                      : const Color(0xFF686868),
                  size: isToday ? 22 : 18,
                ),
        ),
        const SizedBox(height: 4),
        Text(
          '+$xpHari',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: checked
                ? const Color(0xFFF7924A)
                : isToday
                    ? const Color(0xFFF7924A)
                    : const Color(0xFFB0B0B0),
          ),
        ),
        Text(
          'XP',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: checked
                ? const Color(0xFFF7924A)
                : isToday
                    ? const Color(0xFFF7924A)
                    : const Color(0xFFB0B0B0),
          ),
        ),
      ],
    );
  }

  Widget _buildMisiSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Misi Hari Ini',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),
          _buildMisiCard(
            icon: Icons.quiz_outlined,
            title: 'Kerjakan kuis di artikel',
            xp: 50,
            kode: 'kuis_artikel',
            buttonLabel: 'Mulai',
            onTap: () {
              Navigator.pop(context);
              widget.onSwitchToUlik?.call();
            },
          ),
          const SizedBox(height: 12),
          _buildMisiCard(
            icon: Icons.article_outlined,
            title: 'Baca artikel hari ini',
            xp: 50,
            kode: 'baca_artikel',
            buttonLabel: 'Buka',
            onTap: () {
              Navigator.pop(context);
              widget.onSwitchToUlik?.call();
            },
          ),
          const SizedBox(height: 12),
          _buildMisiCard(
            icon: Icons.rate_review_outlined,
            title: 'Tambah review kuliner',
            xp: 70,
            kode: 'tambah_review_kuliner',
            buttonLabel: 'Tulis',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JelajahKulinerScreen(
                    misiKode: 'tambah_review_kuliner',
                    userId: widget.userId,
                    onMisiSelesai: () async {
                      await _completeMisi('tambah_review_kuliner', 70);
                      await _load();
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMisiCard(
            icon: Icons.park_outlined,
            title: 'Tambah review ruang terbuka',
            xp: 70,
            kode: 'tambah_review_ruang',
            buttonLabel: 'Tulis',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JelajahRuangScreen(
                    misiKode: 'tambah_review_ruang',
                    userId: widget.userId,
                    onMisiSelesai: () async {
                      await _completeMisi('tambah_review_ruang', 70);
                      await _load();
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMisiCard(
            icon: Icons.add_location_alt_outlined,
            title: 'Tambahkan tempat kuliner baru',
            xp: 100,
            kode: 'tambah_kuliner',
            buttonLabel: 'Tambah',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JelajahKulinerScreen(
                    misiKode: 'tambah_kuliner',
                    userId: widget.userId,
                    openAddForm: true,
                    fromMisi: true,
                    onMisiSelesai: () async {
                      await _completeMisi('tambah_kuliner', 100);
                      await _load();
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMisiCard(
            icon: Icons.add_location_outlined,
            title: 'Tambahkan ruang terbuka baru',
            xp: 100,
            kode: 'tambah_ruang',
            buttonLabel: 'Tambah',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JelajahRuangScreen(
                    misiKode: 'tambah_ruang',
                    userId: widget.userId,
                    openAddForm: true,
                    fromMisi: true,
                    onMisiSelesai: () async {
                      await _completeMisi('tambah_ruang', 100);
                      await _load();
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMisiCard({
    required IconData icon,
    required String title,
    required int xp,
    required String kode,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    final bool done = _misiStatus[kode] ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFFFF8F5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF7924A).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: done
                  ? const Color(0xFFF7924A).withOpacity(0.15)
                  : const Color(0xFFFED5B9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              done ? Icons.check_circle_outline_rounded : icon,
              color: done ? Colors.white : const Color(0xFFF7924A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: done ? Colors.grey[500] : const Color(0xFF1A1A2E),
                    decoration:
                        done ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+$xp XP',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: done ? Colors.grey[400] : const Color(0xFFF7924A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Selesai ✓',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFF4CAF50),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7924A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}