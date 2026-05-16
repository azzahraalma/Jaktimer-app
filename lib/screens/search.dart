import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../helper/database_helper.dart';
import '../services/location_service.dart';
import '../widgets/kuliner_card.dart';
import '../widgets/ruang_card.dart';
import 'kuliner_detail.dart';
import 'ruang_terbuka_detail.dart';
import '../widgets/tambah_kuliner.dart';
import '../widgets/tambah_ruang.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _kulinerResults = [];
  List<Map<String, dynamic>> _ruangResults = [];
  List<Map<String, dynamic>> _rekomendasi = [];

  bool _isSearching = false;
  bool _hasQuery = false;

  // -1 semua, 0 kuliner, 1 ruang
  int _selectedTab = -1;

  Timer? _debounce;

  Position? _userPosition;
  StreamSubscription<Position>? _positionStream;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _orange      = Color(0xFFF7924A);
  static const _dark        = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _loadRekomendasi();
    _initLocation();
    _animController.forward();
  }

  // ================= LOCATION =================

  Future<void> _initLocation() async {
    final granted = await LocationService.isPermissionGranted();

    if (granted) {
      await _startTrackingLocation();
    } else {
      final permission = await LocationService.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        await _startTrackingLocation();
      }
    }
  }

  Future<void> _startTrackingLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) _updateLocation(pos);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen((position) => _updateLocation(position));
  }

  void _updateLocation(Position position) {
    if (!mounted) return;
    setState(() => _userPosition = position);
  }

  // ================= REKOMENDASI =================

  Future<void> _loadRekomendasi() async {
    final kuliner = await _db.getKuliner();
    final ruang   = await _db.getRuangTerbuka();

    final List<Map<String, dynamic>> mixed = [
      ...kuliner.map((e) => {...e, '_tipe': 'kuliner'}).take(4),
      ...ruang.map((e) => {...e, '_tipe': 'ruang'}).take(4),
    ]..shuffle();

    if (!mounted) return;
    setState(() => _rekomendasi = mixed);
  }

  // ================= SEARCH =================

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _hasQuery = false;
        _kulinerResults = [];
        _ruangResults = [];
      });
      return;
    }

    setState(() => _hasQuery = true);

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _doSearch(query),
    );
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);

    List<Map<String, dynamic>> kuliner = [];
    List<Map<String, dynamic>> ruang   = [];

    if (_selectedTab == 0) {
      kuliner = await _db.getKuliner(search: query);
    } else if (_selectedTab == 1) {
      ruang = await _db.getRuangTerbuka(search: query);
    } else {
      kuliner = await _db.getKuliner(search: query);
      ruang   = await _db.getRuangTerbuka(search: query);
    }

    if (!mounted) return;
    setState(() {
      _kulinerResults = kuliner;
      _ruangResults   = ruang;
      _isSearching    = false;
    });
  }

  // ================= DISTANCE =================

  double? _getDistance(Map<String, dynamic> item) {
    if (_userPosition == null) return null;
    final lat = double.tryParse(item['latitude'].toString());
    final lng = double.tryParse(item['longitude'].toString());
    if (lat == null || lng == null) return null;
    return LocationService.calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      lat,
      lng,
    );
  }

  // ================= FAB: pilih tambah apa =================

  void _showTambahPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Mau Tambah Apa?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih jenis tempat yang ingin kamu tambahkan',
              style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                // Kuliner
                Expanded(
                  child: _PickerOption(
                    icon: Icons.restaurant_rounded,
                    label: 'Kuliner',
                    subtitle: 'Restoran, kafe,\nwarung & lainnya',
                    onTap: () {
                      Navigator.pop(context);
                      showTambahKulinerSheet(context).then((_) => _loadRekomendasi());
                    },
                  ),
                ),
                const SizedBox(width: 14),
                // Ruang Terbuka
                Expanded(
                  child: _PickerOption(
                    icon: Icons.park_rounded,
                    label: 'Ruang Terbuka',
                    subtitle: 'Taman, RPTRA,\nhutan kota & lainnya',
                    onTap: () {
                      Navigator.pop(context);
                      showTambahRuangSheet(context).then((_) => _loadRekomendasi());
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _positionStream?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  _buildTabs(),
                  Expanded(
                    child: _hasQuery
                        ? _buildSearchResults()
                        : _buildRekomendasi(),
                  ),
                ],
              ),

              // ── FAB pojok kanan bawah ────────────────────────────────────
              if (_hasQuery)
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: GestureDetector(
                    onTap: _showTambahPicker,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _orange.withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_hasQuery)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'Mau Cari Apa Hari Ini?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  color: _orange,
                ),
              ),
            ),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFBD2B6)),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.search_rounded, color: _orange),
                ),

                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: _selectedTab == 0
                          ? 'Cari Kuliner...'
                          : _selectedTab == 1
                              ? 'Cari Ruang Terbuka...'
                              : 'Cari Kuliner atau Ruang Terbuka',
                      hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                    ),
                  ),
                ),

                if (_hasQuery)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(Icons.close_rounded, color: Color(0xFFBBBBBB)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB =================

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Berdasarkan Kategori',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: _dark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _tabButton(icon: Icons.restaurant_rounded, label: 'Kuliner', index: 0),
              const SizedBox(width: 10),
              _tabButton(icon: Icons.park_rounded, label: 'Ruang Terbuka', index: 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = _selectedTab == index ? -1 : index);
        final query = _searchController.text.trim();
        if (query.isNotEmpty) _doSearch(query);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _orange : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? _orange : const Color(0xFFFBD2B6),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : _orange),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= REKOMENDASI =================

  Widget _buildRekomendasi() {
    if (_rekomendasi.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data tersedia',
          style: TextStyle(color: Color(0xFFBBBBBB)),
        ),
      );
    }

    final items = _selectedTab == -1
        ? _rekomendasi
        : _rekomendasi.where((item) {
            if (_selectedTab == 0) return item['_tipe'] == 'kuliner';
            return item['_tipe'] == 'ruang';
          }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Text(
              'Rekomendasi dari Timo',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: _dark,
              ),
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (_, index) {
              final item      = items[index];
              final isKuliner = item['_tipe'] == 'kuliner';

              if (isKuliner) {
                return KulinerCard(
                  kuliner: item,
                  distance: _getDistance(item),
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => KulinerDetailScreen(kuliner: item))),
                );
              }

              return RuangCard(
                ruang: item,
                distance: _getDistance(item),
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => RuangDetailScreen(ruang: item))),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= SEARCH RESULT =================

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: _orange),
      );
    }

    List<Map<String, dynamic>> items;

    if (_selectedTab == 0) {
      items = _kulinerResults.map((e) => {...e, '_tipe': 'kuliner'}).toList();
    } else if (_selectedTab == 1) {
      items = _ruangResults.map((e) => {...e, '_tipe': 'ruang'}).toList();
    } else {
      items = [
        ..._kulinerResults.map((e) => {...e, '_tipe': 'kuliner'}),
        ..._ruangResults.map((e) => {...e, '_tipe': 'ruang'}),
      ];
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Tidak ada hasil',
              style: TextStyle(color: Colors.grey[400], fontSize: 15),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.88,  // sama dengan rekomendasi — tidak ada whitespace
      ),
      itemBuilder: (_, index) {
        final item      = items[index];
        final isKuliner = item['_tipe'] == 'kuliner';

        if (isKuliner) {
          return KulinerCard(
            kuliner: item,
            distance: _getDistance(item),
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => KulinerDetailScreen(kuliner: item))),
          );
        }

        return RuangCard(
          ruang: item,
          distance: _getDistance(item),
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => RuangDetailScreen(ruang: item))),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Picker option tile
// ─────────────────────────────────────────────────────────────────────────────

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  static const _orange      = Color(0xFFF7924A);
  static const _orangeLight = Color(0xFFFFF2E8);
  static const _dark        = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: _orangeLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFBD2B6)),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: _orange,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}