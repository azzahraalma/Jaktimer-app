import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/xp_popup.dart';
import 'jelajah_kuliner.dart';
import 'jelajah_ruang.dart';

class DailyCheckinScreen extends StatefulWidget {
  final VoidCallback? onSwitchToUlik;

  const DailyCheckinScreen({
    super.key,
    this.onSwitchToUlik,
  });

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  String get _uid => AuthService.currentUid ?? '';

  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _weeklyCheckin = [];
  Map<String, bool> _misiStatus = {};
  bool _isLoading = true;
  bool _showXpPopup = false;
  int _popupXp = 0;
  String _popupLabel = '';

  static const Map<String, int> _misiXp = {
    'kuis_artikel': 50,
    'baca_artikel': 50,
    'tambah_review_kuliner': 70,
    'tambah_review_ruang': 70,
    'tambah_kuliner': 100,
    'tambah_ruang': 100,
  };

  static const List<int> _xpPerHari = [10, 15, 20, 25, 30, 35, 50];

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
      case 5: return 'Penakluk';
      case 4: return 'Penjelajah Sejati';
      case 3: return 'Penjelajah';
      case 2: return 'Explorer Sejati';
      default: return 'Explorer Muda';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playXpSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sound/notification.mp3'));
    } catch (_) {}
  }

  Future<void> _load() async {
    if (_uid.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        FirestoreService.getUser(_uid),
        FirestoreService.getWeeklyCheckin(_uid),
        FirestoreService.getMisiSelesaiHariIni(_uid),
      ]);

      final user = results[0] as Map<String, dynamic>?;
      final weekly = results[1] as List<Map<String, dynamic>>;
      final misiSelesai = results[2] as List<String>;

      final Map<String, bool> status = {};
      for (final kode in _misiXp.keys) {
        status[kode] = misiSelesai.contains(kode);
      }

      if (!status['kuis_artikel']!) {
        final kuisDone = await FirestoreService.hasKuisHarianSelesaiHariIni(_uid);
        if (kuisDone) {
          await FirestoreService.completeMisi(_uid, 'kuis_artikel');
          status['kuis_artikel'] = true;
        }
      }
      if (!status['baca_artikel']!) {
        final artikelDone = await FirestoreService.hasArtikelXpClaimed(_uid);
        if (artikelDone) {
          await FirestoreService.completeMisi(_uid, 'baca_artikel');
          status['baca_artikel'] = true;
        }
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _weeklyCheckin = weekly;
        _misiStatus = status;
        _isLoading = false;
      });
    } catch (error) {
      print('DailyCheckinScreen._load failed: $error');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat memuat data harian. Coba lagi nanti.')),
      );
    }
  }

  Future<void> _handleCheckin() async {
    if (_uid.isEmpty) return;

    try {
      final success = await FirestoreService.dailyCheckin(_uid);
      if (success) {
        await _load();
        final streak = await FirestoreService.getCurrentStreak(_uid);
        final xp = _xpForStreak(streak);
        _showXp(xp, 'Daily Check-in! 📅');
      }
    } catch (error) {
      print('DailyCheckinScreen._handleCheckin failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in gagal. Periksa koneksi dan coba lagi.')),
      );
    }
  }

  int _xpForStreak(int streak) {
    if (streak <= 0) return _xpPerHari[0];
    if (streak <= _xpPerHari.length) return _xpPerHari[streak - 1];
    return _xpPerHari.last;
  }

  void _showXp(int xp, String label) {
    _playXpSound();
    setState(() {
      _popupXp = xp;
      _popupLabel = label;
      _showXpPopup = true;
    });
  }

  Future<void> _completeMisi(String kode, int xp) async {
    final alreadyDone = _misiStatus[kode] ?? false;
    if (alreadyDone || _uid.isEmpty) return;

    final success = await FirestoreService.completeMisi(_uid, kode);
    if (success) {
      await FirestoreService.addXp(_uid, xp, keterangan: 'Misi: $kode');
      setState(() => _misiStatus[kode] = true);
      _showXp(xp, _misiLabel(kode));
    }
  }

  String _misiLabel(String kode) {
    switch (kode) {
      case 'kuis_artikel': return 'Kerjakan kuis di artikel';
      case 'baca_artikel': return 'Baca artikel hari ini';
      case 'tambah_review_kuliner': return 'Tambah review kuliner';
      case 'tambah_review_ruang': return 'Tambah review ruang terbuka';
      case 'tambah_kuliner': return 'Tambahkan tempat kuliner baru';
      case 'tambah_ruang': return 'Tambahkan ruang terbuka baru';
      default: return kode;
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
    final remaining = _xpNeeded(level) - xp;
    return remaining < 0 ? 0 : remaining;
  }

  static const List<String> _dayOrder = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

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

  String _todayLabel() {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[DateTime.now().weekday - 1];
  }

  bool _hasCheckedInToday() {
    final label = _todayLabel();
    final today = _weeklyCheckin.firstWhere(
      (d) => d['day'] == label,
      orElse: () => {'checked': false},
    );
    return today['checked'] as bool;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF7924A))),
      );
    }

    final int xp = (_user?['xp'] as num? ?? 0).toInt();
    final int level = _levelFromXp(xp);
    final String levelName = _levelNameFromLevel(level);
    final String username = _user?['username'] as String? ?? 'User';
    final int xpNeeded = _xpNeeded(level);
    final double progress = _calcProgress(xp, level);
    final int xpKurang = _xpToNextLevel(xp, level);

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
                          username: username,
                          level: level,
                          levelName: levelName,
                          xp: xp,
                          xpNeeded: xpNeeded,
                          progress: progress,
                          xpKurang: xpKurang,
                        ),
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

  Widget _buildTimoCard({
    required String username,
    required int level,
    required String levelName,
    required int xp,
    required int xpNeeded,
    required double progress,
    required int xpKurang,
  }) {

  final String mascotAsset;
  switch (level) {
    case 5:
      mascotAsset = 'assets/images/mascot/timo_4.png';
      break;
    case 4:
      mascotAsset = 'assets/images/mascot/timo_3.png';
      break;
    case 3:
      mascotAsset = 'assets/images/mascot/timo_2.png';
      break;
    case 2:
      mascotAsset = 'assets/images/mascot/timo_5.png';
      break;
    default:
      mascotAsset = 'assets/images/mascot/timo_6.png';
  }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                mascotAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF7924A),
                  child: const Icon(Icons.catching_pokemon_rounded,
                      size: 52, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Si Timo',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFFF7924A))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFBD2B6)),
                ),
                child: Text('Lv.$level',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF7924A))),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Level $level · $levelName',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1A1A2E))),
                    Text('$xp XP',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFFF7924A))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  level < 5
                      ? '$xp XP di level ini · kurang $xpKurang XP ke level berikutnya'
                      : '$xp XP · Level Maksimum 🎉',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => Stack(
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(99)),
                      ),
                      FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF7924A),
                              borderRadius: BorderRadius.circular(99)),
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
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF7924A))),
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
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Minggu Ini',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: Color(0xFF1A1A2E))),
                Row(
                  children: [
                    Text('Hari ini: +$_xpHariIni XP',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFFF7924A))),
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
                    child: const Text('Masuk Hari Ini',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayItem({
    required String dayLabel,
    required bool checked,
    required bool isToday,
    required int xpHari,
  }) {
    return Column(
      children: [
        Text(dayLabel,
            style: TextStyle(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                fontSize: 12,
                color: isToday
                    ? const Color(0xFFF7924A)
                    : const Color(0xFF000000))),
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
              : Icon(Icons.star_outline_rounded,
                  color: isToday
                      ? const Color(0xFFF7924A)
                      : const Color(0xFF686868),
                  size: isToday ? 22 : 18),
        ),
        const SizedBox(height: 4),
        Text('+$xpHari',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: checked
                    ? const Color(0xFFF7924A)
                    : isToday
                        ? const Color(0xFFF7924A)
                        : const Color(0xFFB0B0B0))),
        Text('XP',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: checked
                    ? const Color(0xFFF7924A)
                    : isToday
                        ? const Color(0xFFF7924A)
                        : const Color(0xFFB0B0B0))),
      ],
    );
  }

  Widget _buildMisiSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Misi Hari Ini',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: Color(0xFF1A1A2E))),
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
                    onMisiSelesai: () async {
                      await _completeMisi('tambah_review_kuliner', 70);
                    },
                  ),
                ),
              );
              await _load();
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
                    onMisiSelesai: () async {
                      await _completeMisi('tambah_review_ruang', 70);
                    },
                  ),
                ),
              );
              await _load();
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
                    openAddForm: true,
                    onMisiSelesai: () async {
                      await _completeMisi('tambah_kuliner', 100);
                    },
                  ),
                ),
              );
              await _load();
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
                    openAddForm: true,
                    onMisiSelesai: () async {
                      await _completeMisi('tambah_ruang', 100);
                    },
                  ),
                ),
              );
              await _load();
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
            color: const Color(0xFFF7924A).withOpacity(0.4), width: 1.5),
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
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: done
                            ? Colors.grey[500]
                            : const Color(0xFF1A1A2E),
                        decoration: done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none)),
                const SizedBox(height: 2),
                Text('+$xp XP',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: done
                            ? Colors.grey[400]
                            : const Color(0xFFF7924A))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Selesai ✓',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF4CAF50))),
            )
          else
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFF7924A),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(buttonLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}