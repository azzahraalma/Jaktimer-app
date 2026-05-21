import 'package:flutter/material.dart';
import '../data/artikel.dart';
import 'artikel_detail_screen.dart';

class SemuaArtikelScreen extends StatefulWidget {
  const SemuaArtikelScreen({super.key});

  @override
  State<SemuaArtikelScreen> createState() => _SemuaArtikelScreenState();
}

class _SemuaArtikelScreenState extends State<SemuaArtikelScreen> {
  String _selectedKategori = 'Semua';

  final List<String> _kategoriList = [
    'Semua',
    'TRADISI',
    'KULINER',
    'SENI',
    'SEJARAH',
  ];

  List<Map<String, dynamic>> get _filteredArtikel {
    if (_selectedKategori == 'Semua') return artikelData;
    return artikelData
        .where((a) => a['kategori'] == _selectedKategori)
        .toList();
  }

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
    final filtered = _filteredArtikel;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF1A1A2E),
              ),
            ),
            title: const Text(
              'Semua Artikel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _kategoriList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final k = _kategoriList[i];
                      final isSelected = _selectedKategori == k;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedKategori = k),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xffF7924A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFF7924A),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            k,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFF7924A),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '${filtered.length} artikel ditemukan',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final artikel = filtered[index];
                  final kategori = artikel['kategori'] as String? ?? '';
                  final color = _kategoriColor(kategori);

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtikelDetailScreen(artikel: artikel),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF7924A),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: Image.asset(
                                artikel['image_asset'] ?? 'assets/images/artikel/placeholder.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFF1A3C5E),
                                  child: const Center(
                                    child: Icon(
                                      Icons.article_rounded,
                                      color: Color(0xFFF7924A),
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          kategori,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        artikel['created_at'] as String? ?? '',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color.fromARGB(255, 78, 78, 78),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    artikel['judul'] as String? ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A2E),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    artikel['ringkasan'] as String? ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color.fromARGB(255, 78, 78, 78),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Row(
                                    children: [
                                      Text(
                                        'Baca selengkapnya',
                                        style: TextStyle(
                                          fontSize: 11,
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
                },
                childCount: filtered.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}