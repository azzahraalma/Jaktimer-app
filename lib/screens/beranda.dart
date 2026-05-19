import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jaktimer/screens/profile_screen.dart';

import '../helper/database_helper.dart';
import '../services/location_service.dart';
import '../widgets/kuliner_card.dart';
import '../widgets/ruang_card.dart';
import '../widgets/location_permission_dialog.dart';
import '../widgets/daily_checkin_float.dart';
import 'kuliner_detail.dart';
import 'jelajah_kuliner.dart';
import 'ruang_terbuka_detail.dart';
import 'search.dart';
import 'jelajah_ruang.dart';
import 'ulik.dart';
import 'daily_checkin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _user;
  int _currentUserId = 1;

  Position? _currentPosition;
  String _locationLabel = 'Mencari lokasi...';
  bool _locationGranted = false;
  StreamSubscription<Position>? _positionStream;

  // Raw data dari DB
  List<Map<String, dynamic>> _allKuliner = [];
  List<Map<String, dynamic>> _allRuang = [];

  // Data yang sudah di-sort & filter berdasarkan jarak
  List<Map<String, dynamic>> _kulinerList = [];
  List<Map<String, dynamic>> _ruangList = [];

  bool _isLoading = true;
  Timer? _searchDebounce;

  int _selectedNav = 0;

  // Radius maksimal rekomendasi (meter) — ubah sesuai kebutuhan
  static const double _maxRadiusMeters = 10000; // 10 km
  // Jumlah item yang ditampilkan di beranda
  static const int _maxItemShown = 10;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _loadUser();
      await _loadData();
      await _checkLocationAndInit();
    } catch (e) {
      debugPrint('Init error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _switchToUlik() => setState(() => _selectedNav = 2);

  Future<void> _loadUser() async {
    final user = await _db.getUserById(_currentUserId);
    if (mounted) setState(() => _user = user);
  }

  Future<void> _loadData() async {
    final kuliner = await _db.getKuliner();
    final ruang = await _db.getRuangTerbuka();
    if (mounted) {
      setState(() {
        _allKuliner = kuliner;
        _allRuang = ruang;
        // Sebelum lokasi didapat, tampilkan semua tanpa sort
        _kulinerList = kuliner.take(_maxItemShown).toList();
        _ruangList = ruang.take(_maxItemShown).toList();
      });
    }
  }

  // ── Sort & filter berdasarkan jarak ──────────────────────────────────────
  // Dipanggil setiap kali posisi user diperbarui.
  // 1. Hitung jarak tiap item ke posisi user
  // 2. Filter yang jaraknya <= _maxRadiusMeters
  // 3. Sort ascending (terdekat dulu)
  // 4. Ambil _maxItemShown teratas
  // Kalau hasil filter kosong (semua terlalu jauh), fallback ke sort tanpa filter
  void _sortAndFilterByLocation(Position pos) {
    double? dist(Map<String, dynamic> item) {
      final lat = (item['latitude'] as num?)?.toDouble();
      final lon = (item['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;
      return LocationService.calculateDistance(
        pos.latitude,
        pos.longitude,
        lat,
        lon,
      );
    }

    List<Map<String, dynamic>> sortedFilter(
        List<Map<String, dynamic>> source) {
      // Pisahkan item yang punya koordinat valid
      final withCoord =
          source.where((e) => dist(e) != null).toList();
      final withoutCoord =
          source.where((e) => dist(e) == null).toList();

      // Sort by jarak
      withCoord.sort((a, b) => dist(a)!.compareTo(dist(b)!));

      // Filter by radius
      final filtered = withCoord
          .where((e) => dist(e)! <= _maxRadiusMeters)
          .toList();

      // Kalau hasil filter kosong, pakai semua yang sudah di-sort (fallback)
      final result =
          filtered.isNotEmpty ? filtered : withCoord;

      return [...result, ...withoutCoord].take(_maxItemShown).toList();
    }

    if (mounted) {
      setState(() {
        _kulinerList = sortedFilter(_allKuliner);
        _ruangList = sortedFilter(_allRuang);
      });
    }
  }

  // ── Location ─────────────────────────────────────────────────────────────

  Future<void> _checkLocationAndInit() async {
    final granted = await LocationService.isPermissionGranted();
    if (granted) {
      _locationGranted = true;
      await _startLocationTracking();
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _showLocationDialog();
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LocationPermissionDialog(
        onAllow: () async {
          Navigator.pop(context);
          final perm = await LocationService.requestPermission();
          if (perm == LocationPermission.whileInUse ||
              perm == LocationPermission.always) {
            setState(() => _locationGranted = true);
            await _startLocationTracking();
          } else {
            setState(() => _locationLabel = 'Lokasi tidak aktif');
          }
        },
        onDeny: () {
          Navigator.pop(context);
          setState(() => _locationLabel = 'Lokasi tidak aktif');
        },
      ),
    );
  }

  Future<void> _startLocationTracking() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) await _updateLocation(position);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen((pos) => _updateLocation(pos));
  }

  Future<void> _updateLocation(Position pos) async {
    if (!mounted) return;
    setState(() {
      _currentPosition = pos;
      _locationLabel = _inferAreaLabel(pos.latitude, pos.longitude);
    });
    // Sort ulang setiap posisi diperbarui
    _sortAndFilterByLocation(pos);
  }

  String _inferAreaLabel(double lat, double lon) {
    final areas = {
      'Cipayung, Jakarta Timur': [-6.2512, 106.8823],
      'Duren Sawit, Jakarta Timur': [-6.2215, 106.9012],
      'Matraman, Jakarta Timur': [-6.2088, 106.8456],
      'Pulogadung, Jakarta Timur': [-6.1889, 106.9001],
      'Jatinegara, Jakarta Timur': [-6.2167, 106.8741],
      'Rawamangun, Jakarta Timur': [-6.1996, 106.8928],
      'Kramat Jati, Jakarta Timur': [-6.2389, 106.8612],
    };

    double minDist = double.infinity;
    String nearest = 'Jakarta Timur';

    areas.forEach((name, coords) {
      final d = Geolocator.distanceBetween(lat, lon, coords[0], coords[1]);
      if (d < minDist) {
        minDist = d;
        nearest = name;
      }
    });

    return nearest;
  }

  double? _distanceTo(double? lat, double? lon) {
    if (_currentPosition == null || lat == null || lon == null) return null;
    return LocationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lon,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF7924A)),
            )
          : Stack(
              children: [
                IndexedStack(
                  index: _selectedNav,
                  children: [
                    Stack(
                      children: [
                        _buildHomePage(),
                        Positioned(
                          right: 2,
                          bottom: -20,
                          child: DailyCheckinFloat(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DailyCheckinScreen(
                                    userId: _currentUserId,
                                    onSwitchToUlik: _switchToUlik,
                                  ),
                                ),
                              );
                              _loadUser();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SearchScreen(),
                    const UlikScreen(),
                    ProfileScreen(userId: _currentUserId),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: _buildFloatingNav(),
    );
  }

  Widget _buildHomePage() {
    final firstName =
        _user?['username']?.toString().split(' ').first ?? 'User';

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Halo, $firstName',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            color: Color(0xFFF7924A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // LOCATION
                  GestureDetector(
                    onTap: () {
                      if (!_locationGranted) _showLocationDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFBD2B6)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF7924A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.near_me_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kamu berada di',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[500]),
                                ),
                                Text(
                                  _locationLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_locationGranted)
                            Icon(Icons.chevron_right_rounded,
                                color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // KULINER
            _buildSectionHeader(
              title: 'Rekomendasi Kuliner di Sekitarmu',
            ),

            _kulinerList.isEmpty
                ? _buildEmptyState('Tidak ada kuliner dalam radius 10 km')
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 6, 0),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _kulinerList.length,
                      itemBuilder: (_, i) {
                        final k = _kulinerList[i];
                        return KulinerCard(
                          kuliner: k,
                          distance: _distanceTo(
                            (k['latitude'] as num?)?.toDouble(),
                            (k['longitude'] as num?)?.toDouble(),
                          ),
                          onTap: () => _onKulinerTap(k),
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 10),

            // BUTTON KULINER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JelajahKulinerScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF7924A),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'Jelajahi Kuliner',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // RUANG TERBUKA
            _buildSectionHeader(
              title: 'Rekomendasi Ruang Terbuka di Sekitarmu',
            ),

            _ruangList.isEmpty
                ? _buildEmptyState('Tidak ada ruang terbuka dalam radius 10 km')
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 6, 0),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _ruangList.length,
                      itemBuilder: (_, i) {
                        final r = _ruangList[i];
                        return RuangCard(
                          ruang: r,
                          distance: _distanceTo(
                            (r['latitude'] as num?)?.toDouble(),
                            (r['longitude'] as num?)?.toDouble(),
                          ),
                          onTap: () => _onRuangTap(r),
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 10),

            // BUTTON RUANG
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JelajahRuangScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF7924A),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'Jelajahi Ruang Terbuka',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 160),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFBD2B6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded,
                color: Color(0xFFF7924A), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBD2B6),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.home_rounded, index: 0),
            _navItem(icon: Icons.search_rounded, index: 1),
            _navItem(icon: Icons.article_outlined, index: 2),
            _navItem(icon: Icons.person_outline_rounded, index: 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required int index}) {
    final bool selected = _selectedNav == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNav = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFF7924A), size: 34),
      ),
    );
  }

  void _onKulinerTap(Map<String, dynamic> k) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KulinerDetailScreen(
          kuliner: k,
          distance: _distanceTo(
            (k['latitude'] as num?)?.toDouble(),
            (k['longitude'] as num?)?.toDouble(),
          ),
        ),
      ),
    );
  }

  void _onRuangTap(Map<String, dynamic> r) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RuangDetailScreen(
          ruang: r,
          distance: _distanceTo(
            (r['latitude'] as num?)?.toDouble(),
            (r['longitude'] as num?)?.toDouble(),
          ),
        ),
      ),
    );
  }
}