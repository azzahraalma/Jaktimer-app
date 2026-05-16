// lib/helper/badge_helper.dart
import 'package:flutter/material.dart';
import '../helper/database_helper.dart';
import '../widgets/badge_popup.dart';

class BadgeHelper {
  static final DatabaseHelper _db = DatabaseHelper();

  // ── Definisi semua badge ─────────────────────────────────────────────────
  static const Map<String, Map<String, String>> badgeDefinitions = {
    // Level badges
    'Explorer Muda': {
      'icon': '🗺️',
      'deskripsi': 'Capai Level 1: Explorer Muda',
    },
    'Explorer Sejati': {
      'icon': '🧭',
      'deskripsi': 'Capai Level 2: Explorer Sejati',
    },
    'Penjelajah': {
      'icon': '🎒',
      'deskripsi': 'Capai Level 3: Penjelajah',
    },
    'Penjelajah Sejati': {
      'icon': '⚔️',
      'deskripsi': 'Capai Level 4: Penjelajah Sejati',
    },
    'Penakluk': {
      'icon': '👑',
      'deskripsi': 'Capai Level 5: Penakluk',
    },
    // Pencapaian badges
    'Juara Konsistensi': {
      'icon': '🔥',
      'deskripsi': 'Check-in selama 7 hari berturut-turut',
    },
    'Pengabdi Harian': {
      'icon': '📅',
      'deskripsi': 'Check-in selama 30 hari berturut-turut',
    },
    'Penggemar Budaya': {
      'icon': '🎭',
      'deskripsi': 'Baca 10 artikel budaya',
    },
    'Pecinta Kuliner': {
      'icon': '🍽️',
      'deskripsi': 'Tulis 10 ulasan kuliner',
    },
    'Pencinta Alam': {
      'icon': '🌳',
      'deskripsi': 'Tambahkan 5 ruang terbuka baru',
    },
    'Pemburu Kuliner': {
      'icon': '🍜',
      'deskripsi': 'Tambahkan 5 tempat kuliner baru',
    },
    'Penulis Ulung': {
      'icon': '✍️',
      'deskripsi': 'Tulis 50 ulasan',
    },
    'Hobi Jalan': {
      'icon': '🚶',
      'deskripsi': 'Tulis 10 ulasan ruang terbuka',
    },
    'First Explorer': {
      'icon': '🌟',
      'deskripsi': 'Pertama kali check-in',
    },
  };

  /// Cek dan award badge, return list badge baru yang berhasil diraih
  static Future<List<Map<String, String>>> checkAndAwardBadges(
      int userId) async {
    final List<Map<String, String>> newBadges = [];

    final user = await _db.getUserById(userId);
    if (user == null) return newBadges;

    final level = user['level'] as int? ?? 1;
    // levelName dipakai untuk award level badge yang sesuai level saat ini
    final levelBadgeNames = [
      'Explorer Muda',
      'Explorer Sejati',
      'Penjelajah',
      'Penjelajah Sejati',
      'Penakluk',
    ];

    // ── Level badges ─────────────────────────────────────────────────────
    if (level >= 1 && level <= 5) {
      final badgeName = levelBadgeNames[level - 1];
      final awarded = await _tryAwardBadge(userId, badgeName);
      if (awarded) {
        newBadges.add({'name': badgeName, ...badgeDefinitions[badgeName]!});
      }
    }

    // ── Check-in streak badges ───────────────────────────────────────────
    final streak = await _db.getCurrentStreak(userId);
    if (streak >= 1) {
      final awarded = await _tryAwardBadge(userId, 'First Explorer');
      if (awarded) {
        newBadges.add({
          'name': 'First Explorer',
          ...badgeDefinitions['First Explorer']!,
        });
      }
    }
    if (streak >= 7) {
      final awarded = await _tryAwardBadge(userId, 'Juara Konsistensi');
      if (awarded) {
        newBadges.add({
          'name': 'Juara Konsistensi',
          ...badgeDefinitions['Juara Konsistensi']!,
        });
      }
    }
    if (streak >= 30) {
      final awarded = await _tryAwardBadge(userId, 'Pengabdi Harian');
      if (awarded) {
        newBadges.add({
          'name': 'Pengabdi Harian',
          ...badgeDefinitions['Pengabdi Harian']!,
        });
      }
    }

    // ── Artikel / kuis badges ────────────────────────────────────────────
    final totalArtikel = await _db.getTotalArtikelDibaca(userId);
    if (totalArtikel >= 10) {
      final awarded = await _tryAwardBadge(userId, 'Penggemar Budaya');
      if (awarded) {
        newBadges.add({
          'name': 'Penggemar Budaya',
          ...badgeDefinitions['Penggemar Budaya']!,
        });
      }
    }

    // ── Ulasan badges ────────────────────────────────────────────────────
    final totalUlasan = await _db.getTotalUlasan(userId);
    if (totalUlasan >= 10) {
      final kulinerUlasan =
          await _db.getTotalUlasanByTipe(userId, 'kuliner');
      final ruangUlasan =
          await _db.getTotalUlasanByTipe(userId, 'ruang_terbuka');

      if (kulinerUlasan >= 10) {
        final awarded = await _tryAwardBadge(userId, 'Pecinta Kuliner');
        if (awarded) {
          newBadges.add({
            'name': 'Pecinta Kuliner',
            ...badgeDefinitions['Pecinta Kuliner']!,
          });
        }
      }
      if (ruangUlasan >= 10) {
        final awarded = await _tryAwardBadge(userId, 'Hobi Jalan');
        if (awarded) {
          newBadges.add({
            'name': 'Hobi Jalan',
            ...badgeDefinitions['Hobi Jalan']!,
          });
        }
      }
    }
    if (totalUlasan >= 50) {
      final awarded = await _tryAwardBadge(userId, 'Penulis Ulung');
      if (awarded) {
        newBadges.add({
          'name': 'Penulis Ulung',
          ...badgeDefinitions['Penulis Ulung']!,
        });
      }
    }

    // ── Tempat ditambahkan badges ────────────────────────────────────────
    final totalKulinerAdded = await _db.getTotalKulinerAdded(userId);
    if (totalKulinerAdded >= 5) {
      final awarded = await _tryAwardBadge(userId, 'Pemburu Kuliner');
      if (awarded) {
        newBadges.add({
          'name': 'Pemburu Kuliner',
          ...badgeDefinitions['Pemburu Kuliner']!,
        });
      }
    }
    final totalRuangAdded = await _db.getTotalRuangAdded(userId);
    if (totalRuangAdded >= 5) {
      final awarded = await _tryAwardBadge(userId, 'Pencinta Alam');
      if (awarded) {
        newBadges.add({
          'name': 'Pencinta Alam',
          ...badgeDefinitions['Pencinta Alam']!,
        });
      }
    }

    return newBadges;
  }

  static Future<bool> _tryAwardBadge(int userId, String name) async {
    final def = badgeDefinitions[name];
    if (def == null) return false;
    final existing = await _db.getUserBadges(userId);
    final alreadyHas = existing.any((b) => b['badge_name'] == name);
    if (alreadyHas) return false;
    await _db.awardBadge(userId, name, def['icon']!, def['deskripsi']!);
    return true;
  }

  /// Tampilkan badge popup satu per satu secara queue via Overlay
  static void showBadgeQueue({
    required BuildContext context,
    required List<Map<String, String>> badges,
  }) {
    if (badges.isEmpty) return;
    _showNextBadge(context, badges, 0);
  }

  static void _showNextBadge(
    BuildContext context,
    List<Map<String, String>> badges,
    int index,
  ) {
    if (index >= badges.length) return;
    if (!context.mounted) return;

    final badge = badges[index];
    final overlay = Overlay.of(context);
    OverlayEntry? entry;

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
              entry?.remove();
              entry = null;
              Future.delayed(const Duration(milliseconds: 300), () {
                _showNextBadge(context, badges, index + 1);
              });
            },
          ),
        ),
      ),
    );

    overlay.insert(entry!);
  }
}