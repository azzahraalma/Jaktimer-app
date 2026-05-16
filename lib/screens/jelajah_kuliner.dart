// lib/screens/jelajah_kuliner.dart
import 'package:flutter/material.dart';
import '../helper/database_helper.dart';
import '../helper/badge_helper.dart';
import 'kuliner_detail.dart';
import '../widgets/tambah_kuliner.dart';

class JelajahKulinerScreen extends StatefulWidget {
  final String? misiKode;
  final int? userId;
  final bool openAddForm;
  final bool fromMisi;
  final VoidCallback? onMisiSelesai;

  const JelajahKulinerScreen({
    super.key,
    this.misiKode,
    this.userId,
    this.openAddForm = false,
    this.fromMisi = false,
    this.onMisiSelesai,
  });

  @override
  State<JelajahKulinerScreen> createState() => _JelajahKulinerScreenState();
}

class _JelajahKulinerScreenState extends State<JelajahKulinerScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allKuliner = [];
  List<Map<String, dynamic>> _filteredKuliner = [];
  bool _isLoading = true;
  String _selectedFilter = 'Terdekat';

  final List<String> _filters = ['Terdekat', 'Rating Tertinggi', 'Terpopuler'];

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearch);

    if (widget.openAddForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTambahKulinerForm();
      });
    }
  }

  // ── Badge helper ──────────────────────────────────────────────────────────
  Future<void> _checkAndShowBadges() async {
    if (widget.userId == null) return;
    final newBadges = await BadgeHelper.checkAndAwardBadges(widget.userId!);
    if (newBadges.isNotEmpty && mounted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          BadgeHelper.showBadgeQueue(
            context: context,
            badges: newBadges,
          );
        }
      });
    }
  }

  // ── Misi callbacks ────────────────────────────────────────────────────────
  Future<void> _onReviewSubmitted() async {
    if (widget.misiKode == 'tambah_review_kuliner' &&
        widget.onMisiSelesai != null) {
      widget.onMisiSelesai!();
    }
    await _checkAndShowBadges();
  }

  Future<void> _onKulinerAdded() async {
    if (widget.misiKode == 'tambah_kuliner' && widget.onMisiSelesai != null) {
      widget.onMisiSelesai!();
    }
    await _checkAndShowBadges();
  }

  void _showTambahKulinerForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TambahKulinerScreen(
        onSubmit: (data) async {
          Navigator.pop(context);
          await _onKulinerAdded();
          await _loadData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kuliner berhasil ditambahkan!'),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _loadData() async {
    final data = await _db.getKuliner();
    setState(() {
      _allKuliner = data;
      _filteredKuliner = List.from(data);
      _isLoading = false;
    });
    _applyFilter(_selectedFilter);
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredKuliner = _allKuliner.where((k) {
        return (k['nama'] ?? '').toLowerCase().contains(q) ||
            (k['deskripsi'] ?? '').toLowerCase().contains(q);
      }).toList();
    });
    _applyFilter(_selectedFilter);
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Rating Tertinggi') {
        _filteredKuliner.sort((a, b) =>
            _toDouble(b['rating']).compareTo(_toDouble(a['rating'])));
      } else if (filter == 'Terpopuler') {
        _filteredKuliner.sort((a, b) =>
            _toDouble(b['jumlah_ulasan'])
                .compareTo(_toDouble(a['jumlah_ulasan'])));
      }
    });
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _formatHarga(dynamic min, dynamic max) {
    final iMin = _toDouble(min).toInt();
    final iMax = _toDouble(max).toInt();
    final hasMin = min != null;
    final hasMax = max != null;
    String fmt(int n) =>
        n >= 1000 ? 'Rp ${(n / 1000).toStringAsFixed(0)}k' : 'Rp $n';
    if (hasMin && hasMax) return '${fmt(iMin)} – ${fmt(iMax)}';
    if (hasMin) return '${fmt(iMin)}+';
    if (hasMax) return fmt(iMax);
    return '';
  }

  String _shortAlamat(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.split(',').first.trim();
  }

  Widget _buildLocalImage({
    required Map<String, dynamic> k,
    required double height,
    double? width,
    BoxFit fit = BoxFit.cover,
    Widget? fallbackIcon,
  }) {
    return Image.asset(
      k['image_asset'] ?? 'assets/images/kuliner/placeholder.png',
      height: height,
      width: width ?? double.infinity,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        height: height,
        width: width ?? double.infinity,
        color: const Color(0xFFFFF3EC),
        child: Center(
          child: fallbackIcon ??
              const Icon(
                Icons.restaurant_rounded,
                color: Color(0xFFF7924A),
                size: 36,
              ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _isSearching;

    final featured = (!isSearching && _filteredKuliner.isNotEmpty)
        ? _filteredKuliner.first
        : null;
    final gridItems = (!isSearching && _filteredKuliner.length > 1)
        ? _filteredKuliner.sublist(1, _filteredKuliner.length.clamp(1, 3))
        : <Map<String, dynamic>>[];
    final listItems = isSearching
        ? _filteredKuliner
        : (_filteredKuliner.length > 3
            ? _filteredKuliner.sublist(3)
            : <Map<String, dynamic>>[]);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _showTambahKulinerForm,
        backgroundColor: const Color(0xFFF7924A),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF7924A)),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── HEADER ───────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3EC),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFFBD2B6)),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 16,
                                    color: Color(0xFFF7924A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jelajahi Kuliner',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  Text(
                                    'Temukan cita rasa terbaik di sekitarmu',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Cari sate, bakso, atau kafe...',
                                hintStyle: const TextStyle(
                                    color: Color(0xFFBBBBBB), fontSize: 14),
                                prefixIcon: const Icon(Icons.search_rounded,
                                    color: Color(0xFFBBBBBB)),
                                suffixIcon: isSearching
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          _onSearch();
                                        },
                                        child: const Icon(Icons.close_rounded,
                                            color: Color(0xFFBBBBBB)),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _filters.map((f) {
                                final selected = f == _selectedFilter;
                                return GestureDetector(
                                  onTap: () => _applyFilter(f),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFFF7924A)
                                          : const Color(0xFFFFF3EC),
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFFF7924A)
                                            : const Color(0xFFFBD2B6),
                                      ),
                                    ),
                                    child: Text(
                                      f,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFFF7924A),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // ── FEATURED ─────────────────────────────────────────────
                  if (featured != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KulinerDetailScreen(
                                kuliner: featured,
                                onReviewSubmitted: _onReviewSubmitted,
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildLocalImage(k: featured, height: 200),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Color(0xCC000000),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 14,
                                    left: 14,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7924A),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'POPULER',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 14,
                                    right: 14,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              size: 14,
                                              color: Color(0xFFFFB800)),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${featured['rating'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1A1A2E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 14,
                                    left: 14,
                                    right: 14,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          featured['nama'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatHarga(
                                            featured['harga_min'],
                                            featured['harga_max'],
                                          ),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFFFFD9B0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── GRID ─────────────────────────────────────────────────
                  if (gridItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Row(
                          children: gridItems.map((k) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: k == gridItems.last ? 0 : 10,
                                ),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => KulinerDetailScreen(
                                        kuliner: k,
                                        onReviewSubmitted: _onReviewSubmitted,
                                      ),
                                    ),
                                  ),
                                  child: _buildGridCard(k),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  // ── LIST ─────────────────────────────────────────────────
                  if (listItems.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final k = listItems[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KulinerDetailScreen(
                                    kuliner: k,
                                    onReviewSubmitted: _onReviewSubmitted,
                                  ),
                                ),
                              ),
                              child: _buildListCard(k),
                            );
                          },
                          childCount: listItems.length,
                        ),
                      ),
                    )
                  else if (isSearching)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 60, horizontal: 20),
                        child: Column(
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 48, color: Color(0xFFBBBBBB)),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada hasil untuk\n"${_searchController.text}"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF999999)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> k) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFBD2B6),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                _buildLocalImage(k: k, height: 110),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 12, color: Color(0xFFFFB800)),
                        const SizedBox(width: 2),
                        Text(
                          '${k['rating'] ?? '-'}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k['nama'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatHarga(k['harga_min'], k['harga_max']),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF7924A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> k) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFBD2B6),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 88,
              height: 88,
              child: _buildLocalImage(k: k, height: 88, width: 88),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        k['nama'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 15, color: Color(0xFFFFB800)),
                        const SizedBox(width: 3),
                        Text(
                          '${k['rating'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _shortAlamat(k['alamat']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatHarga(k['harga_min'], k['harga_max']),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF7924A),
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