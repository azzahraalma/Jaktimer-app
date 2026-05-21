import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';


import '../helper/database_helper.dart';

Future<void> showTambahKulinerSheet(
  BuildContext context, {
  bool fromMisi = false,
  VoidCallback? onMisiSelesai,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _KulinerFormSheet(
      fromMisi: fromMisi,
      onMisiSelesai: onMisiSelesai,
    ),
  );
}

class _KulinerFormSheet extends StatelessWidget {
  final bool fromMisi;
  final VoidCallback? onMisiSelesai;

  const _KulinerFormSheet({
    this.fromMisi = false,
    this.onMisiSelesai,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _KulinerFormBody(
                scrollController: scrollController,
                fromMisi: fromMisi,
                onMisiSelesai: onMisiSelesai,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TambahKulinerScreen extends StatelessWidget {
  final Function(Map<String, dynamic>)? onSubmit;
  final bool fromMisi;
  final VoidCallback? onMisiSelesai;

  const TambahKulinerScreen({
    super.key,
    this.onSubmit,
    this.fromMisi = false,
    this.onMisiSelesai,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _KulinerFormBody(
          onClose: () => Navigator.pop(context),
          onSubmit: onSubmit,
          fromMisi: fromMisi,
          onMisiSelesai: onMisiSelesai,
        ),
      ),
    );
  }
}

class _PlaceSuggestion {
  final String displayName;
  final String shortName;
  final double lat;
  final double lon;

  const _PlaceSuggestion({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lon,
  });

  factory _PlaceSuggestion.fromJson(Map<String, dynamic> j) {
    final display = j['display_name'] as String? ?? '';
    final short = display.split(',').take(3).join(',').trim();
    return _PlaceSuggestion(
      displayName: display,
      shortName: short,
      lat: double.tryParse(j['lat'] as String? ?? '0') ?? 0,
      lon: double.tryParse(j['lon'] as String? ?? '0') ?? 0,
    );
  }
}

class _KulinerFormBody extends StatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback? onClose;
  final Function(Map<String, dynamic>)? onSubmit;
  final bool fromMisi;
  final VoidCallback? onMisiSelesai;

  const _KulinerFormBody({
    this.scrollController,
    this.onClose,
    this.onSubmit,
    this.fromMisi = false,
    this.onMisiSelesai,
  });

  @override
  State<_KulinerFormBody> createState() => _KulinerFormBodyState();
}

class _KulinerFormBodyState extends State<_KulinerFormBody> {
  final DatabaseHelper _db = DatabaseHelper();

  final _namaController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _tentangController = TextEditingController();
  final _hargaMinController = TextEditingController();
  final _hargaMaxController = TextEditingController();
  final _jamBukaController = TextEditingController();
  final _jamTutupController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _searchController = TextEditingController();

  File? _selectedImage;
  bool _isSaving = false;

  bool _showMap = false;
  LatLng _pinLatLng = const LatLng(-6.2615, 106.9005);
  final MapController _mapController = MapController();

  List<_PlaceSuggestion> _suggestions = [];
  bool _loadingSuggest = false;
  bool _showDropdown = false;
  Timer? _debounce;

  static bool _isInJakTim(double lat, double lon) =>
      lat >= -6.37 && lat <= -6.19 && lon >= 106.82 && lon <= 106.98;

  static const _fasilitasOptions = [
    {'label': 'Makan di Tempat', 'icon': Icons.restaurant_rounded},
    {'label': 'Delivery', 'icon': Icons.delivery_dining_rounded},
    {'label': 'Takeaway', 'icon': Icons.takeout_dining_rounded},
    {'label': 'Parkir', 'icon': Icons.local_parking_rounded},
    {'label': 'WiFi', 'icon': Icons.wifi_rounded},
    {'label': 'AC', 'icon': Icons.ac_unit_rounded},
    {'label': 'Outdoor', 'icon': Icons.deck_rounded},
    {'label': 'Live Music', 'icon': Icons.music_note_rounded},
    {'label': 'Toilet Umum', 'icon': Icons.wc_rounded},
    {'label': 'Area Bermain', 'icon': Icons.toys_rounded},
  ];

  final Set<String> _selectedFasilitas = {};

  static const _orange = Color(0xFFF7924A);
  static const _orangeLight = Color(0xFFFFF2E8);
  static const _orangeBorder = Color(0xFFFBD2B6);
  static const _dark = Color(0xFF1A1A2E);

  @override
  void dispose() {
    _namaController.dispose();
    _lokasiController.dispose();
    _tentangController.dispose();
    _hargaMinController.dispose();
    _hargaMaxController.dispose();
    _jamBukaController.dispose();
    _jamTutupController.dispose();
    _kategoriController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _showOutOfAreaDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF2E8),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.location_off_rounded, color: _orange, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lokasi di Luar Jakarta Timur',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tempat yang kamu pilih berada di luar wilayah Jakarta Timur.\n\n'
              'Aplikasi ini hanya mendukung penambahan tempat kuliner di area Jakarta Timur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                elevation: 0,
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: _orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _onSearchChanged(String value) async {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showDropdown = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _loadingSuggest = true);
      try {
        final query = '${value.trim()}, Jakarta Timur';
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=json'
          '&addressdetails=1'
          '&limit=7'
          '&countrycodes=id'
          '&viewbox=106.6900,-6.1000,107.0000,-6.4000',
        );
        final resp = await http
            .get(uri, headers: {'User-Agent': 'KulinerApp/1.0'})
            .timeout(const Duration(seconds: 8));

        if (!mounted) return;
        if (resp.statusCode == 200) {
          final List<dynamic> data = jsonDecode(resp.body);
          setState(() {
            _suggestions =
                data.map((j) => _PlaceSuggestion.fromJson(j)).toList();
            _showDropdown = _suggestions.isNotEmpty;
          });
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() => _loadingSuggest = false);
      }
    });
  }

  Future<void> _onSuggestionTap(_PlaceSuggestion s) async {
    if (!_isInJakTim(s.lat, s.lon)) {
      await _showOutOfAreaDialog();
      return;
    }

    final latlng = LatLng(s.lat, s.lon);
    setState(() {
      _pinLatLng = latlng;
      _lokasiController.text = s.shortName;
      _searchController.text = s.shortName;
      _showDropdown = false;
      _suggestions = [];
      _showMap = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(latlng, 16);
    });
  }

  Future<void> _goToMyLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final latlng = LatLng(pos.latitude, pos.longitude);

      if (!_isInJakTim(latlng.latitude, latlng.longitude)) {
        await _showOutOfAreaDialog();
        return;
      }

      setState(() {
        _pinLatLng = latlng;
        _showMap = true;
      });
      _mapController.move(latlng, 16);
      await _reverseGeocode(latlng);
    } catch (_) {
      _showSnack('Tidak dapat mengambil lokasi. Pastikan GPS aktif.');
    }
  }

  Future<void> _reverseGeocode(LatLng latlng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${latlng.latitude}&lon=${latlng.longitude}&format=json',
      );
      final resp = await http
          .get(uri, headers: {'User-Agent': 'KulinerApp/1.0'})
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200 && mounted) {
        final json = jsonDecode(resp.body);
        final address = json['address'] as Map<String, dynamic>? ?? {};
        final parts = [
          address['road'],
          address['suburb'] ?? address['neighbourhood'],
          address['city_district'],
        ].where((s) => s != null && (s as String).isNotEmpty).toList();

        final text = parts.isNotEmpty
            ? parts.join(', ')
            : (json['display_name'] as String? ?? '')
                .split(',')
                .take(3)
                .join(',');

        if (mounted) {
          setState(() {
            _lokasiController.text = text;
            _searchController.text = text;
          });
        }
      }
    } catch (_) {}
  }

Future<void> _save() async {
  if (_namaController.text.trim().isEmpty) {
    _showSnack('Nama tempat wajib diisi!');
    return;
  }
  if (_kategoriController.text.trim().isEmpty) {
    _showSnack('Kategori wajib diisi!');
    return;
  }

  setState(() => _isSaving = true);

  final userId = AuthService.currentUid;
  int addedBy = int.tryParse(userId ?? '1') ?? 1;

  final data = {
    'nama': _namaController.text.trim(),
    'kategori': _kategoriController.text.trim(),
    'alamat': _lokasiController.text.trim(),
    'deskripsi': _tentangController.text.trim(),
    'harga_min': int.tryParse(_hargaMinController.text) ?? 0,
    'harga_max': int.tryParse(_hargaMaxController.text) ?? 0,
    'jam_buka': _jamBukaController.text.trim(),
    'jam_tutup': _jamTutupController.text.trim(),
    'fasilitas': _selectedFasilitas.join(','),
    'image_asset': _selectedImage?.path ?? 'assets/images/kuliner/placeholder.png',
    'rating': 0.0,
    'jumlah_ulasan': 0,
    'latitude': _pinLatLng.latitude,
    'longitude': _pinLatLng.longitude,
    'is_populer': 0,
    'added_by': addedBy,
  };

  try {
    await _db.insertKuliner(data);
    
    // FIRESTORE MISI
    if (userId != null) {
      try {
        final misiSelesai = await FirestoreService.getMisiSelesaiHariIni(userId);
        if (!misiSelesai.contains('tambah_kuliner')) {
          await FirestoreService.completeMisi(userId, 'tambah_kuliner');
          await FirestoreService.addXp(userId, 100, keterangan: 'Misi: tambah_kuliner');
        }
      } catch (e) {
        print('Error Firestore: $e');
      }
    }
    
    setState(() => _isSaving = false);

    if (widget.onSubmit != null) {
      widget.onSubmit!(data);
      return;
    }

    if (widget.fromMisi) {
      widget.onClose?.call();
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 300));
      widget.onMisiSelesai?.call();
    } else {
      widget.onClose?.call();
      Navigator.pop(context);
    }
  } catch (e) {
    setState(() => _isSaving = false);
    print('Error: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tambah Kuliner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.onClose?.call();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: Color(0xFF666666)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('Unggah Foto'),
              const SizedBox(height: 8),
              _PhotoPicker(image: _selectedImage, onTap: _pickImage),
              const SizedBox(height: 18),
              _buildLabel('Nama Tempat'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _namaController,
                hint: 'Masukkan nama tempat',
              ),
              const SizedBox(height: 16),
              _buildLabel('Kategori'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _kategoriController,
                hint: 'Contoh: Restoran, Kafe, Warung, Street Food…',
                prefixIcon:
                    const Icon(Icons.category_rounded, color: _orange, size: 20),
              ),
              const SizedBox(height: 16),
              _buildLabel('Lokasi'),
              const SizedBox(height: 4),
              const Text(
                'Cari nama jalan / tempat di Jakarta Timur',
                style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 8),
              _buildLocationSearch(),
              if (_showDropdown) _buildSuggestionsDropdown(),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _showMap = !_showMap),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _showMap ? _orangeLight : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: _showMap ? _orange : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showMap ? Icons.map_rounded : Icons.map_outlined,
                        size: 16,
                        color: _showMap ? _orange : const Color(0xFF888888),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showMap ? 'Sembunyikan peta' : 'Lihat / geser peta',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _showMap ? _orange : const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showMap ? _buildMiniMap() : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              _buildLabel('Range Harga (Rp)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _hargaMinController,
                      hint: 'Min (15000)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _hargaMaxController,
                      hint: 'Max (50000)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLabel('Jam Operasional'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        controller: _jamBukaController, hint: 'Buka (08:00)'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–',
                        style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
                  ),
                  Expanded(
                    child: _buildTextField(
                        controller: _jamTutupController, hint: 'Tutup (22:00)'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLabel('Fasilitas'),
              const SizedBox(height: 10),
              _FasilitasPicker(
                options: _fasilitasOptions,
                selected: _selectedFasilitas,
                onToggle: (label) {
                  setState(() {
                    _selectedFasilitas.contains(label)
                        ? _selectedFasilitas.remove(label)
                        : _selectedFasilitas.add(label);
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildLabel('Tentang'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _orangeLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _orange),
                ),
                child: TextField(
                  controller: _tentangController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14, color: _dark),
                  decoration: const InputDecoration(
                    hintText: 'Ceritakan sedikit tentang tempat ini…',
                    hintStyle:
                        TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 20, color: Colors.white),
                label: Text(
                  _isSaving ? 'Menyimpan…' : 'Simpan',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  disabledBackgroundColor: _orange.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _orange),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.search_rounded, color: _orange, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 14, color: _dark),
              decoration: const InputDecoration(
                hintText: 'Cari tempat di Jakarta Timur…',
                hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          if (_loadingSuggest)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 1.8, color: _orange),
              ),
            )
          else
            GestureDetector(
              onTap: _goToMyLocation,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _orangeLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: _orange, width: 1),
                ),
                child: const Icon(Icons.my_location_rounded,
                    color: _orange, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _orangeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: _suggestions.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final inArea = _isInJakTim(s.lat, s.lon);
            return InkWell(
              onTap: () => _onSuggestionTap(s),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: i < _suggestions.length - 1
                      ? const Border(
                          bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: inArea ? _orange : const Color(0xFFCCCCCC),
                        size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.shortName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: inArea ? _dark : const Color(0xFFAAAAAA),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.displayName,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF999999)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!inArea) ...[
                            const SizedBox(height: 3),
                            const Text(
                              'Di luar Jakarta Timur',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFFF6B6B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
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

  Widget _buildMiniMap() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _orangeBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _pinLatLng,
                initialZoom: 15,
                cameraConstraint: CameraConstraint.containCenter(
                  bounds: LatLngBounds(
                    const LatLng(-6.37, 106.82),
                    const LatLng(-6.19, 106.98),
                  ),
                ),
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture && pos.center != null) {
                    setState(() => _pinLatLng = pos.center!);
                  }
                },
                onMapEvent: (event) {
                  if (event is MapEventMoveEnd) {
                    _reverseGeocode(_pinLatLng);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kuliner.app',
                  maxZoom: 19,
                ),
              ],
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _orange.withValues(alpha: 0.45),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: _orange, size: 42),
                  ),
                  const SizedBox(height: 42),
                ],
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: GestureDetector(
                onTap: _goToMyLocation,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.my_location_rounded,
                      color: _orange, size: 18),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: Colors.white.withValues(alpha: 0.95),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: _orange, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _lokasiController.text.isEmpty
                            ? 'Geser peta untuk pilih lokasi…'
                            : _lokasiController.text,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF333333)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: _dark),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    Widget? prefixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _orange),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: _dark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
          prefixIcon: prefixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;

  const _PhotoPicker({required this.image, required this.onTap});

  static const _orange = Color(0xFFF7924A);
  static const _orangeLight = Color(0xFFFFF2E8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _orangeLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _orange, width: 1.5),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(image!, fit: BoxFit.cover))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_outlined,
                        color: _orange, size: 26),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sentuh untuk unggah foto tempat',
                    style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FasilitasPicker extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _FasilitasPicker({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  static const _orange = Color(0xFFF7924A);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((f) {
        final label = f['label'] as String;
        final icon  = f['icon']  as IconData;
        final isOn  = selected.contains(label);

        return GestureDetector(
          onTap: () => onToggle(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOn ? _orange : const Color(0xFFFFF3EC),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isOn ? _orange : const Color(0xFFFBD2B6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: isOn ? Colors.white : _orange),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOn ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}