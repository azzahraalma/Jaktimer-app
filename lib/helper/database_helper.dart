import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/artikel.dart';
import '../data/kuis_harian.dart';
import '../data/dummy_kuliner.dart';
import '../data/dummy_ruang_terbuka.dart';
import '../data/ulasan_kuliner.dart';
import '../data/ulasan_ruang.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'jaktimer.db');
    return await openDatabase(
      path,
      version: 12, // bump version agar onUpgrade jalan
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MIGRATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 12) {
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS kuliner');
      await db.execute('DROP TABLE IF EXISTS ruang_terbuka');
      await db.execute('DROP TABLE IF EXISTS ulasan');
      await db.execute('DROP TABLE IF EXISTS ulasan_ruang');
      await db.execute('DROP TABLE IF EXISTS artikel');
      await db.execute('DROP TABLE IF EXISTS kuis');
      await db.execute('DROP TABLE IF EXISTS kuis_log');
      await db.execute('DROP TABLE IF EXISTS kuis_harian_log');
      await db.execute('DROP TABLE IF EXISTS xp_log');
      await db.execute('DROP TABLE IF EXISTS daily_checkin');
      await db.execute('DROP TABLE IF EXISTS badges');
      await db.execute('DROP TABLE IF EXISTS misi_log');
      await _createTables(db, newVersion);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE TABLES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        avatar_url TEXT,
        image_path TEXT,
        level INTEGER DEFAULT 1,
        xp INTEGER DEFAULT 0,
        level_name TEXT DEFAULT 'Explorer Muda',
        security_question TEXT,
        security_answer TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ── image_url → image_asset ────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE kuliner (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        deskripsi TEXT,
        alamat TEXT,
        kecamatan TEXT,
        kategori TEXT,
        harga_min INTEGER,
        harga_max INTEGER,
        rating REAL DEFAULT 0,
        jumlah_ulasan INTEGER DEFAULT 0,
        image_asset TEXT,
        latitude REAL,
        longitude REAL,
        jam_buka TEXT,
        jam_tutup TEXT,
        fasilitas TEXT DEFAULT '',
        is_populer INTEGER DEFAULT 0,
        added_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ── image_url → image_asset ────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE ruang_terbuka (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        deskripsi TEXT,
        alamat TEXT,
        kecamatan TEXT,
        kategori TEXT,
        fasilitas TEXT,
        tags TEXT,
        jam_buka TEXT,
        jam_tutup TEXT,
        rating REAL DEFAULT 0,
        jumlah_ulasan INTEGER DEFAULT 0,
        image_asset TEXT,
        latitude REAL,
        longitude REAL,
        tiket TEXT DEFAULT 'Gratis',
        is_populer INTEGER DEFAULT 0,
        added_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE ulasan_ruang (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ruang_id INTEGER,
        tempat_nama TEXT,
        nama_user TEXT,
        komentar TEXT,
        rating REAL,
        tanggal TEXT,
        FOREIGN KEY (ruang_id) REFERENCES ruang_terbuka(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ulasan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        tempat_id INTEGER,
        tipe TEXT NOT NULL,
        rating INTEGER,
        komentar TEXT,
        username TEXT,
        avatar_url TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE artikel (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        judul TEXT NOT NULL,
        isi TEXT NOT NULL,
        kategori TEXT,
        image_asset TEXT,
        author TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE kuis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        artikel_id INTEGER,
        pertanyaan TEXT NOT NULL,
        pilihan_a TEXT,
        pilihan_b TEXT,
        pilihan_c TEXT,
        pilihan_d TEXT,
        jawaban_benar TEXT,
        xp_reward INTEGER DEFAULT 50,
        tanggal TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE kuis_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        artikel_id INTEGER NOT NULL,
        jawaban_index INTEGER,
        is_benar INTEGER DEFAULT 0,
        xp_earned INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, artikel_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE kuis_harian_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        kuis_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        jawaban_index INTEGER,
        is_benar INTEGER DEFAULT 0,
        xp_earned INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, tanggal)
      )
    ''');

    await db.execute('''
      CREATE TABLE xp_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        xp INTEGER,
        keterangan TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_checkin (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        tanggal TEXT,
        streak INTEGER DEFAULT 1,
        xp INTEGER DEFAULT 10,
        UNIQUE(user_id, tanggal)
      )
    ''');

    await db.execute('''
      CREATE TABLE badges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        badge_name TEXT,
        badge_icon TEXT,
        deskripsi TEXT,
        earned_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE misi_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        misi_kode TEXT,
        tanggal TEXT,
        UNIQUE(user_id, misi_kode, tanggal)
      )
    ''');

    await _insertDummyData(db);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEED DATA
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _seedKuisFromJson(Database db) async {
    for (final a in artikelData) {
      final kuis = a['kuis'] as Map<String, dynamic>?;
      if (kuis == null) continue;
      final pilihan = List<String>.from(kuis['pilihan'] as List);
      final jawabanBenar = kuis['jawaban_benar'] as int;
      final jawabanHuruf = ['A', 'B', 'C', 'D'][jawabanBenar];
      await db.insert('kuis', {
        'artikel_id': a['id'],
        'pertanyaan': kuis['pertanyaan'],
        'pilihan_a': pilihan.isNotEmpty ? pilihan[0] : null,
        'pilihan_b': pilihan.length > 1 ? pilihan[1] : null,
        'pilihan_c': pilihan.length > 2 ? pilihan[2] : null,
        'pilihan_d': pilihan.length > 3 ? pilihan[3] : null,
        'jawaban_benar': jawabanHuruf,
        'xp_reward': kuis['xp_reward'] ?? 50,
        'tanggal': null,
      });
    }
  }

  Future<void> _insertDummyData(Database db) async {
    await db.insert('users', {
      'username': 'Timo',
      'email': 'timoimut@jaktimer.com',
      'password': 'password123',
      'level': 1,
      'xp': 0,
      'level_name': 'Explorer Muda',
      'avatar_url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Timo',
      'image_path': null,
      'security_question': 'Nama hewan peliharaan pertamamu?',
      'security_answer': 'kucing',
    });

    for (final k in dummyKulinerData) {
      // Sanitize: pastikan latitude ada (HALWA KITCHEN tidak punya)
      final row = Map<String, dynamic>.from(k);
      row['latitude'] ??= 0.0;
      row['longitude'] ??= 0.0;
      await db.insert('kuliner', row);
    }

    for (final r in dummyRuangTerbukaData) {
      await db.insert('ruang_terbuka', r);
    }

    for (final u in DummyUlasanKuliner) {
      await db.insert('ulasan', u);
    }

    for (final u in dummyUlasanRuangData) {
      await db.insert('ulasan_ruang', u);
    }

    await _seedKuisFromJson(db);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER
  // ═══════════════════════════════════════════════════════════════════════════

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _levelFromXp(int xp) {
    if (xp >= 5000) return 5;
    if (xp >= 3000) return 4;
    if (xp >= 2000) return 3;
    if (xp >= 1000) return 2;
    return 1;
  }

  static String _levelNameFromLevel(int level) {
    switch (level) {
      case 5:
        return 'Penakluk';
      case 4:
        return 'Penjelajah Sejati';
      case 3:
        return 'Penjelajah';
      case 2:
        return 'Explorer Sejati';
      default:
        return 'Explorer Muda';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTIKEL
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> getAllArtikel() => List.from(artikelData);

  List<Map<String, dynamic>> getArtikelByKategori(String kategori) {
    if (kategori == 'Semua') return getAllArtikel();
    return artikelData.where((a) => a['kategori'] == kategori).toList();
  }

  Map<String, dynamic>? getArtikelByIdJson(int id) {
    try {
      return artikelData.firstWhere((a) => a['id'] == id);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> getRandomArtikel(int count) {
    final list = List<Map<String, dynamic>>.from(artikelData);
    list.shuffle();
    return list.take(count).toList();
  }

  Future<List<Map<String, dynamic>>> getArtikel() async => getAllArtikel();
  Future<Map<String, dynamic>?> getArtikelById(int id) async =>
      getArtikelByIdJson(id);

  // ═══════════════════════════════════════════════════════════════════════════
  // KUIS ARTIKEL
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> hasKuisCompleted(int userId, int artikelId) async {
    final db = await database;
    final res = await db.query(
      'kuis_log',
      where: 'user_id = ? AND artikel_id = ?',
      whereArgs: [userId, artikelId],
    );
    return res.isNotEmpty;
  }

  Future<void> saveKuisResult({
    required int userId,
    required int artikelId,
    required int jawabanIndex,
    required bool isBenar,
    required int xpEarned,
  }) async {
    final db = await database;
    await db.insert(
      'kuis_log',
      {
        'user_id': userId,
        'artikel_id': artikelId,
        'jawaban_index': jawabanIndex,
        'is_benar': isBenar ? 1 : 0,
        'xp_earned': xpEarned,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    if (isBenar) {
      await updateUserXp(userId, xpEarned);
      await logXp(userId, xpEarned, 'Kuis Artikel #$artikelId');
    }
  }

  Future<List<int>> getCompletedKuisArtikelIds(int userId) async {
    final db = await database;
    final res = await db.query(
      'kuis_log',
      columns: ['artikel_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return res.map((r) => r['artikel_id'] as int).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KUIS HARIAN
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> getKuisHarianUntukUser(int userId) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final seed = userId * 1000 + now.year;
    final indices = List<int>.generate(kuisHarianData.length, (i) => i);
    indices.shuffle(Random(seed));
    final soalIndex = indices[dayOfYear % kuisHarianData.length];
    return kuisHarianData[soalIndex];
  }

  Future<bool> hasKuisHarianSelesaiHariIni(int userId) async {
    final db = await database;
    final tanggal = _formatDate(DateTime.now());
    final res = await db.query(
      'kuis_harian_log',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
    );
    return res.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getHasilKuisHarianHariIni(int userId) async {
    final db = await database;
    final tanggal = _formatDate(DateTime.now());
    final res = await db.query(
      'kuis_harian_log',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> saveKuisHarianResult({
    required int userId,
    required int kuisId,
    required int jawabanIndex,
    required bool isBenar,
  }) async {
    final db = await database;
    final tanggal = _formatDate(DateTime.now());
    final xpEarned = isBenar ? 50 : 10;
    try {
      await db.insert(
        'kuis_harian_log',
        {
          'user_id': userId,
          'kuis_id': kuisId,
          'tanggal': tanggal,
          'jawaban_index': jawabanIndex,
          'is_benar': isBenar ? 1 : 0,
          'xp_earned': xpEarned,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await updateUserXp(userId, xpEarned);
      await logXp(
        userId,
        xpEarned,
        isBenar ? 'Kuis Harian Benar 🎉' : 'Kuis Harian (tetap semangat!)',
      );
      return xpEarned;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getRiwayatKuisHarian(int userId,
      {int limit = 7}) async {
    final db = await database;
    return await db.query(
      'kuis_harian_log',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC',
      limit: limit,
    );
  }

  Future<Map<String, int>> getStatistikKuisHarian(int userId) async {
    final db = await database;
    final all = await db
        .query('kuis_harian_log', where: 'user_id = ?', whereArgs: [userId]);
    final totalDikerjakan = all.length;
    final totalBenar = all.where((r) => (r['is_benar'] as int) == 1).length;
    return {
      'total_dikerjakan': totalDikerjakan,
      'total_benar': totalBenar,
      'total_salah': totalDikerjakan - totalBenar,
    };
  }

  Future<int> getStreakKuisHarian(int userId) async {
    final db = await database;
    final rows = await db.query(
      'kuis_harian_log',
      columns: ['tanggal'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC',
    );
    if (rows.isEmpty) return 0;
    int streak = 0;
    DateTime check = DateTime.now();
    for (final row in rows) {
      final tanggal = DateTime.parse(row['tanggal'] as String);
      final diff = check.difference(tanggal).inDays;
      if (diff <= 1) {
        streak++;
        check = tanggal;
      } else {
        break;
      }
    }
    return streak;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KULINER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getKuliner({
    String? search,
    String? kategori,
    String? sortBy,
  }) async {
    final db = await database;
    String query = 'SELECT * FROM kuliner';
    final List<dynamic> args = [];
    final List<String> conditions = [];

    if (search != null && search.isNotEmpty) {
      conditions.add('(nama LIKE ? OR alamat LIKE ? OR kategori LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    if (kategori != null && kategori != 'Semua') {
      conditions.add('kategori = ?');
      args.add(kategori);
    }
    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }
    if (sortBy == 'Rating Tertinggi') {
      query += ' ORDER BY rating DESC';
    } else if (sortBy == 'Termurah') {
      query += ' ORDER BY harga_min ASC';
    } else {
      query += ' ORDER BY is_populer DESC, rating DESC';
    }
    return await db.rawQuery(query, args);
  }

  Future<Map<String, dynamic>?> getKulinerById(int id) async {
    final db = await database;
    final res = await db.query('kuliner', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> insertKuliner(Map<String, dynamic> kuliner) async {
    final db = await database;
    return await db.insert('kuliner', kuliner);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RUANG TERBUKA
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getRuangTerbuka({
    String? search,
    String? sortBy,
  }) async {
    final db = await database;
    String query = 'SELECT * FROM ruang_terbuka';
    final List<dynamic> args = [];

    if (search != null && search.isNotEmpty) {
      query += ' WHERE (nama LIKE ? OR alamat LIKE ? OR kategori LIKE ?)';
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    if (sortBy == 'Rating Tertinggi') {
      query += ' ORDER BY rating DESC';
    } else {
      query += ' ORDER BY is_populer DESC, rating DESC';
    }
    return await db.rawQuery(query, args);
  }

  Future<Map<String, dynamic>?> getRuangTerbukaById(int id) async {
    final db = await database;
    final res =
        await db.query('ruang_terbuka', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> insertRuangTerbuka(Map<String, dynamic> ruang) async {
    final db = await database;
    return await db.insert('ruang_terbuka', ruang);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ULASAN
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getUlasan(
      int tempatId, String tipe) async {
    final db = await database;
    return await db.query(
      'ulasan',
      where: 'tempat_id = ? AND tipe = ?',
      whereArgs: [tempatId, tipe],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> insertUlasan(Map<String, dynamic> ulasan) async {
    final db = await database;
    return await db.insert('ulasan', ulasan);
  }

  Future<int> insertUlasanRuang(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('ulasan_ruang', data);
  }

  Future<List<Map<String, dynamic>>> getUlasanByRuangId(int ruangId) async {
    final db = await database;
    return await db.query(
      'ulasan_ruang',
      where: 'ruang_id = ?',
      whereArgs: [ruangId],
      orderBy: 'id DESC',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, dynamic>?> loginUser(
      String email, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> registerUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<void> updateUsernameEmail(
      int userId, String newUsername, String newEmail) async {
    final db = await database;
    final existing = await db.query(
      'users',
      where: 'email = ? AND id != ?',
      whereArgs: [newEmail, userId],
    );
    if (existing.isNotEmpty) {
      throw Exception('Email sudah digunakan akun lain.');
    }
    await db.update(
      'users',
      {'username': newUsername, 'email': newEmail},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> updatePassword(
      int userId, String oldPassword, String newPassword) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [userId, oldPassword],
    );
    if (res.isEmpty) return false;
    await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return true;
  }

  Future<String?> getSecurityQuestion(String email) async {
    final db = await database;
    final res = await db.query(
      'users',
      columns: ['security_question'],
      where: 'email = ?',
      whereArgs: [email],
    );
    if (res.isEmpty) return null;
    return res.first['security_question'] as String?;
  }

  Future<bool> resetPasswordWithSecurityAnswer({
    required String email,
    required String answer,
    required String newPassword,
  }) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (res.isEmpty) return false;
    final storedAnswer =
        (res.first['security_answer'] as String? ?? '').toLowerCase().trim();
    if (storedAnswer != answer.toLowerCase().trim()) return false;
    await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
    return true;
  }

  Future<void> updateUserImagePath(int userId, String imagePath) async {
    final db = await database;
    await db.update(
      'users',
      {'image_path': imagePath},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateUserXp(int userId, int xpToAdd) async {
    final db = await database;
    final user = await getUserById(userId);
    if (user == null) return;

    final newXp = (user['xp'] as int) + xpToAdd;
    final newLevel = _levelFromXp(newXp);
    final newLevelName = _levelNameFromLevel(newLevel);

    await db.update(
      'users',
      {'xp': newXp, 'level': newLevel, 'level_name': newLevelName},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateUserProfile(
      int userId, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('users', data, where: 'id = ?', whereArgs: [userId]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAILY CHECKIN
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> dailyCheckin(int userId) async {
    final db = await database;
    final today = _formatDate(DateTime.now());

    final existing = await db.query(
      'daily_checkin',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, today],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;

    final yesterday =
        _formatDate(DateTime.now().subtract(const Duration(days: 1)));
    final yesterdayRow = await db.query(
      'daily_checkin',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, yesterday],
      limit: 1,
    );

    final lastStreak = yesterdayRow.isNotEmpty
        ? (yesterdayRow.first['streak'] as int? ?? 0)
        : 0;
    final newStreak = lastStreak + 1;
    final xp = _xpForStreak(newStreak);

    await db.insert('daily_checkin', {
      'user_id': userId,
      'tanggal': today,
      'streak': newStreak,
      'xp': xp,
    });

    await updateUserXp(userId, xp);
    await logXp(userId, xp, 'Daily Check-in 📅 (streak $newStreak)');

    return true;
  }

  Future<bool> hasCheckedInToday(int userId) async {
    final db = await database;
    final tanggal = _formatDate(DateTime.now());
    final res = await db.query(
      'daily_checkin',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
    );
    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getWeeklyCheckin(int userId) async {
    final db = await database;
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));

    const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final startDate = _formatDate(monday);
    final endDate = _formatDate(monday.add(const Duration(days: 6)));

    final weekRows = await db.query(
      'daily_checkin',
      where: 'user_id = ? AND tanggal >= ? AND tanggal <= ?',
      whereArgs: [userId, startDate, endDate],
    );
    final Map<String, Map<String, dynamic>> checkinByDate = {
      for (final r in weekRows) r['tanggal'] as String: r,
    };

    final allRows = await db.query(
      'daily_checkin',
      columns: ['tanggal', 'streak'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal ASC',
    );

    int runningStreak = 0;
    if (allRows.isNotEmpty) {
      final mondayDate = monday;
      final rowsBeforeThisWeek = allRows.where((r) {
        final d = DateTime.parse(r['tanggal'] as String);
        return d.isBefore(mondayDate);
      }).toList();

      if (rowsBeforeThisWeek.isNotEmpty) {
        final lastRow = rowsBeforeThisWeek.last;
        final lastDate = DateTime.parse(lastRow['tanggal'] as String);
        final diffToMonday = mondayDate.difference(lastDate).inDays;
        if (diffToMonday == 1) {
          runningStreak = lastRow['streak'] as int? ?? 0;
        }
      }
    }

    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final dateStr = _formatDate(date);
      final row = checkinByDate[dateStr];

      if (row != null) {
        final streak = row['streak'] as int? ?? 1;
        final xp = row['xp'] as int? ?? _xpForStreak(streak);
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

  Future<int> getCurrentStreak(int userId) async {
    final db = await database;
    final today = _formatDate(DateTime.now());
    final res = await db.query(
      'daily_checkin',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, today],
      limit: 1,
    );
    if (res.isNotEmpty) return res.first['streak'] as int;

    final yesterday =
        _formatDate(DateTime.now().subtract(const Duration(days: 1)));
    final res2 = await db.query(
      'daily_checkin',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, yesterday],
      limit: 1,
    );
    return res2.isNotEmpty ? res2.first['streak'] as int : 0;
  }

  int _xpForStreak(int streak) => xpForStreak(streak);

  Future<bool> isStreakBroken(int userId) async {
    final db = await database;
    final yesterday = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final today = _formatDate(DateTime.now());

    final todayRow = await db.query(
      'daily_checkin',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, today],
      limit: 1,
    );
    if (todayRow.isNotEmpty) return false;

    final yesterdayRow = await db.query(
      'daily_checkin',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, yesterday],
      limit: 1,
    );
    if (yesterdayRow.isNotEmpty) return false;

    final anyRow = await db.query(
      'daily_checkin',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return anyRow.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BADGES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getUserBadges(int userId) async {
    final db = await database;
    return await db.query('badges', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> awardBadge(
      int userId, String name, String icon, String deskripsi) async {
    final db = await database;
    final existing = await db.query(
      'badges',
      where: 'user_id = ? AND badge_name = ?',
      whereArgs: [userId, name],
    );
    if (existing.isEmpty) {
      await db.insert('badges', {
        'user_id': userId,
        'badge_name': name,
        'badge_icon': icon,
        'deskripsi': deskripsi,
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> searchAll(String query) async {
    final db = await database;
    final kuliner = await db.rawQuery(
      "SELECT *, 'kuliner' as tipe FROM kuliner WHERE nama LIKE ? OR alamat LIKE ? LIMIT 10",
      ['%$query%', '%$query%'],
    );
    final ruang = await db.rawQuery(
      "SELECT *, 'ruang_terbuka' as tipe FROM ruang_terbuka WHERE nama LIKE ? OR alamat LIKE ? LIMIT 10",
      ['%$query%', '%$query%'],
    );
    final artikelHits = artikelData
        .where((a) =>
            (a['judul'] as String)
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            (a['ringkasan'] as String? ?? '')
                .toLowerCase()
                .contains(query.toLowerCase()))
        .take(10)
        .map((a) => {...a, 'tipe': 'artikel'})
        .toList();
    return [...kuliner, ...ruang, ...artikelHits];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MISI
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> completeMisi(int userId, String misiKode) async {
    final db = await database;
    final tanggal = _formatDate(DateTime.now());
    try {
      await db.insert(
        'misi_log',
        {'user_id': userId, 'misi_kode': misiKode, 'tanggal': tanggal},
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isMisiCompleted(int userId, String misiKode) async {
    final db = await database;
    final tanggal = _formatDate(DateTime.now());
    final res = await db.query(
      'misi_log',
      where: 'user_id = ? AND misi_kode = ? AND tanggal = ?',
      whereArgs: [userId, misiKode, tanggal],
    );
    return res.isNotEmpty;
  }

  Future<List<String>> getMisiSelesaiHariIni(int userId) async {
    final db = await database;
    final tanggal = _formatDate(DateTime.now());
    final res = await db.query(
      'misi_log',
      columns: ['misi_kode'],
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
    );
    return res.map((r) => r['misi_kode'] as String).toList();
  }

  Future<int> getTotalMisiXpHariIni(int userId) async {
    final db = await database;
    final tanggal = _formatDate(DateTime.now());
    final res = await db.rawQuery(
      "SELECT SUM(xp) as total FROM xp_log WHERE user_id = ? AND created_at LIKE ?",
      [userId, '$tanggal%'],
    );
    return (res.first['total'] as int?) ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // XP LOG
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> logXp(int userId, int xp, String keterangan) async {
    final db = await database;
    await db.insert('xp_log', {
      'user_id': userId,
      'xp': xp,
      'keterangan': keterangan,
    });
  }

  int xpForStreak(int streak) {
    const xpList = [10, 15, 20, 25, 30, 35, 50];
    if (streak <= 0) return xpList[0];
    if (streak <= xpList.length) return xpList[streak - 1];
    return xpList.last;
  }

  Future<List<Map<String, dynamic>>> getXpLog(int userId) async {
    final db = await database;
    return await db.query(
      'xp_log',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 20,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATISTIK USER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<int> getTotalTempat(int userId) async {
    final db = await database;
    final r1 = await db.rawQuery(
        'SELECT COUNT(*) as c FROM kuliner WHERE added_by = ?', [userId]);
    final r2 = await db.rawQuery(
        'SELECT COUNT(*) as c FROM ruang_terbuka WHERE added_by = ?', [userId]);
    return (r1.first['c'] as int) + (r2.first['c'] as int);
  }

  Future<int> getTotalUlasan(int userId) async {
    final db = await database;
    final res = await db.rawQuery(
        'SELECT COUNT(*) as c FROM ulasan WHERE user_id = ?', [userId]);
    return res.first['c'] as int;
  }

  Future<int> getTotalArtikelDibaca(int userId) async {
    final db = await database;
    final res = await db.rawQuery(
        'SELECT COUNT(*) as c FROM kuis_log WHERE user_id = ?', [userId]);
    return res.first['c'] as int;
  }

  Future<int> getTotalKuisBenar(int userId) async {
    final db = await database;
    final r1 = await db.rawQuery(
        'SELECT COUNT(*) as c FROM kuis_log WHERE user_id = ? AND is_benar = 1',
        [userId]);
    final r2 = await db.rawQuery(
        'SELECT COUNT(*) as c FROM kuis_harian_log WHERE user_id = ? AND is_benar = 1',
        [userId]);
    return (r1.first['c'] as int) + (r2.first['c'] as int);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getKuisHariIni() async =>
      getKuisHarianUntukUser(1);

  Future<int> getTotalUlasanByTipe(int userId, String tipe) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ulasan WHERE user_id = ? AND tipe = ?',
      [userId, tipe],
    );
    return res.first['c'] as int;
  }

  Future<int> getTotalKulinerAdded(int userId) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as c FROM kuliner WHERE added_by = ?',
      [userId],
    );
    return res.first['c'] as int;
  }

  Future<int> getTotalRuangAdded(int userId) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ruang_terbuka WHERE added_by = ?',
      [userId],
    );
    return res.first['c'] as int;
  }
}