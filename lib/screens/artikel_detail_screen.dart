import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ArtikelDetailScreen extends StatelessWidget {
  final Map<String, dynamic> artikel;

  const ArtikelDetailScreen({super.key, required this.artikel});

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

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 235, 222),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
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
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    artikel['image_asset'] ?? 'assets/images/artikel/placeholder.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200, 
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

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            kategori,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artikel['judul'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_outline_rounded,
                                size: 16, color: color),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artikel['author'] as String? ?? 'Redaksi',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              Text(
                                artikel['created_at'] as String? ?? '',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade100, height: 1),
                      const SizedBox(height: 16),

                      if (artikel['ringkasan'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.format_quote_rounded,
                                  color: color, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  artikel['ringkasan'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: color.withOpacity(0.9),
                                    fontStyle: FontStyle.italic,
                                    height: 1.55,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Text(
                        artikel['isi'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF333333),
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}