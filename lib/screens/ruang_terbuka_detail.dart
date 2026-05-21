import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helper/database_helper.dart';
import '../helper/badge_helper.dart';
import '../widgets/badge_popup.dart';
import '../screens/ulasan_list.dart';
import '../widgets/xp_popup.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'package:share_plus/share_plus.dart';

class RuangDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ruang;
  final double? distance;
  final VoidCallback? onReviewSubmitted;

  const RuangDetailScreen({
    super.key,
    required this.ruang,
    this.distance,
    this.onReviewSubmitted,
  });

  @override
  State<RuangDetailScreen> createState() => _RuangDetailScreenState();
}

class _RuangDetailScreenState extends State<RuangDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _ulasanController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _ulasanList = [];
  int _selectedRating = 0;
  bool _isSubmitting = false;
  bool _showXpPopup = false;

  @override
  void initState() {
    super.initState();
    _loadUlasan();
  }

  Future<void> _loadUlasan() async {
    final ulasan = await _db.getUlasanByRuangId(widget.ruang['id']);
    setState(() => _ulasanList = ulasan);
  }

  void _showXp() {
    setState(() => _showXpPopup = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showXpPopup = false);
    });
  }

  Future<void> _checkAndShowBadges() async {
    final userId = AuthService.currentUid;
    if (userId == null) return;
    
    final newBadges = await BadgeHelper.checkAndAwardBadges(userId);
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
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = AuthService.currentUid;
      String username = '';
      String avatarUrl = '';

      if (userId != null) {
        final userData = await FirestoreService.getUser(userId);
        if (userData != null) {
          username = userData['username'] as String? ?? '';
          avatarUrl = userData['avatar_url'] as String? ?? 'https://api.dicebear.com/7.x/adventurer/png?seed=$username';
        }
      }

      if (username.isEmpty) username = 'User';

      await _db.insertUlasanRuang({
        'user_id': int.tryParse(userId ?? '1') ?? 1,
        'tempat_id': widget.ruang['id'],
        'rating': _selectedRating,
        'komentar': _ulasanController.text.trim(),
        'username': username,
        'avatar_url': avatarUrl,
      });

      if (userId != null) {
        try {
          final misiSelesai = await FirestoreService.getMisiSelesaiHariIni(userId);
          if (!misiSelesai.contains('tambah_review_ruang')) {
            await FirestoreService.completeMisi(userId, 'tambah_review_ruang');
            await FirestoreService.addXp(userId, 70, keterangan: 'Misi: tambah_review_ruang');
          }
        } catch (e) {
          print('Error Firestore: $e');
        }
      }

      if (widget.onReviewSubmitted != null) {
        widget.onReviewSubmitted!();
      }

      await _checkAndShowBadges();
      _showXp();

      _ulasanController.clear();
      setState(() {
        _selectedRating = 0;
        _isSubmitting = false;
      });

      await _loadUlasan();
    } catch (e) {
      setState(() => _isSubmitting = false);
      print('Error submitting ulasan: $e');
    }
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

  List<Map<String, dynamic>> _parseFasilitas(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final items = raw.split(',').map((s) => s.trim()).toList();
    const iconMap = {
      'Area Bermain': Icons.toys_rounded,
      'Jogging Track': Icons.directions_run_rounded,
      'Bangku Taman': Icons.chair_alt_rounded,
      'Toilet Umum': Icons.wc_rounded,
      'Parkir': Icons.local_parking_rounded,
      'Area Piknik': Icons.deck_rounded,
      'Restoran': Icons.restaurant_rounded,
      'Wahana': Icons.attractions_rounded,
      'Museum': Icons.museum_rounded,
      'Pantai': Icons.beach_access_rounded,
      'Hotel': Icons.hotel_rounded,
    };
    return items.map((label) {
      return {
        'label': label,
        'icon': iconMap[label] ?? Icons.check_circle_outline_rounded,
      };
    }).toList();
  }

  List<String> _parseTags(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').map((s) => s.trim()).toList();
  }

  @override
  void dispose() {
    _ulasanController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ruang;

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
                      Image.asset(
                        r['image_asset'] ??
                            'assets/images/ruang/placeholder.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: const Color(0xFFFFF3EC),
                          child: const Center(
                            child: Icon(
                              Icons.park_rounded,
                              color: Color(0xFFF7924A),
                              size: 48,
                            ),
                          ),
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
                                Colors.transparent,
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
                        Share.share(
                            'Yuk Jelajah Jakarta Timur Bareng si Timo!');
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
                        r['nama'] ?? '',
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
                            '${r['rating']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            ' (${r['jumlah_ulasan']}+ ulasan)',
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF999999)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: Color(0xFF999999)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              r['alamat'] ?? '',
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF666666)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if ((r['tags'] as String?)?.isNotEmpty == true)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _parseTags(r['tags'])
                              .map((tag) => _buildTagChip(tag))
                              .toList(),
                        ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Tentang'),
                      const SizedBox(height: 14),
                      Text(
                        r['deskripsi'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555555),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Fasilitas'),
                      const SizedBox(height: 14),
                      _buildFasilitasGrid(r['fasilitas']),
                      const SizedBox(height: 34),
                      if (r['tiket'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3EC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFFBD2B6)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.confirmation_num_outlined,
                                      color: Color(0xFFF7924A),
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TIKET MASUK',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF999999),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r['tiket'] ?? 'Gratis',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFF7924A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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
                                    tempatId: widget.ruang['id'],
                                    tipe: 'ruang_terbuka',
                                    namaTempat: widget.ruang['nama'] ?? '',
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Lihat Semua',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF7924A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (_ulasanList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Belum ada ulasan. Jadilah yang pertama!',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 14),
                          ),
                        )
                      else
                        ...(_ulasanList
                            .take(3)
                            .map((u) => _buildUlasanItem(u))),
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
                              mainAxisAlignment: MainAxisAlignment.center,
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
                label: 'Review berhasil ditambahkan!',
                onDismiss: () => setState(() => _showXpPopup = false),
              ),
            ),
          ),
      ],
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

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFBD2B6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF7924A),
        ),
      ),
    );
  }

  Widget _buildFasilitasGrid(String? raw) {
    final items = _parseFasilitas(raw);
    if (items.isEmpty) {
      return Text('Tidak ada info fasilitas.',
          style: TextStyle(color: Colors.grey[400], fontSize: 13));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 16),
              child: SizedBox(
                width: 64,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EC),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: const Color(0xFFFBD2B6)),
                      ),
                      child: Icon(item['icon'] as IconData,
                          color: const Color(0xFFF7924A), size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF555555),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
                    fontSize: 14, color: Color(0xFF999999)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${u['komentar'] ?? ''}"',
            style: const TextStyle(
              fontSize: 14,
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