import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../data/artikel.dart';
import '../data/kuis_harian.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/xp_popup.dart';
import 'artikel_detail_screen.dart';
import 'semua_artikel_screen.dart';
import '../widgets/badge_popup.dart';

class UlikScreen extends StatefulWidget {
  final Future<void> Function()? onArtikelSelesaiBaca;
  final Future<void> Function()? onKuisSelesai;

  const UlikScreen({
    super.key,
    this.onArtikelSelesaiBaca,
    this.onKuisSelesai,
  });

  @override
  State<UlikScreen> createState() => _UlikScreenState();
}

class _UlikScreenState extends State<UlikScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> _randomArtikel = [];
  Map<String, dynamic> _kuisHariIni = {};

  int? _selectedOption;
  bool _submitted = false;
  bool _isBenar = false;
  int _xpEarned = 0;

  bool _artikelXpClaimed = false;

  bool _showXpPopup = false; 
  String _xpLabel = '';

  bool _showBadgePopup = false;
  String _badgeName = '';
  String _badgeIcon = '';
  String _badgeDeskripsi = '';

  String get _uid => AuthService.currentUid ?? '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playRight() async {
    try {
      await _audioPlayer.play(AssetSource('sound/right.mp3'));
    } catch (e) {
      debugPrint('Audio right error: $e');
    }
  }

  Future<void> _playWrong() async {
    try {
      await _audioPlayer.play(AssetSource('sound/wrong.mp3'));
    } catch (e) {
      debugPrint('Audio wrong error: $e');
    }
  }

  Map<String, dynamic> _getKuisUntukUser(String uid) {
    final now = DateTime.now();
    final seed = uid.hashCode.abs() * 31 + now.year * 366 + now.month * 31 + now.day;
    final index = seed % kuisHarianData.length;
    return kuisHarianData[index];
  }

  void _pickRandomArtikel() {
    final list = List<Map<String, dynamic>>.from(artikelData);
    list.shuffle();
    _randomArtikel = list.take(4).toList();
  }

  Future<void> _loadAll() async {
    if (_uid.isEmpty) return;

    final kuis = _getKuisUntukUser(_uid);
    final savedResult = await FirestoreService.getHasilKuisHarianHariIni(_uid);
    final artikelClaimed = await FirestoreService.hasArtikelXpClaimed(_uid);

    int? selectedOption;
    bool submitted = false;
    bool isBenar = false;
    int xpEarned = 0;

    if (savedResult != null) {
      selectedOption = savedResult['jawaban_index'] as int?;
      isBenar = savedResult['is_benar'] as bool? ?? false;
      xpEarned = savedResult['xp_earned'] as int? ?? 0;
      submitted = true;
    }

    _pickRandomArtikel();

    if (!mounted) return;
    setState(() {
      _kuisHariIni = kuis;
      _submitted = submitted;
      _selectedOption = selectedOption;
      _isBenar = isBenar;
      _xpEarned = xpEarned;
      _artikelXpClaimed = artikelClaimed;
    });
  }

  void _showXpPopupWithDelay(int xp, String label) {
    setState(() {
      _xpEarned = xp;
      _xpLabel = label;
      _showXpPopup = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showXpPopup = false);
      }
    });
  }

  void _showBadge(String name, String icon, String deskripsi) {
    setState(() {
      _badgeName = name;
      _badgeIcon = icon;
      _badgeDeskripsi = deskripsi;
      _showBadgePopup = true;
    });
  }

  Future<void> _submitKuis() async {
    if (_selectedOption == null || _submitted || _uid.isEmpty) return;

    final jawabanBenar = _kuisHariIni['jawaban_benar'] as int;
    final benar = _selectedOption == jawabanBenar;
    final kuisId = _kuisHariIni['id'] as int? ?? 0;

    final xp = await FirestoreService.saveKuisHarianResult(
      uid: _uid,
      kuisId: kuisId,
      jawabanIndex: _selectedOption!,
      isBenar: benar,
    );

    if (xp == 0 && !_submitted) {
      await _loadAll();
      return;
    }

    if (benar) {
      await _playRight();
    } else {
      await _playWrong();
    }

    _showXpPopupWithDelay(
      xp,
      benar ? 'Kuis Harian Benar! 🎉' : 'Tetap semangat belajar!',
    );

    if (benar) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          _showBadge('Kuiz Master', '🧠', 'Kamu menjawab kuis harian dengan benar!');
        }
      });
    }

    setState(() {
      _submitted = true;
      _isBenar = benar;
    });

    if (widget.onKuisSelesai != null) {
      await widget.onKuisSelesai!();
    }
  }

  Future<void> _openArtikel(Map<String, dynamic> artikel) async {
    if (!_artikelXpClaimed && _uid.isNotEmpty) {
      await FirestoreService.claimArtikelXp(_uid);

      if (widget.onArtikelSelesaiBaca != null) {
        await widget.onArtikelSelesaiBaca!();
      }

      if (mounted) {
        _showXpPopupWithDelay(50, 'Baca Artikel! 📖');

        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) {
            _showBadge('Pembaca Setia', '📖', 'Kamu sudah baca artikel hari ini!');
          }
        });

        setState(() {
          _artikelXpClaimed = true;
        });
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArtikelDetailScreen(artikel: artikel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: const Text(
                    'Kita Ulik Yok! ',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF7924A),
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.74,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ArtikelGridCard(
                      artikel: _randomArtikel[index],
                      onTap: () => _openArtikel(_randomArtikel[index]),
                    ),
                    childCount: _randomArtikel.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SemuaArtikelScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7924A),
                        borderRadius: BorderRadius.circular(90),
                      ),
                      child: const Text(
                        'Ulik Semua Artikel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildKuisHarian(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          if (_showXpPopup)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: XpPopup(
                  xp: _xpEarned,
                  label: _xpLabel,
                  onDismiss: () => setState(() => _showXpPopup = false),
                ),
              ),
            ),
          if (_showBadgePopup)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: BadgePopup(
                  badgeName: _badgeName,
                  badgeIcon: _badgeIcon,
                  deskripsi: _badgeDeskripsi,
                  onDismiss: () => setState(() => _showBadgePopup = false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKuisHarian() {
    final kuis = _kuisHariIni;
    if (kuis.isEmpty) return const SizedBox.shrink();

    final List<String> pilihan = List<String>.from(kuis['pilihan'] as List);
    final int jawabanBenar = kuis['jawaban_benar'] as int;
    final String penjelasan = kuis['penjelasan'] as String? ?? '';
    final xpBadgeLabel = _submitted ? '+$_xpEarned XP' : '+50 XP';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFED5B9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Kuis Harian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Uji pengetahuanmu tentang Jakarta Timur!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9B7B4E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Container(
                    key: ValueKey(xpBadgeLabel),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 3),
                        Text(
                          xpBadgeLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF7924A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kuis['pertanyaan'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(pilihan.length, (i) {
                  final isSelected = _selectedOption == i;
                  final isCorrect = i == jawabanBenar;

                  Color bgColor = Colors.white;
                  Color borderColor = const Color(0xFFE8E8E8);
                  Color textColor = const Color(0xFF333333);
                  Color circleColor = const Color(0xFFFAE5D3);
                  Color circleTextColor = const Color(0xFFE8803A);

                  if (_submitted) {
                    if (isCorrect) {
                      bgColor = const Color(0xFFF0FBF4);
                      borderColor = const Color(0xFF27AE60);
                      textColor = const Color(0xFF1E8449);
                      circleColor = const Color(0xFF27AE60);
                      circleTextColor = Colors.white;
                    } else if (isSelected && !isCorrect) {
                      bgColor = const Color(0xFFFEF0EF);
                      borderColor = const Color(0xFFE74C3C);
                      textColor = const Color(0xFFC0392B);
                      circleColor = const Color(0xFFE74C3C);
                      circleTextColor = Colors.white;
                    }
                  } else if (isSelected) {
                    bgColor = const Color(0xFFFFF3EC);
                    borderColor = const Color(0xFFF7924A);
                    textColor = const Color(0xFF7A3B10);
                    circleColor = const Color(0xFFF7924A);
                    circleTextColor = Colors.white;
                  }

                  return GestureDetector(
                    onTap: _submitted ? null : () => setState(() => _selectedOption = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: circleColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                ['A', 'B', 'C', 'D'][i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: circleTextColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pilihan[i],
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (_submitted && isCorrect)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF27AE60), size: 18),
                          if (_submitted && isSelected && !isCorrect)
                            const Icon(Icons.cancel_rounded,
                                color: Color(0xFFE74C3C), size: 18),
                        ],
                      ),
                    ),
                  );
                }),
                if (_submitted && penjelasan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2A6496).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 14, color: Color(0xFF2A6496)),
                            SizedBox(width: 5),
                            Text(
                              'Tahukah kamu?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A3C5E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          penjelasan,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF444444),
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else
                  const SizedBox(height: 4),
                if (!_submitted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedOption != null ? _submitKuis : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF7924A),
                        disabledBackgroundColor:
                            const Color(0xFFF7924A).withOpacity(0.35),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Jawab',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAE5D3).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _isBenar
                            ? 'Kuis sudah selesai hari ini 🎯'
                            : 'Kuis sudah selesai hari ini — coba lagi besok!',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B6914),
                        ),
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
}

class _ArtikelGridCard extends StatelessWidget {
  final Map<String, dynamic> artikel;
  final VoidCallback onTap;

  const _ArtikelGridCard({required this.artikel, required this.onTap});

  Color _kategoriColor(String kategori) {
    switch (kategori) {
      case 'KULINER':
        return const Color(0xFFE67E22);
      case 'SENI':
        return const Color(0xFF8E44AD);
      case 'SEJARAH':
        return const Color(0xFF27AE60);
      case 'TRADISI':
        return const Color(0xFFE8A020);
      default:
        return const Color(0xFF2A6496);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategori = artikel['kategori'] as String? ?? '';
    final color = _kategoriColor(kategori);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF7924A).withOpacity(0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Stack(
                children: [
                  Image.asset(
                    artikel['image_asset'] as String? ?? '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: const Color(0xFFFFF3EC),
                      child: const Icon(
                        Icons.article_outlined,
                        color: Color(0xFFF7924A),
                        size: 36,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        kategori,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artikel['judul'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (artikel['ringkasan'] != null)
                      Text(
                        artikel['ringkasan'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                    const Spacer(),
                    const Row(
                      children: [
                        Text(
                          'Baca selengkapnya',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF7924A),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Color(0xFFF7924A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}