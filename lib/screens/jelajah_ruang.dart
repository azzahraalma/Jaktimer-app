// lib/screens/jelajah_ruang.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

import '../helper/database_helper.dart';
import '../helper/badge_helper.dart';
import '../widgets/tambah_ruang.dart';
import 'ruang_terbuka_detail.dart';

class JelajahRuangScreen extends StatefulWidget {
  final String? misiKode;
  final int? userId;
  final bool openAddForm;
  final bool fromMisi;
  final VoidCallback? onMisiSelesai;

  const JelajahRuangScreen({
    super.key,
    this.misiKode,
    this.userId,
    this.openAddForm = false,
    this.fromMisi = false,
    this.onMisiSelesai,
  });

  @override
  State<JelajahRuangScreen> createState() => _JelajahRuangScreenState();
}

class _JelajahRuangScreenState extends State<JelajahRuangScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allRuang = [];
  List<Map<String, dynamic>> _filteredRuang = [];
  bool _isLoading = true;
  String _selectedFilter = 'Terdekat';

  final List<String> _filters = ['Terdekat', 'Fasilitas', 'Tiket Gratis'];

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  Position? _userPosition;

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _userPosition = pos);
    } catch (_) {}
  }

  List<Map<String, dynamic>> _injectDistance(List<Map<String, dynamic>> data) {
    if (_userPosition == null) return data;
    return data.map((r) {
      final lat = _toDouble(r['latitude']);
      final lon = _toDouble(r['longitude']);
      if (lat == 0 && lon == 0) return r;
      final dist = _haversine(
          _userPosition!.latitude, _userPosition!.longitude, lat, lon);
      return {...r, 'distance': dist};
    }).toList();
  }

  //  Badge helper 
  Future<void> _checkAndShowBadges() async {
    if (widget.userId == null) return;
    final newBadges = await BadgeHelper.checkAndAwardBadges(widget.userId!);
    if (newBadges.isNotEmpty && mounted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          BadgeHelper.showBadgeQueue(context: context, badges: newBadges);
        }
      });
    }
  }

  //  Misi callbacks 
  Future<void> _onReviewSubmitted() async {
    if (widget.misiKode == 'tambah_review_ruang' &&
        widget.onMisiSelesai != null) {
      widget.onMisiSelesai!();
    }
    await _checkAndShowBadges();
  }

  Future<void> _onRuangAdded() async {
    if (widget.misiKode == 'tambah_ruang' && widget.onMisiSelesai != null) {
      widget.onMisiSelesai!();
    }
    await _checkAndShowBadges();
  }

  void _showTambahRuangForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TambahRuangScreen(
        onSubmit: (data) async {
          if (mounted) Navigator.pop(context);
          await _onRuangAdded();
          await _loadData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Ruang terbuka berhasil ditambahkan! 🎉'),
                backgroundColor: const Color(0xFFF7924A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
    _searchController.addListener(_onSearch);

    if (widget.openAddForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTambahRuangForm();
      });
    }
  }

  Future<void> _init() async {
    await _fetchLocation();
    await _loadData();
  }

  Future<void> _loadData() async {
    final raw = await _db.getRuangTerbuka();
    final data = _injectDistance(raw);
    setState(() {
      _allRuang = data;
      _filteredRuang = List.from(data);
      _isLoading = false;
    });
    _applyFilter(_selectedFilter);
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredRuang = _injectDistance(_allRuang).where((r) {
        return (r['nama'] ?? '').toLowerCase().contains(q) ||
            (r['deskripsi'] ?? '').toLowerCase().contains(q) ||
            (r['alamat'] ?? '').toLowerCase().contains(q);
      }).toList();
    });
    _applyFilter(_selectedFilter);
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Fasilitas') {
        _filteredRuang.sort((a, b) {
          final fa = (a['fasilitas'] ?? '').toString().split(',').length;
          final fb = (b['fasilitas'] ?? '').toString().split(',').length;
          return fb.compareTo(fa);
        });
      } else if (filter == 'Tiket Gratis') {
        _filteredRuang.sort((a, b) {
          final ta = (a['tiket'] ?? '').toString().toLowerCase().trim();
          final tb = (b['tiket'] ?? '').toString().toLowerCase().trim();
          final aFree = ta.isEmpty || ta == 'gratis' || ta == '0';
          final bFree = tb.isEmpty || tb == 'gratis' || tb == '0';
          if (aFree && !bFree) return -1;
          if (!aFree && bFree) return 1;
          return ta.compareTo(tb);
        });
      } else {
        _filteredRuang.sort((a, b) {
          final da = (a['distance'] != null)
              ? _toDouble(a['distance'])
              : 999999.0;
          final db = (b['distance'] != null)
              ? _toDouble(b['distance'])
              : 999999.0;
          return da.compareTo(db);
        });
      }
    });
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _formatDistance(dynamic distance) {
    if (distance == null) return '-';
    final d = _toDouble(distance);
    if (d < 1) return '${(d * 1000).toInt()} m';
    return '${d.toStringAsFixed(1)} km';
  }

  String _formatTiket(dynamic tiket) {
    if (tiket == null) return 'Gratis';
    final s = tiket.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'gratis' || s == '0') return 'Gratis';
    return s;
  }

  List<String> _parseFasilitas(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) return [];
    return raw
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(4)
        .toList();
  }

  IconData _fasilitasIcon(String nama) {
    final n = nama.toLowerCase();
    if (n.contains('wifi') || n.contains('wi-fi')) return Icons.wifi_rounded;
    if (n.contains('parkir') || n.contains('park'))
      return Icons.local_parking_rounded;
    if (n.contains('toilet') || n.contains('wc') || n.contains('kamar mandi'))
      return Icons.wc_rounded;
    if (n.contains('mushola') || n.contains('masjid') || n.contains('ibadah'))
      return Icons.mosque_rounded;
    if (n.contains('kantin') ||
        n.contains('makan') ||
        n.contains('restoran') ||
        n.contains('cafe') ||
        n.contains('kafe')) return Icons.restaurant_rounded;
    if (n.contains('playground') ||
        n.contains('bermain') ||
        n.contains('anak')) return Icons.child_care_rounded;
    if (n.contains('jogging') || n.contains('lari') || n.contains('olahraga'))
      return Icons.directions_run_rounded;
    if (n.contains('bangku') || n.contains('kursi') || n.contains('gazebo'))
      return Icons.chair_outlined;
    if (n.contains('lampu') || n.contains('penerangan'))
      return Icons.light_mode_rounded;
    if (n.contains('air') || n.contains('danau') || n.contains('kolam'))
      return Icons.water_rounded;
    return Icons.check_circle_outline_rounded;
  }

  String _shortAlamat(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.split(',').first.trim();
  }

  Widget _buildLocalImage({
    required Map<String, dynamic> r,
    required double height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      r['image_asset'] ?? 'assets/images/ruang/placeholder.png',
      height: height,
      width: width ?? double.infinity,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        height: height,
        width: width ?? double.infinity,
        color: const Color(0xFFFFF3EC),
        child: const Center(
          child: Icon(
            Icons.park_rounded,
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

    final featured = (!isSearching && _filteredRuang.isNotEmpty)
        ? _filteredRuang.first
        : null;
    final gridItems = (!isSearching && _filteredRuang.length > 1)
        ? _filteredRuang.sublist(1, _filteredRuang.length.clamp(1, 3))
        : <Map<String, dynamic>>[];
    final listItems = isSearching
        ? _filteredRuang
        : (_filteredRuang.length > 3
            ? _filteredRuang.sublist(3)
            : <Map<String, dynamic>>[]);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _showTambahRuangForm,
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
                  //  HEADER 
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
                                    'Jelajahi Ruang Terbuka',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  Text(
                                    'Temukan ruang terbaik di sekitarmu',
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
                                hintText: 'Cari taman atau ruang terbuka...',
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

                  //  FEATURED 
                  if (featured != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RuangDetailScreen(
                                ruang: featured,
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
                                  _buildLocalImage(r: featured, height: 200),
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
                                        'UNGGULAN',
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
                                          const Icon(
                                              Icons.location_on_rounded,
                                              size: 14,
                                              color: Color(0xFFF7924A)),
                                          const SizedBox(width: 2),
                                          Text(
                                            _formatDistance(
                                                featured['distance']),
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
                                          _formatTiket(featured['tiket']),
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

                  //  GRID 
                  if (gridItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Row(
                          children: gridItems.map((r) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: r == gridItems.last ? 0 : 10,
                                ),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RuangDetailScreen(
                                        ruang: r,
                                        onReviewSubmitted: _onReviewSubmitted,
                                      ),
                                    ),
                                  ),
                                  child: _buildGridCard(r),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  //  LIST 
                  if (listItems.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final r = listItems[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RuangDetailScreen(
                                    ruang: r,
                                    onReviewSubmitted: _onReviewSubmitted,
                                  ),
                                ),
                              ),
                              child: _buildListCard(r),
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

  Widget _buildGridCard(Map<String, dynamic> r) {
    final fasilitas = _parseFasilitas(r['fasilitas']);
    final rating = r['rating'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBD2B6), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                _buildLocalImage(r: r, height: 110),
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
                        const Icon(Icons.location_on_rounded,
                            size: 11, color: Color(0xFFF7924A)),
                        const SizedBox(width: 2),
                        Text(
                          _formatDistance(r['distance']),
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
                  r['nama'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                if (rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFFFB800)),
                      const SizedBox(width: 3),
                      Text('$rating',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          )),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTiket(r['tiket']),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF7924A),
                  ),
                ),
                if (fasilitas.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: fasilitas.map((f) {
                      return Tooltip(
                        message: f,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3EC),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(_fasilitasIcon(f),
                              size: 13, color: const Color(0xFFF7924A)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> r) {
    final fasilitas = _parseFasilitas(r['fasilitas']);
    final rating = r['rating'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBD2B6), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 88,
              height: 88,
              child: _buildLocalImage(r: r, height: 88, width: 88),
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
                        r['nama'] ?? '',
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
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: Color(0xFFF7924A)),
                        const SizedBox(width: 2),
                        Text(
                          _formatDistance(r['distance']),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _shortAlamat(r['alamat']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF999999)),
                ),
                const SizedBox(height: 4),
                if (rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFFFB800)),
                      const SizedBox(width: 3),
                      Text('$rating',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          )),
                    ],
                  ),
                if (rating != null) const SizedBox(height: 4),
                Text(
                  _formatTiket(r['tiket']),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF7924A),
                  ),
                ),
                if (fasilitas.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: fasilitas.map((f) {
                      return Tooltip(
                        message: f,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3EC),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(_fasilitasIcon(f),
                              size: 14, color: const Color(0xFFF7924A)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}