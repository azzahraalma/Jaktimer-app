import 'package:flutter/material.dart';
import '../helper/database_helper.dart';

class UlasanListScreen extends StatefulWidget {
  final int tempatId;
  final String tipe; // 'kuliner' atau 'ruang_terbuka'
  final String namaTempat;

  const UlasanListScreen({
    super.key,
    required this.tempatId,
    required this.tipe,
    required this.namaTempat,
  });

  @override
  State<UlasanListScreen> createState() => _UlasanListScreenState();
}

class _UlasanListScreenState extends State<UlasanListScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  List<Map<String, dynamic>> _ulasanList = [];
  bool _isLoading = true;

  // Filter state
  int _filterRating = 0; // 0 = semua

  @override
  void initState() {
    super.initState();
    _loadUlasan();
  }

  Future<void> _loadUlasan() async {
    setState(() => _isLoading = true);
    final ulasan = await _db.getUlasan(widget.tempatId, widget.tipe);
    setState(() {
      _ulasanList = ulasan;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredUlasan {
    if (_filterRating == 0) return _ulasanList;
    return _ulasanList
        .where((u) => (u['rating'] as num? ?? 0).toInt() == _filterRating)
        .toList();
  }

  double get _avgRating {
    if (_ulasanList.isEmpty) return 0;
    final total = _ulasanList.fold<double>(
      0,
      (sum, u) => sum + ((u['rating'] as num?)?.toDouble() ?? 0),
    );
    return total / _ulasanList.length;
  }

  Map<int, int> get _ratingDistribution {
    final map = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final u in _ulasanList) {
      final r = (u['rating'] as num? ?? 0).toInt();
      if (r >= 1 && r <= 5) map[r] = (map[r] ?? 0) + 1;
    }
    return map;
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()} minggu lalu';
      if (diff.inDays >= 1) return '${diff.inDays} hari lalu';
      if (diff.inHours >= 1) return '${diff.inHours} jam lalu';
      return 'Baru saja';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF7924A)),
            )
          : _ulasanList.isEmpty
              ? _buildEmptyState()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── SUMMARY CARD ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildSummaryCard(),
                      ),
                    ),

                    // ── FILTER CHIPS ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: _buildFilterChips(),
                      ),
                    ),

                    // ── JUMLAH HASIL ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Text(
                          '${_filteredUlasan.length} ulasan ditampilkan',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ),

                    // ── LIST ULASAN ───────────────────────────────
                    _filteredUlasan.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptyFilter())
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _buildUlasanItem(_filteredUlasan[i]),
                                childCount: _filteredUlasan.length,
                              ),
                            ),
                          ),
                  ],
                ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true, // FIX: title jadi center
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.only(left: 12),
          width: 38,
          height: 38,
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // FIX: center
        children: [
          const Text(
            'Semua Ulasan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          Text(
            widget.namaTempat,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF999999),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center, // FIX: center
          ),
        ],
      ),
      titleSpacing: 8,
    );
  }

  // ── SUMMARY CARD ───────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final avg = _avgRating;
    final dist = _ratingDistribution;
    final total = _ulasanList.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBD2B6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: big avg
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF7924A),
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < avg.floor()
                        ? Icons.star_rounded
                        : (i < avg
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded),
                    color: const Color(0xFFFFB800),
                    size: 16,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$total ulasan',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),

          // Right: bar chart per bintang
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = dist[star] ?? 0;
                final fraction = total > 0 ? count / total : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFFFB800),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction.toDouble(),
                            minHeight: 7,
                            backgroundColor: Colors.white,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFF7924A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTER CHIPS ───────────────────────────────────────────────────
  Widget _buildFilterChips() {
    final options = [
      {'label': 'Semua', 'value': 0},
      {'label': '⭐ 5', 'value': 5},
      {'label': '⭐ 4', 'value': 4},
      {'label': '⭐ 3', 'value': 3},
      {'label': '⭐ 2', 'value': 2},
      {'label': '⭐ 1', 'value': 1},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.map((opt) {
          final selected = _filterRating == opt['value'];
          return GestureDetector(
            onTap: () => setState(() => _filterRating = opt['value'] as int),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFF7924A)
                    : const Color(0xFFFFF3EC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFF7924A)
                      : const Color(0xFFFBD2B6),
                ),
              ),
              child: Text(
                opt['label'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFFF7924A),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── ULASAN ITEM ────────────────────────────────────────────────────
  Widget _buildUlasanItem(Map<String, dynamic> u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          // FIX: withOpacity deprecated → withValues
          color: const Color(0xFFFBD2B6).withValues(alpha: 0.6),
        ),
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
                  fontSize: 11,
                  color: Color(0xFF999999),
                ),
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

  // ── EMPTY STATES ───────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              size: 40,
              color: Color(0xFFF7924A),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada ulasan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Jadilah yang pertama memberikan ulasan!',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'Tidak ada ulasan dengan bintang $_filterRating',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF999999),
          ),
        ),
      ),
    );
  }
}