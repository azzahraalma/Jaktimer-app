import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helper/database_helper.dart';
import '../helper/badge_helper.dart';
import '../widgets/badge_popup.dart';
import '../screens/ulasan_list.dart';
import '../widgets/xp_popup.dart';
import 'package:share_plus/share_plus.dart';

class KulinerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> kuliner;
  final double? distance;
  final Future<void> Function()? onReviewSubmitted;

  const KulinerDetailScreen({
    super.key,
    required this.kuliner,
    this.distance,
    this.onReviewSubmitted,
  });

  @override
  State<KulinerDetailScreen> createState() => _KulinerDetailScreenState();
}

class _KulinerDetailScreenState extends State<KulinerDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _ulasanController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _ulasanList = [];
  int _selectedRating = 0;
  bool _isSubmitting = false;
  bool _showXpPopup = false;

  static const Map<String, IconData> _fasilitasIconMap = {
    'Makan di Tempat': Icons.restaurant_rounded,
    'Delivery': Icons.delivery_dining_rounded,
    'Takeaway': Icons.takeout_dining_rounded,
    'Parkir': Icons.local_parking_rounded,
    'WiFi': Icons.wifi_rounded,
    'AC': Icons.ac_unit_rounded,
    'Outdoor': Icons.deck_rounded,
    'Live Music': Icons.music_note_rounded,
    'Toilet Umum': Icons.wc_rounded,
    'Area Bermain': Icons.toys_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadUlasan();
  }

  Future<void> _loadUlasan() async {
    final ulasan = await _db.getUlasan(widget.kuliner['id'], 'kuliner');
    setState(() => _ulasanList = ulasan);
  }

  // ── Badge: cek dan tampilkan via overlay ──────────────────────────────────
  Future<void> _checkAndShowBadges() async {
    final newBadges = await BadgeHelper.checkAndAwardBadges(1); // userId default 1
    if (newBadges.isEmpty || !mounted) return;

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _showBadgeQueue(newBadges);
    });
  }

  void _showBadgeQueue(List<Map<String, String>> badges) {
    if (badges.isEmpty || !mounted) return;
    final badge = badges.first;
    final rest = badges.sublist(1);

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
                _showBadgeQueue(rest);
              });
            },
          ),
        ),
      ),
    );
    overlay.insert(entry);
  }

  Future<void> _submitUlasan() async {
    if (_selectedRating == 0 || _ulasanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Isi rating dan komentar dulu ya!',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFF7924A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await _db.insertUlasan({
      'user_id': 1,
      'tempat_id': widget.kuliner['id'],
      'tipe': 'kuliner',
      'rating': _selectedRating,
      'komentar': _ulasanController.text.trim(),
      'username': 'Timo',
      'avatar_url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Timo',
    });

    if (widget.onReviewSubmitted != null) {
      await widget.onReviewSubmitted!();
    }

    // ── Cek badge ──────────────────────────────────────────────────────────
    await _checkAndShowBadges();

    setState(() => _showXpPopup = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showXpPopup = false);
    });

    _ulasanController.clear();
    setState(() {
      _selectedRating = 0;
      _isSubmitting = false;
    });

    await _loadUlasan();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Ulasan berhasil dikirim!',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFF7924A),
          behavior: SnackBarBehavior.floating,
          margin:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatHarga(int? min, int? max) {
    if (min == null && max == null) return 'N/A';
    String format(int n) {
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
      return n.toString();
    }

    if (min != null && max != null)
      return 'Rp ${format(min)} – ${format(max)}';
    if (min != null) return 'Rp ${format(min)}+';
    return 'Rp ${format(max!)}';
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays >= 7)
        return '${(diff.inDays / 7).floor()} minggu lalu';
      if (diff.inDays >= 1) return '${diff.inDays} hari lalu';
      if (diff.inHours >= 1) return '${diff.inHours} jam lalu';
      return 'Baru saja';
    } catch (_) {
      return '';
    }
  }

  List<String> _parseFasilitas(dynamic raw) {
    if (raw == null) return [];
    final str = raw.toString().trim();
    if (str.isEmpty) return [];
    return str
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _ulasanController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kuliner;
    final fasilitas = _parseFasilitas(k['fasilitas']);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        k['image_url'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFFFF3EC),
                          child: const Icon(Icons.restaurant_rounded,
                              color: Color(0xFFF7924A), size: 64),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color(0xCCFFFFFF),
                                Colors.transparent
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Color(0xFF1A1A2E)),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        Share.share('Yuk Jelajah Jakarta Timur Bareng si Timo!');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        k['nama'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A2E),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFB800), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${k['rating']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            ' (${k['jumlah_ulasan']}+ ulasan)',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF999999)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 15, color: Color(0xFF999999)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              k['alamat'] ?? '',
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF666666)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3EC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFBD2B6)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rentang Harga',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF999999),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatHarga(
                                      (k['harga_min'] as num?)?.toInt(),
                                      (k['harga_max'] as num?)?.toInt(),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFF7924A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _iconBox(Icons.restaurant_menu_rounded),
                                const SizedBox(width: 8),
                                _iconBox(Icons.delivery_dining_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (k['jam_buka'] != null && k['jam_tutup'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 15, color: Color(0xFFF7924A)),
                              const SizedBox(width: 6),
                              Text(
                                'Buka ${k['jam_buka']} – ${k['jam_tutup']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildOpenStatusBadge(
                                  k['jam_buka'], k['jam_tutup']),
                            ],
                          ),
                        ),
                      if (fasilitas.isNotEmpty) ...[
                        _buildSectionTitle('Fasilitas'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: fasilitas
                              .map((label) => _buildFasilitasBadge(label))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildSectionTitle('Tentang'),
                      const SizedBox(height: 10),
                      Text(
                        k['deskripsi'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555555),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Ulasan'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UlasanListScreen(
                                    tempatId: widget.kuliner['id'],
                                    tipe: 'kuliner',
                                    namaTempat:
                                        widget.kuliner['nama'] ?? '',
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Lihat Semua',
                              style: TextStyle(
                                color: Color(0xFFF7924A),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_ulasanList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Belum ada ulasan. Jadilah yang pertama!',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ..._ulasanList.take(2).map((u) => _buildUlasanItem(u)),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBD2B6),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF7924A)
                                  .withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tulis Ulasan Anda',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: List.generate(5, (i) {
                                return GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedRating = i + 1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: Icon(
                                      i < _selectedRating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: i < _selectedRating
                                          ? const Color(0xFFFFB800)
                                          : const Color(0xFFF7924A),
                                      size: 32,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFFBD2B6)),
                              ),
                              child: TextField(
                                controller: _ulasanController,
                                maxLines: 4,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1A1A2E)),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Bagaimana pengalaman Anda di sini?',
                                  hintStyle: TextStyle(
                                      color: Color(0xFFBBBBBB),
                                      fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isSubmitting ? null : _submitUlasan,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF7924A),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      const Color(0xFFF7924A)
                                          .withValues(alpha: 0.5),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Text(
                                        'Kirim Ulasan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                xp: 70,
                label: 'Misi Selesai!',
                onDismiss: () => setState(() => _showXpPopup = false),
              ),
            ),
          ),
      ],
    );
  }

  Widget _iconBox(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFF7924A), size: 20),
      );

  Widget _buildFasilitasBadge(String label) {
    final icon =
        _fasilitasIconMap[label] ?? Icons.check_circle_outline_rounded;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFFFBD2B6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFF7924A)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFF7924A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenStatusBadge(String jamBuka, String jamTutup) {
    final now = TimeOfDay.now();
    bool isOpen = false;
    try {
      final bukaParts = jamBuka.split(':');
      final tutupParts = jamTutup.split(':');
      final nowMinutes = now.hour * 60 + now.minute;
      final bukaMinutes =
          int.parse(bukaParts[0]) * 60 + int.parse(bukaParts[1]);
      final tutupMinutes =
          int.parse(tutupParts[0]) * 60 + int.parse(tutupParts[1]);
      isOpen = nowMinutes >= bukaMinutes && nowMinutes < tutupMinutes;
    } catch (_) {}
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen
            ? const Color(0xFFE8F8F0)
            : const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Buka' : 'Tutup',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isOpen
              ? const Color(0xFF2ECC71)
              : const Color(0xFFE74C3C),
        ),
      ),
    );
  }

  Widget _buildUlasanItem(Map<String, dynamic> u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFFBD2B6).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  u['avatar_url'] ??
                      'https://api.dicebear.com/7.x/adventurer/png?seed=User',
                ),
                onBackgroundImageError: (_, __) {},
                backgroundColor: const Color(0xFFFBD2B6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u['username'] ?? 'Anonim',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < (u['rating'] as num? ?? 0)
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFFFB800),
                          size: 13,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                _timeAgo(u['created_at']),
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF999999)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${u['komentar'] ?? ''}"',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555555),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}