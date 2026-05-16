// lib/data/kuis_harian_data.dart
//
// 30 soal kuis harian budaya Jakarta Timur.
// Setiap soal punya: id, pertanyaan, pilihan (4), jawaban_benar (index 0-3),
// penjelasan (ditampilkan kalau jawaban salah), kategori.
//
// Sistem rotasi: shuffle 30 soal di awal bulan (seed = userId + bulan + tahun),
// lalu tampilkan 1 soal per hari secara berurutan selama 30 hari.
// Dengan seed unik per user, urutan soal berbeda antar user.

const List<Map<String, dynamic>> kuisHarianData = [
  {
    'id': 1,
    'pertanyaan': 'Apa arti harfiah dari istilah "Gotong Royong" yang menjadi kearifan lokal kita?',
    'pilihan': [
      'Bekerja sendirian untuk hasil maksimal',
      'Mengangkat beban bersama-sama',
      'Bersaing secara sehat antar warga',
      'Menghormati orang yang lebih tua',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Gotong Royong berasal dari kata "gotong" (mengangkat) dan "royong" (bersama). Filosofi ini berarti memikul beban secara bersama-sama, mencerminkan semangat kolektif masyarakat Betawi dan Jawa yang mengutamakan kebersamaan di atas kepentingan pribadi.',
    'kategori': 'TRADISI',
  },
  {
    'id': 2,
    'pertanyaan': 'Bir Pletok adalah minuman tradisional Betawi yang terbuat dari campuran...',
    'pilihan': [
      'Alkohol fermentasi beras ketan',
      'Rempah-rempah seperti jahe, serai, dan kayu manis',
      'Sari buah nipa fermentasi',
      'Teh hitam dengan gula aren',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Meskipun namanya mengandung kata "bir", Bir Pletok sama sekali tidak mengandung alkohol. Minuman ini terbuat dari rempah seperti jahe, serai, kayu manis, kapulaga, dan cengkeh. Namanya konon dari bunyi "pletok-pletok" saat es batu dikocok dalam bambu saat membuatnya.',
    'kategori': 'KULINER',
  },
  {
    'id': 3,
    'pertanyaan': 'Ondel-ondel merupakan boneka raksasa khas Betawi. Apa fungsi aslinya sebelum menjadi hiburan?',
    'pilihan': [
      'Dekorasi pernikahan adat Betawi',
      'Simbol kemakmuran panen raya',
      'Penolak bala dan roh jahat',
      'Penanda batas wilayah kampung',
    ],
    'jawaban_benar': 2,
    'penjelasan':
        'Secara tradisional, Ondel-ondel berfungsi sebagai penolak bala — dipercaya dapat mengusir roh jahat dan membawa perlindungan bagi kampung. Boneka raksasa ini diarak keliling kampung sebagai ritual perlindungan. Seiring waktu, fungsinya bergeser menjadi seni pertunjukan hiburan.',
    'kategori': 'TRADISI',
  },
  {
    'id': 4,
    'pertanyaan': 'Rumah Kebaya adalah rumah adat Betawi. Mengapa disebut "Kebaya"?',
    'pilihan': [
      'Karena sering digunakan untuk acara pemakaian kebaya',
      'Karena atapnya menyerupai lipatan kain kebaya',
      'Karena dihiasi bordir seperti motif kebaya',
      'Karena dibangun oleh pengrajin kebaya Betawi',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Rumah Kebaya mendapat namanya karena bentuk atapnya yang jika dilihat dari samping menyerupai lipatan kain kebaya yang sedang dilipat. Ciri khasnya adalah teras lebar (serambi) yang digunakan untuk menerima tamu dan berinteraksi sosial dengan tetangga.',
    'kategori': 'SEJARAH',
  },
  {
    'id': 5,
    'pertanyaan': 'Soto Betawi berbeda dari soto daerah lain karena kuahnya menggunakan...',
    'pilihan': [
      'Kaldu ayam kampung murni',
      'Campuran santan dan susu sapi',
      'Air tamarind (asam jawa)',
      'Campuran kecap manis dan kemiri',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Soto Betawi memiliki ciri khas kuah creamy berwarna putih kekuningan yang berasal dari campuran santan kelapa dan susu sapi (atau susu evaporasi). Kombinasi ini menghasilkan tekstur yang kaya dan gurih, berbeda dengan soto-soto dari daerah lain yang umumnya berkuah bening atau hanya bersantan.',
    'kategori': 'KULINER',
  },
  {
    'id': 6,
    'pertanyaan': 'Lenong adalah kesenian teater tradisional Betawi. Apa karakteristik utamanya?',
    'pilihan': [
      'Dialog kaku tanpa improvisasi, plot tertulis ketat',
      'Pertunjukan sunyi dengan ekspresi mimik dan gerak',
      'Improvisasi bebas dengan humor spontan dan interaksi penonton',
      'Nyanyian opera tanpa dialog, hanya musik',
    ],
    'jawaban_benar': 2,
    'penjelasan':
        'Lenong dikenal karena sifatnya yang sangat improvisatif. Para pemain leluasa berinteraksi langsung dengan penonton, melempar lawak spontan, dan menyesuaikan alur cerita sesuai respons penonton. Unsur humor (dagelan) adalah jiwa dari Lenong, menjadikannya hiburan rakyat yang hidup dan dinamis.',
    'kategori': 'SENI',
  },
  {
    'id': 7,
    'pertanyaan': 'Gabus Pucung adalah masakan khas Betawi yang menggunakan bahan utama...',
    'pilihan': [
      'Ikan gabus dengan kuah keluak (pucung)',
      'Daging kambing dengan daun pandan',
      'Udang sungai dengan bumbu kelapa bakar',
      'Ikan lele dengan sambal terasi pucung',
    ],
    'jawaban_benar': 0,
    'penjelasan':
        'Gabus Pucung adalah masakan ikonik Betawi berupa ikan gabus (juga dikenal sebagai ikan kutuk) yang dimasak dengan kuah hitam kental dari kluwek/keluak (pucung). Rasa kuahnya gurih, sedikit pahit, dan berwarna hitam pekat dari biji kluwek. Masakan ini kini termasuk kuliner yang semakin langka.',
    'kategori': 'KULINER',
  },
  {
    'id': 8,
    'pertanyaan': 'Tanjidor adalah orkes musik tradisional Betawi. Berasal dari pengaruh budaya mana?',
    'pilihan': [
      'Portugis dan Belanda',
      'Arab dan India',
      'China dan Melayu',
      'Jawa dan Sunda',
    ],
    'jawaban_benar': 0,
    'penjelasan':
        'Tanjidor berasal dari pengaruh budaya Eropa — khususnya Portugis dan Belanda — yang masuk ke Batavia pada abad ke-17. Kata "Tanjidor" sendiri diyakini berasal dari bahasa Portugis "tangedor" (alat musik berdawai). Meski berakar Eropa, orkes ini kemudian diadaptasi dengan nuansa lokal Betawi dan sering mengiringi arak-arakan pengantin.',
    'kategori': 'SENI',
  },
  {
    'id': 9,
    'pertanyaan': 'Kawasan Condet di Jakarta Timur dulunya terkenal sebagai penghasil buah apa?',
    'pilihan': [
      'Mangga dan rambutan',
      'Salak dan duku Condet',
      'Durian dan manggis',
      'Jambu dan nangka',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Condet dulunya merupakan kawasan pertanian dengan kebun salak dan duku yang terkenal — bahkan ditetapkan sebagai Cagar Budaya Lingkungan di era 1970-an untuk melestarikan kebunnya. Duku Condet memiliki rasa khas yang berbeda. Sayangnya, urbanisasi masif telah menggerus hampir seluruh kebun buah tersebut.',
    'kategori': 'SEJARAH',
  },
  {
    'id': 10,
    'pertanyaan': 'Dalam tradisi pernikahan Betawi, "Palang Pintu" adalah ritual...',
    'pilihan': [
      'Prosesi seserahan dari pihak pria ke wanita',
      'Pertarungan silat dan pantun sebelum pengantin pria masuk',
      'Upacara memohon restu kepada leluhur',
      'Tarian selamat datang untuk tamu undangan',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Palang Pintu adalah ritual unik pernikahan Betawi di mana jagoan (jawara) dari pihak pengantin pria harus mengalahkan jagoan dari pihak wanita melalui adu silat dan berbalas pantun sebelum rombongan pengantin pria diperbolehkan masuk. Ini melambangkan kemampuan calon suami melindungi keluarganya.',
    'kategori': 'TRADISI',
  },
  {
    'id': 11,
    'pertanyaan': 'Kerak Telor adalah makanan ikonik Betawi. Bahan utamanya adalah...',
    'pilihan': [
      'Telur ayam, tepung beras, dan kelapa parut',
      'Telur bebek, beras ketan, dan kelapa sangrai',
      'Telur puyuh, sagu, dan gula merah',
      'Telur ayam, mie bihun, dan bumbu balado',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Kerak Telor dibuat dari bahan utama telur bebek (atau ayam), beras ketan putih, dan kelapa parut sangrai (serundeng) sebagai topping. Bumbu pelengkapnya antara lain bawang merah goreng, cabai, kencur, jahe, dan ebi. Cara memasaknya unik — wajan dibalik menghadap api arang agar kedua sisi matang merata.',
    'kategori': 'KULINER',
  },
  {
    'id': 12,
    'pertanyaan': 'Silat Betawi atau "Maen Pukulan" berbeda dari silat daerah lain karena...',
    'pilihan': [
      'Fokus pada tendangan akrobatik seperti silat Minang',
      'Lebih mengutamakan serangan tangan dan pukulan keras jarak dekat',
      'Menggunakan senjata tombak sebagai ciri khasnya',
      'Hanya digunakan dalam ritual keagamaan, bukan pertarungan',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Maen Pukulan khas Betawi menekankan teknik serangan tangan kosong jarak dekat dengan pukulan yang keras dan langsung. Berbeda dengan silat Minangkabau yang akrobatik atau silat Sunda yang mengutamakan kaki, Maen Pukulan bersifat praktis dan efektif untuk pertarungan jalanan, mencerminkan karakter keras Jakarta tempo dulu.',
    'kategori': 'TRADISI',
  },
  {
    'id': 13,
    'pertanyaan': 'Apa yang dimaksud dengan "Betawi Ora" atau orang Betawi pinggiran?',
    'pilihan': [
      'Masyarakat Betawi keturunan Arab yang tinggal di pusat kota',
      'Masyarakat Betawi yang bermukim di tepi kota Jakarta, lebih kental budaya aslinya',
      'Komunitas pendatang yang menikah dengan orang Betawi',
      'Kelompok seniman Betawi yang tidak diakui secara resmi',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Betawi Ora (ora = bukan/luar dalam dialek Jawa) merujuk pada komunitas Betawi pinggiran yang mendiami wilayah perbatasan Jakarta. Berbeda dengan Betawi Kota, Betawi Ora lebih banyak menyerap pengaruh budaya Sunda dan Jawa. Budaya asli mereka cenderung lebih kental karena relatif terisolasi dari urbanisasi pusat kota.',
    'kategori': 'SEJARAH',
  },
  {
    'id': 14,
    'pertanyaan': 'Taman Mini Indonesia Indah (TMII) yang berlokasi di Jakarta Timur diresmikan pada tahun...',
    'pilihan': [
      '1972',
      '1975',
      '1978',
      '1980',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'TMII diresmikan pada 20 April 1975 oleh Presiden Soeharto. Gagasannya berasal dari Ibu Tien Soeharto yang terinspirasi dari Taman Mini di Los Angeles dan miniatur dunia di Brussel. TMII menampilkan keberagaman budaya 34 provinsi Indonesia melalui rumah adat, museum, dan wahana hiburan di lahan seluas 150 hektar.',
    'kategori': 'SEJARAH',
  },
  {
    'id': 15,
    'pertanyaan': 'Keroncong Betawi berbeda dari keroncong Jawa dalam hal...',
    'pilihan': [
      'Keroncong Betawi tidak menggunakan alat musik ukulele',
      'Keroncong Betawi lebih cepat temponya dan melantunkan lirik berbahasa Melayu',
      'Keroncong Betawi hanya dimainkan di acara pemakaman',
      'Keroncong Betawi menggunakan gamelan sebagai alat utamanya',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Keroncong Betawi atau Stambul memiliki tempo yang lebih cepat dan riang dibanding keroncong Jawa yang cenderung lambat dan melankolis. Liriknya berbahasa Melayu-Betawi dengan tema kehidupan sehari-hari, percintaan, dan humor. Pengaruh Portugis sangat kental pada musik ini, masuk lewat komunitas Mardijkers di Batavia.',
    'kategori': 'SENI',
  },
  {
    'id': 16,
    'pertanyaan': 'Kampung Melayu di Jakarta Timur mendapat namanya karena...',
    'pilihan': [
      'Dulunya tempat tinggal para imigran Malaysia',
      'Kawasan pemukiman etnis Melayu yang dibentuk pemerintah kolonial Belanda',
      'Nama seorang tokoh bernama Melayu yang berjasa di sana',
      'Tempat di mana bahasa Melayu pertama kali diajarkan di Batavia',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Kampung Melayu merupakan kawasan pemukiman yang diperuntukkan bagi etnis Melayu oleh pemerintah kolonial VOC/Belanda. Kebijakan segregasi etnis era kolonial menciptakan banyak kampung berbasis etnis di Batavia seperti Kampung Melayu, Kampung Bali, dan Kampung Makassar. Kawasan ini kini menjadi salah satu simpul transportasi penting Jakarta.',
    'kategori': 'SEJARAH',
  },
  {
    'id': 17,
    'pertanyaan': 'Betawi terkenal dengan tradisi "Nujuh Bulanin". Apa artinya?',
    'pilihan': [
      'Upacara tujuh bulan setelah pernikahan',
      'Syukuran kehamilan saat kandungan memasuki tujuh bulan',
      'Festival panen raya yang diadakan tiap tujuh bulan',
      'Ritual berdoa tujuh hari berturut-turut sebelum Ramadan',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Nujuh Bulanin (dari kata "tujuh bulan") adalah tradisi syukuran dan doa bersama yang digelar saat kehamilan memasuki usia tujuh bulan — usia kandungan yang dianggap sudah cukup kuat. Acara ini biasanya dimeriahkan dengan pengajian, makan bersama, dan ritual siraman. Tradisi serupa ada di berbagai budaya Nusantara dengan nama berbeda.',
    'kategori': 'TRADISI',
  },
  {
    'id': 18,
    'pertanyaan': 'Dodol Betawi yang terkenal pekat dan kenyal terbuat dari bahan dasar...',
    'pilihan': [
      'Singkong parut, gula aren, dan pandan',
      'Ketan putih/hitam, santan, dan gula merah',
      'Tepung terigu, mentega, dan vanili',
      'Ubi jalar ungu, kelapa, dan gula pasir',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Dodol Betawi dibuat dari tepung beras ketan (putih atau hitam), santan kelapa, dan gula merah. Proses memasaknya sangat lama — bisa 5-8 jam — dengan pengadukan terus-menerus tanpa henti di wajan besar di atas tungku kayu. Itulah mengapa dodol Betawi terkenal sangat pekat, kenyal, dan tahan lama.',
    'kategori': 'KULINER',
  },
  {
    'id': 19,
    'pertanyaan': 'Topeng Betawi adalah tarian yang menggunakan topeng. Apa makna simbolis topeng dalam pertunjukan ini?',
    'pilihan': [
      'Menakut-nakuti roh jahat agar menjauhi penonton',
      'Mewakili berbagai karakter dan sifat manusia dalam kehidupan',
      'Menyembunyikan identitas penari agar tidak dikenali',
      'Simbol penguasa kerajaan Betawi kuno',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Dalam Topeng Betawi, setiap topeng mewakili karakter dan sifat manusia yang berbeda — ada yang bijaksana, angkuh, jenaka, atau emosional. Pertunjukan ini menjadi media untuk mengekspresikan nilai-nilai moral dan cerita kehidupan. Ada lima karakter utama: Panji (putih/suci), Samba (merah/pemberani), Rumyang (merah muda/ceria), Tumenggung (coklat/bijak), dan Kelana (merah marun/angkuh).',
    'kategori': 'SENI',
  },
  {
    'id': 20,
    'pertanyaan': 'Apa sebutan untuk komunitas keturunan Arab yang banyak menetap di kawasan Kramat Jati dan sekitarnya?',
    'pilihan': [
      'Betawi Arab atau Arab Peranakan',
      'Hadrami atau Betawi Hadrami',
      'Mardijkers Arab',
      'Warga Sayid',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Komunitas keturunan Arab di Jakarta, termasuk kawasan Jakarta Timur, umumnya disebut Hadrami — merujuk pada asal mereka dari Hadramaut, Yaman. Mereka telah bermukim di Batavia sejak abad ke-17 dan berperan besar dalam penyebaran Islam. Banyak yang telah berasimilasi dengan budaya Betawi dan disebut pula sebagai "Betawi Hadrami".',
    'kategori': 'SEJARAH',
  },
  {
    'id': 21,
    'pertanyaan': 'Festival tahunan apa yang sering menampilkan Ondel-ondel, Tanjidor, dan berbagai seni Betawi secara bersamaan?',
    'pilihan': [
      'Festival Danau Sunter',
      'Pekan Raya Jakarta (PRJ) / Jakarta Fair',
      'Jakarta Betawi Festival',
      'Lebaran Betawi',
    ],
    'jawaban_benar': 3,
    'penjelasan':
        'Lebaran Betawi adalah festival tahunan khusus yang dirancang untuk merayakan dan melestarikan budaya Betawi, biasanya digelar beberapa minggu setelah Hari Raya Idul Fitri. Acara ini menampilkan parade Ondel-ondel, pertunjukan Lenong, Tanjidor, Silat Betawi, pameran kuliner tradisional, dan berbagai produk kerajinan Betawi secara bersamaan.',
    'kategori': 'TRADISI',
  },
  {
    'id': 22,
    'pertanyaan': 'Kawasan Jatinegara (dahulu Meester Cornelis) di Jakarta Timur terkenal sebagai pusat...',
    'pilihan': [
      'Industri batik Betawi sejak kolonial',
      'Perdagangan dan pasar tradisional terbesar di Jakarta Timur',
      'Pembuatan ondel-ondel dan kerajinan bambu',
      'Sentra produksi bir pletok dan dodol',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Jatinegara telah lama dikenal sebagai pusat perdagangan dan pasar tradisional di Jakarta Timur. Pasar Jatinegara yang legendaris menjual berbagai barang mulai dari tekstil, perabot, hewan peliharaan, hingga barang antik. Nama aslinya "Meester Cornelis" berasal dari Cornelis Senen, pemilik tanah partikelir pada era VOC.',
    'kategori': 'SEJARAH',
  },
  {
    'id': 23,
    'pertanyaan': 'Dalam bahasa Betawi, "Nyang" atau "Enyak" adalah sebutan untuk...',
    'pilihan': [
      'Kakek atau nenek',
      'Ibu atau orang tua perempuan',
      'Paman dari pihak ayah',
      'Tetangga yang dihormati',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Dalam dialek Betawi, "Enyak" adalah sebutan akrab untuk ibu (orang tua perempuan), setara dengan "Emak" atau "Mama". Sementara "Babe" digunakan untuk menyebut ayah. Pasangan "Enyak-Babe" ini sangat populer dalam serial komedi Si Doel Anak Sekolahan yang menggambarkan kehidupan keluarga Betawi.',
    'kategori': 'TRADISI',
  },
  {
    'id': 24,
    'pertanyaan': 'Pencak Silat secara resmi diakui UNESCO sebagai warisan budaya tak benda dari Indonesia pada tahun...',
    'pilihan': [
      '2015',
      '2017',
      '2019',
      '2021',
    ],
    'jawaban_benar': 2,
    'penjelasan':
        'Pencak Silat, termasuk aliran-aliran dari Betawi, resmi diakui UNESCO sebagai Intangible Cultural Heritage of Humanity pada Desember 2019. Pengakuan ini memperkuat posisi Indonesia sebagai penjaga warisan seni bela diri asli Nusantara yang telah berkembang ribuan tahun dengan ratusan aliran berbeda di setiap daerah.',
    'kategori': 'TRADISI',
  },
  {
    'id': 25,
    'pertanyaan': 'Bangunan ikonik apa di Jakarta Timur yang pernah menjadi tempat penahanan para pejuang kemerdekaan?',
    'pilihan': [
      'Gedung Juang Tambun',
      'Penjara Cipinang (Lembaga Pemasyarakatan Cipinang)',
      'Benteng Meester Cornelis',
      'Gedung Kramat 106',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'LP Cipinang yang dibangun Belanda pada 1910 memiliki sejarah kelam sekaligus heroik — di sinilah banyak pejuang dan tokoh nasional seperti Bung Karno, Bung Hatta, dan berbagai aktivis pergerakan nasional pernah ditahan. Kini LP Cipinang masih aktif sebagai lembaga pemasyarakatan dan menjadi bagian dari sejarah perjuangan Indonesia.',
    'kategori': 'SEJARAH',
  },
  {
    'id': 26,
    'pertanyaan': 'Apa istilah Betawi untuk "nongkrong bersama sambil ngobrol santai" yang mencerminkan budaya sosial mereka?',
    'pilihan': [
      'Ngariung',
      'Ngabobodo',
      'Ngumpul kongkow',
      'Ngetem',
    ],
    'jawaban_benar': 2,
    'penjelasan':
        '"Kongkow" atau "kongkow-kongkow" adalah istilah populer di Jakarta (berasal dari kata Hokkien "kōng-kha") yang berarti berkumpul dan mengobrol santai tanpa agenda khusus. Budaya kongkow mencerminkan masyarakat Betawi yang terbuka dan ramah, biasanya dilakukan di warung kopi, teras rumah, atau pos ronda — menjadi sarana mempererat hubungan sosial.',
    'kategori': 'TRADISI',
  },
  {
    'id': 27,
    'pertanyaan': 'Kain Betawi tradisional yang sering digunakan dalam upacara adat memiliki motif khas bernama...',
    'pilihan': [
      'Batik Mega Mendung',
      'Kain Pucuk Rebung dan Tumpal',
      'Tenun Ikat Troso',
      'Batik Kawung',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Kain tradisional Betawi umumnya bermotif Pucuk Rebung (berbentuk segitiga menyerupai tunas bambu yang melambangkan harapan dan pertumbuhan) dan Tumpal (motif segitiga yang disusun berderet). Motif-motif ini banyak dijumpai pada kain sarung, baju sadariah (baju koko Betawi), dan taplak meja dalam acara adat Betawi.',
    'kategori': 'SENI',
  },
  {
    'id': 28,
    'pertanyaan': 'Mengapa Betawi sering disebut sebagai etnis "asli" Jakarta, padahal terbentuk dari percampuran banyak budaya?',
    'pilihan': [
      'Karena pemerintah secara resmi menetapkan Betawi sebagai suku asli Jakarta',
      'Karena Betawi terbentuk dari percampuran berbagai etnis di Batavia dan telah ada sejak abad ke-17',
      'Karena bahasa Betawi adalah bahasa tertua di Pulau Jawa',
      'Karena semua warga Jakarta secara hukum dianggap Betawi',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Betawi adalah etnis hasil akulturasi dari banyak kelompok yang datang ke Batavia sejak abad ke-17 — Melayu, Sunda, Jawa, Bali, Bugis, Portugis, Belanda, Arab, India, dan China. Mereka menjadi komunitas tersendiri yang lahir dan tumbuh di tanah Batavia/Jakarta, sehingga disebut sebagai "anak asli" Jakarta meski sejarahnya sangat kosmopolit.',
    'kategori': 'SEJARAH',
  },
  {
    'id': 29,
    'pertanyaan': 'Sembelit atau "Sembeyan" adalah tradisi Betawi di mana tetangga dan kerabat...',
    'pilihan': [
      'Berkumpul untuk membantu memasak di acara hajatan',
      'Beriuran uang untuk membantu biaya pernikahan',
      'Bergotong royong membangun rumah baru',
      'Membagi makanan kepada fakir miskin saat lebaran',
    ],
    'jawaban_benar': 0,
    'penjelasan':
        'Sembeyan (juga disebut sambatan dalam budaya Jawa) adalah tradisi saling membantu memasak di acara hajatan seperti pernikahan, sunatan, atau aqiqah. Para tetangga dan kerabat datang sukarela untuk memasak bersama dari malam sebelum acara. Tradisi ini mencerminkan semangat gotong royong yang sangat kuat dalam komunitas Betawi.',
    'kategori': 'TRADISI',
  },
  {
    'id': 30,
    'pertanyaan': 'Orkes Gambang Kromong khas Betawi merupakan perpaduan antara...',
    'pilihan': [
      'Musik Melayu dan Sunda',
      'Alat musik China (gambang, kromong) dengan melodi dan lagu-lagu Betawi',
      'Musik Portugis dan gamelan Jawa',
      'Instrumen Arab dan perkusi Betawi',
    ],
    'jawaban_benar': 1,
    'penjelasan':
        'Gambang Kromong adalah seni musik khas Betawi yang unik karena memadukan instrumen dari budaya China — gambang (xylophone kayu) dan kromong (gong kecil dari perunggu) — dengan alat musik Melayu-Betawi seperti suling, rebab, dan kecrek. Hasilnya adalah harmoni lintas budaya yang menjadi simbol kosmopolitisme masyarakat Betawi.',
    'kategori': 'SENI',
  },
];