import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference get _users => _db.collection('users');

  static DocumentReference _userDoc(String uid) => _users.doc(uid);

  static CollectionReference _sub(String uid, String col) =>
      _userDoc(uid).collection(col);

  static Future<void> createUserDocument({
    required String uid,
    required String username,
    required String email,
  }) async {
    await _userDoc(uid).set({
      'uid': uid,
      'username': username,
      'email': email,
      'level': 1,
      'xp': 0,
      'level_name': 'Explorer Muda',
      'avatar_url': 'https://api.dicebear.com/7.x/adventurer/png?seed=$username',
      'image_path': null,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    return snap.data() as Map<String, dynamic>;
  }

  static Stream<Map<String, dynamic>?> userStream(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return snap.data() as Map<String, dynamic>;
    });
  }

  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _userDoc(uid).update(data);
  }

  static Future<void> updateUsernameEmail(
      String uid, String username, String email) async {
    await _userDoc(uid).update({'username': username, 'email': email});
  }

  static Future<void> updateImagePath(String uid, String? path) async {
    await _userDoc(uid).update({'image_path': path});
  }

  static int levelFromXp(int xp) {
    if (xp >= 5000) return 5;
    if (xp >= 3000) return 4;
    if (xp >= 2000) return 3;
    if (xp >= 1000) return 2;
    return 1;
  }

  static String levelNameFromLevel(int level) {
    switch (level) {
      case 5: return 'Penakluk';
      case 4: return 'Penjelajah Sejati';
      case 3: return 'Penjelajah';
      case 2: return 'Explorer Sejati';
      default: return 'Explorer Muda';
    }
  }

  static Future<void> addXp(String uid, int xpToAdd, {String keterangan = ''}) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final currentXp = (data['xp'] as num? ?? 0).toInt();
    final newXp = currentXp + xpToAdd;
    final newLevel = levelFromXp(newXp);
    final newLevelName = levelNameFromLevel(newLevel);

    await _userDoc(uid).update({
      'xp': newXp,
      'level': newLevel,
      'level_name': newLevelName,
    });

    if (keterangan.isNotEmpty) {
      await _sub(uid, 'xp_log').add({
        'xp': xpToAdd,
        'keterangan': keterangan,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<List<Map<String, dynamic>>> getXpLog(String uid) async {
    final snap = await _sub(uid, 'xp_log')
        .orderBy('created_at', descending: true)
        .limit(20)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _xpForStreak(int streak) {
    const xpList = [10, 15, 20, 25, 30, 35, 50];
    if (streak <= 0) return xpList[0];
    if (streak <= xpList.length) return xpList[streak - 1];
    return xpList.last;
  }

  static Future<bool> dailyCheckin(String uid) async {
    final today = _todayStr();
    final ref = _sub(uid, 'daily_checkin').doc(today);
    final existing = await ref.get();
    if (existing.exists) return false;

    final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    final yDoc = await _sub(uid, 'daily_checkin').doc(yesterday).get();
    final lastStreak = yDoc.exists ? (yDoc.data() as Map)['streak'] as int? ?? 0 : 0;
    final newStreak = lastStreak + 1;
    final xp = _xpForStreak(newStreak);

    await ref.set({
      'tanggal': today,
      'streak': newStreak,
      'xp': xp,
      'created_at': FieldValue.serverTimestamp(),
    });

    await addXp(uid, xp, keterangan: 'Daily Check-in 📅 (streak $newStreak)');
    return true;
  }

  static Future<bool> hasCheckedInToday(String uid) async {
    final ref = _sub(uid, 'daily_checkin').doc(_todayStr());
    return (await ref.get()).exists;
  }

  static Future<int> getCurrentStreak(String uid) async {
    final today = _todayStr();
    final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));

    final todayDoc = await _sub(uid, 'daily_checkin').doc(today).get();
    if (todayDoc.exists) {
      return (todayDoc.data() as Map)['streak'] as int? ?? 0;
    }
    final yDoc = await _sub(uid, 'daily_checkin').doc(yesterday).get();
    if (yDoc.exists) {
      return (yDoc.data() as Map)['streak'] as int? ?? 0;
    }
    return 0;
  }

  static Future<bool> isStreakBroken(String uid) async {
    final today = _todayStr();
    final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));

    if ((await _sub(uid, 'daily_checkin').doc(today).get()).exists) return false;
    if ((await _sub(uid, 'daily_checkin').doc(yesterday).get()).exists) return false;

    final any = await _sub(uid, 'daily_checkin').limit(1).get();
    return any.docs.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> getWeeklyCheckin(String uid) async {
    const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final List<Map<String, dynamic>> result = [];
    int runningStreak = 0;

    final beforeMonday = _dateStr(monday.subtract(const Duration(days: 1)));
    final beforeDoc = await _sub(uid, 'daily_checkin').doc(beforeMonday).get();
    if (beforeDoc.exists) {
      runningStreak = (beforeDoc.data() as Map)['streak'] as int? ?? 0;
    }

    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final dateStr = _dateStr(date);
      final doc = await _sub(uid, 'daily_checkin').doc(dateStr).get();

      if (doc.exists) {
        final streak = (doc.data() as Map)['streak'] as int? ?? 1;
        final xp = (doc.data() as Map)['xp'] as int? ?? _xpForStreak(streak);
        runningStreak = streak;
        result.add({
          'day': dayLabels[i],
          'date': dateStr,
          'checked': true,
          'xp': xp,
          'streak': streak,
        });
      } else {
        final projectedStreak = runningStreak + 1;
        runningStreak = projectedStreak;
        result.add({
          'day': dayLabels[i],
          'date': dateStr,
          'checked': false,
          'xp': _xpForStreak(projectedStreak),
          'streak': 0,
        });
      }
    }
    return result;
  }

  static Future<List<Map<String, dynamic>>> getUserBadges(String uid) async {
    final snap = await _sub(uid, 'badges').get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  static Future<void> awardBadge(String uid, String name, String icon, String deskripsi) async {
    final existing = await _sub(uid, 'badges')
        .where('badge_name', isEqualTo: name)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _sub(uid, 'badges').add({
      'badge_name': name,
      'badge_icon': icon,
      'deskripsi': deskripsi,
      'earned_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<bool> hasKuisHarianSelesaiHariIni(String uid) async {
    final today = _todayStr();
    final snap = await _sub(uid, 'kuis_harian_log')
        .where('tanggal', isEqualTo: today)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getHasilKuisHarianHariIni(String uid) async {
    final today = _todayStr();
    final snap = await _sub(uid, 'kuis_harian_log')
        .where('tanggal', isEqualTo: today)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data() as Map<String, dynamic>;
  }

  static Future<int> saveKuisHarianResult({
    required String uid,
    required int kuisId,
    required int jawabanIndex,
    required bool isBenar,
  }) async {
    final today = _todayStr();
    final existing = await _sub(uid, 'kuis_harian_log')
        .where('tanggal', isEqualTo: today)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return 0;

    final xpEarned = isBenar ? 50 : 10;
    await _sub(uid, 'kuis_harian_log').add({
      'kuis_id': kuisId,
      'tanggal': today,
      'jawaban_index': jawabanIndex,
      'is_benar': isBenar,
      'xp_earned': xpEarned,
      'created_at': FieldValue.serverTimestamp(),
    });
    await addXp(uid, xpEarned, keterangan: isBenar ? 'Kuis Harian Benar 🎉' : 'Kuis Harian (tetap semangat!)');
    return xpEarned;
  }

  static Future<bool> hasArtikelXpClaimed(String uid) async {
    final today = _todayStr();
    final snap = await _sub(uid, 'artikel_log')
        .where('tanggal', isEqualTo: today)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  static Future<void> claimArtikelXp(String uid) async {
    final today = _todayStr();
    await _sub(uid, 'artikel_log').add({
      'tanggal': today,
      'created_at': FieldValue.serverTimestamp(),
    });
    await addXp(uid, 50, keterangan: 'Baca Artikel 📖');
  }

  static Future<bool> completeMisi(String uid, String misiKode) async {
    final today = _todayStr();
    final existing = await _sub(uid, 'misi_log')
        .where('misi_kode', isEqualTo: misiKode)
        .where('tanggal', isEqualTo: today)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return false;

    await _sub(uid, 'misi_log').add({
      'misi_kode': misiKode,
      'tanggal': today,
      'created_at': FieldValue.serverTimestamp(),
    });
    return true;
  }

  static Future<bool> isMisiCompleted(String uid, String misiKode) async {
    final today = _todayStr();
    final snap = await _sub(uid, 'misi_log')
        .where('misi_kode', isEqualTo: misiKode)
        .where('tanggal', isEqualTo: today)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  static Future<List<String>> getMisiSelesaiHariIni(String uid) async {
    final today = _todayStr();
    final snap = await _sub(uid, 'misi_log')
        .where('tanggal', isEqualTo: today)
        .get();
    return snap.docs.map((d) => (d.data() as Map)['misi_kode'] as String).toList();
  }

  static Future<int> getTotalArtikelDibaca(String uid) async {
    final snap = await _sub(uid, 'artikel_log').get();
    return snap.docs.length;
  }

  static Future<int> getTotalKuisBenar(String uid) async {
    final snap = await _sub(uid, 'kuis_harian_log')
        .where('is_benar', isEqualTo: true)
        .get();
    return snap.docs.length;
  }

  static Future<int> getTotalTempat(String uid) async {
    final kuliner = await _db.collection('kuliner')
        .where('added_by', isEqualTo: uid)
        .get();
    final ruang = await _db.collection('ruang_terbuka')
        .where('added_by', isEqualTo: uid)
        .get();
    return kuliner.docs.length + ruang.docs.length;
  }

  static Future<int> getTotalUlasan(String uid) async {
    final snap = await _db.collection('ulasan')
        .where('user_id', isEqualTo: uid)
        .get();
    return snap.docs.length;
  }

  static Future<int> getTotalUlasanByTipe(String uid, String tipe) async {
    final snap = await _db.collection('ulasan')
        .where('user_id', isEqualTo: uid)
        .where('tipe', isEqualTo: tipe)
        .get();
    return snap.docs.length;
  }

  static Future<int> getTotalKulinerAdded(String uid) async {
    final snap = await _db.collection('kuliner')
        .where('added_by', isEqualTo: uid)
        .get();
    return snap.docs.length;
  }

  static Future<int> getTotalRuangAdded(String uid) async {
    final snap = await _db.collection('ruang_terbuka')
        .where('added_by', isEqualTo: uid)
        .get();
    return snap.docs.length;
  }
}
