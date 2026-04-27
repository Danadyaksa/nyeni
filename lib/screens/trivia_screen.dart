import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  final _supabase = Supabase.instance.client;
  
  int? _selectedLevel;
  List<Map<String, dynamic>> _activeQuestions = [];
  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  int _userMaxLevel = 1; 
  bool _isQuizFinished = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  // ======================================================
  // UPDATE 1: Panggil completed_levels_trivia & maybeSingle
  // ======================================================
  Future<void> _loadUserProgress() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase.from('users').select('completed_levels_trivia').eq('id', user.id).maybeSingle();
        setState(() {
          _userMaxLevel = data?['completed_levels_trivia'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startLevel(int level) {
    List<Map<String, dynamic>> questions = List.from(_allQuizData[level]!);
    questions.shuffle(); 

    setState(() {
      _selectedLevel = level;
      _activeQuestions = questions;
      _currentQuestionIndex = 0;
      _correctCount = 0;
      _isQuizFinished = false;
    });
  }

  void _handleAnswer(String choice) {
    final currentQ = _activeQuestions[_currentQuestionIndex];
    bool isCorrect = choice == currentQ['ans'];

    if (isCorrect) _correctCount++;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCorrect ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                color: isCorrect ? Colors.green : Colors.red,
                size: 70,
              ),
              const SizedBox(height: 16),
              Text(
                isCorrect ? "Tepat Sekali!" : "Yah, Kurang Tepat!",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              
              if (!isCorrect) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text("Jawaban yang benar adalah:", style: TextStyle(fontSize: 12, color: Colors.red)),
                      const SizedBox(height: 4),
                      Text(
                        currentQ['ans'], 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2C3E50).withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.lightbulb, size: 18, color: Colors.amber),
                        SizedBox(width: 8),
                        Text("Tahukah Kamu?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentQ['fact'], 
                      style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _nextQuestion();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Lanjut ke Soal Berikutnya", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _activeQuestions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      _processLevelResult();
    }
  }

  // ======================================================
  // UPDATE 2: maybeSingle, upsert, dan completed_levels_trivia
  // ======================================================
  Future<void> _processLevelResult() async {
    setState(() => _isQuizFinished = true);

    if (_correctCount == 10) {
      try {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final res = await _supabase.from('users').select('total_xp, level, completed_levels_trivia').eq('id', user.id).maybeSingle();
          
          int currentXp = res?['total_xp'] ?? 0;
          int newXp = currentXp + 200; 
          int newLevel = (newXp ~/ 100) + 1;
          
          int updatedCompletedLevel = _userMaxLevel;
          if (_selectedLevel == _userMaxLevel) {
            updatedCompletedLevel = _userMaxLevel + 1;
          }

          // Pakai upsert agar aman untuk user baru
          await _supabase.from('users').upsert({
            'id': user.id,
            'total_xp': newXp,
            'level': newLevel,
            'completed_levels_trivia': updatedCompletedLevel
          });

          setState(() {
            _userMaxLevel = updatedCompletedLevel;
          });
        }
      } catch (e) {
        debugPrint('Update Error: $e');
        // Fallback lokal jika internet/database bermasalah
        setState(() {
           if (_selectedLevel == _userMaxLevel) {
              _userMaxLevel = _userMaxLevel + 1;
           }
        });
      }
    }
  }

  // ==========================================
  // DATA KUIS FINAL 50 SOAL & FUN FACT PARAGRAF
  // ==========================================
  final Map<int, List<Map<String, dynamic>>> _allQuizData = {
    1: [
      {'q': 'Pelukis maestro Indonesia beraliran ekspresionisme adalah...', 'opts': ['Raden Saleh', 'Affandi', 'Basuki Abdullah', 'Sudjojono'], 'ans': 'Affandi', 
       'fact': 'Affandi dikenal dunia karena teknik eksentriknya dalam melukis. Ia jarang menggunakan kuas, melainkan memeras tube cat minyak langsung ke atas kanvas lalu menyapunya menggunakan jari-jari tangannya secara emosional. Teknik plototan cat ini menghasilkan tekstur lukisan yang sangat tebal, ekspresif, dan bernilai jual luar biasa tinggi di berbagai balai lelang internasional.'},
      {'q': 'Festival seni rupa kontemporer di Yogyakarta disebut...', 'opts': ['ARTJOG', 'FKY', 'Sekaten', 'Biennale'], 'ans': 'ARTJOG', 
       'fact': 'ARTJOG merupakan pameran seni rupa tahunan yang selalu dinantikan dan rutin diadakan di Jogja National Museum (JNM). Keunikan utama pameran ini terletak pada fasad atau wajah depan gedungnya yang selalu dirombak total setiap tahun oleh seniman komisi, menjadikannya ikon estetis sekaligus spot foto paling populer bagi ribuan pengunjung dari dalam dan luar negeri.'},
      {'q': 'Bapak Seni Rupa Modern Indonesia adalah...', 'opts': ['Affandi', 'Raden Saleh', 'S. Sudjojono', 'Hendra Gunawan'], 'ans': 'S. Sudjojono', 
       'fact': 'S. Sudjojono diberi gelar Bapak Seni Rupa Modern karena ia adalah tokoh utama yang menentang gaya lukisan Mooi Indie (Hindia Molek) buatan pelukis Eropa. Ia mendirikan PERSAGI (Persatuan Ahli Gambar Indonesia) pada tahun 1938 untuk mencari identitas dan corak seni rupa asli Indonesia yang mencerminkan realitas penderitaan rakyat, bukan sekadar pemandangan indah yang menipu.'},
      {'q': 'Wayang Kulit ditetapkan UNESCO sebagai warisan dunia pada...', 'opts': ['2001', '2003', '2005', '2010'], 'ans': '2003', 
       'fact': 'Pada tanggal 7 November 2003, UNESCO secara resmi mengakui Wayang Kulit sebagai Masterpiece of Oral and Intangible Heritage of Humanity. Wayang bukan sekadar hiburan, melainkan sebuah mahakarya seni pertunjukan kompleks yang memadukan keindahan seni kriya kulit, seni musik gamelan, seni sastra lisan sang dalang, serta ajaran filosofi hidup masyarakat Jawa.'},
      {'q': 'Candi Buddha terbesar di dunia di Indonesia adalah...', 'opts': ['Prambanan', 'Mendut', 'Borobudur', 'Sewu'], 'ans': 'Borobudur', 
       'fact': 'Candi Borobudur dibangun pada abad ke-8 dan ke-9 Masehi oleh Dinasti Syailendra. Bangunan megah ini disusun dari lebih dari dua juta blok batu andesit vulkanik yang saling mengunci satu sama lain (interlocking) tanpa menggunakan semen atau perekat sedikit pun. Susunan reliefnya jika dibentangkan akan memanjang hingga 2,5 kilometer, menceritakan perjalanan karma manusia hingga mencapai nirwana.'},
      {'q': 'Raden Saleh berguru seni lukis di negara...', 'opts': ['Prancis', 'Belanda', 'Inggris', 'Jerman'], 'ans': 'Belanda', 
       'fact': 'Raden Saleh adalah pelukis pertama keturunan Jawa dari Hindia Belanda yang mendapat kesempatan belajar seni rupa langsung di Eropa, tepatnya di Belanda, di bawah bimbingan pelukis Cornelis Kruseman. Kemampuannya melukis aliran Romantisisme membuatnya sangat dihormati di kalangan bangsawan Eropa hingga ia dipercaya menjadi pelukis resmi istana.'},
      {'q': 'Patung Dirgantara di Jakarta juga dikenal sebagai...', 'opts': ['Patung Tugu Tani', 'Patung Pancoran', 'Patung Monas', 'Patung Selamat Datang'], 'ans': 'Patung Pancoran', 
       'fact': 'Patung ini dirancang oleh maestro pematung Edhi Sunarso atas instruksi langsung dari Presiden Soekarno untuk menunjukkan keperkasaan bangsa Indonesia di bidang kedirgantaraan. Saking pedulinya Bung Karno terhadap proyek ini, beliau rela menjual mobil pribadi kesayangannya demi menutupi kekurangan dana pembuatan patung tersebut.'},
      {'q': 'Motif batik Megamendung berasal dari...', 'opts': ['Solo', 'Yogyakarta', 'Cirebon', 'Pekalongan'], 'ans': 'Cirebon', 
       'fact': 'Motif Megamendung yang berbentuk gumpalan awan tebal memiliki sejarah panjang persilangan budaya. Motif ini terpengaruh oleh seni keramik dan kebudayaan Tiongkok yang dibawa oleh para pendatang dan pelaut ke pelabuhan Cirebon, yang kemudian diadaptasi oleh para seniman lokal dengan sentuhan gradasi warna yang melambangkan kesejukan hati.'},
      {'q': 'Warna dominan pada lukisan Hendra Gunawan biasanya...', 'opts': ['Gelap', 'Monokrom', 'Cerah & Berani', 'Pastel'], 'ans': 'Cerah & Berani', 
       'fact': 'Hendra Gunawan sangat revolusioner karena ia sering menggunakan palet warna yang sangat cerah, bertabrakan, dan berani, seperti pink terang, hijau neon, dan kuning menyala. Melalui warna-warna mencolok inilah ia melukiskan kehidupan sehari-hari rakyat jelata yang sederhana, seperti penjual ikan, wanita menyusui, dan pejuang gerilya, sehingga lukisannya terasa sangat hidup.'},
      {'q': 'Teater tradisional dari Betawi disebut...', 'opts': ['Lenong', 'Ketoprak', 'Ludruk', 'Randai'], 'ans': 'Lenong', 
       'fact': 'Lenong adalah seni teater tradisional khas Betawi yang berkembang sejak akhir abad ke-19. Keunikan utama dari Lenong adalah para pemainnya tidak pernah menggunakan naskah tulisan (script). Mereka bermain secara spontan dan berimprovisasi penuh humor di atas panggung dengan iringan musik gambang kromong, menjadikannya pertunjukan yang selalu segar dan penuh tawa.'},
    ],
    2: [
      {'q': 'Kain tenun khas masyarakat Batak disebut...', 'opts': ['Ulos', 'Songket', 'Tapis', 'Ikat'], 'ans': 'Ulos', 
       'fact': 'Bagi masyarakat Batak di Sumatera Utara, kain Ulos bukanlah sekadar pakaian atau tekstil biasa. Ulos merupakan simbol ikatan kasih sayang, restu, dan perlindungan yang hadir dalam setiap fase ritual siklus hidup mereka, mulai dari upacara kelahiran, pernikahan, hingga upacara pemakaman sebagai penghormatan terakhir.'},
      {'q': 'Rumah adat berbentuk limas di Sumatera Selatan disebut...', 'opts': ['Rumah Gadang', 'Rumah Limas', 'Joglo', 'Honai'], 'ans': 'Rumah Limas', 
       'fact': 'Rumah Limas memiliki arsitektur yang sangat unik karena lantai di dalamnya dibangun bertingkat-tingkat (disebut kekijing). Setiap tingkatan ini bukan tanpa alasan, melainkan digunakan untuk membedakan status sosial, usia, dan garis keturunan tamu atau keluarga yang sedang berkumpul dalam suatu acara adat persedekahan.'},
      {'q': 'Suku di Papua yang terkenal dengan seni ukir kayunya adalah...', 'opts': ['Dani', 'Asmat', 'Biak', 'Sentani'], 'ans': 'Asmat', 
       'fact': 'Suku Asmat yang mendiami pesisir selatan Papua memandang seni mengukir kayu sebagai sebuah ritual suci. Mereka percaya bahwa leluhur pertama mereka tercipta dari patung kayu yang dipahat oleh dewa Fumeripitsy, sehingga setiap ukiran yang mereka buat adalah bentuk penghormatan sekaligus medium komunikasi dengan arwah nenek moyang.'},
      {'q': 'Senjata tradisional Jawa yang diakui UNESCO adalah...', 'opts': ['Keris', 'Kujang', 'Rencong', 'Mandau'], 'ans': 'Keris', 
       'fact': 'UNESCO secara resmi mengakui Keris Indonesia sebagai Warisan Kemanusiaan untuk Budaya Lisan dan Nonbendawi. Keris bukan sekadar senjata tajam untuk berperang, tetapi merupakan karya seni kriya logam yang mengandung teknik penempaan meteorit tingkat tinggi (pamor) serta memuat nilai spiritual dan status sosial yang sangat dihormati oleh pemiliknya.'},
      {'q': 'Batik yang dibuat dengan canting disebut batik...', 'opts': ['Cap', 'Tulis', 'Printing', 'Ikat'], 'ans': 'Batik Tulis', 
       'fact': 'Batik tulis merupakan karya seni kriya tingkat tinggi karena setiap titik dan garis malam (lilin) digoreskan secara manual menggunakan tangan dan canting oleh para pengrajin. Karena kerumitan motif dan proses pewarnaannya yang berulang-ulang, pengerjaan satu lembar kain batik tulis berkualitas bisa memakan waktu antara satu hingga enam bulan lamanya.'},
      {'q': 'Pusat gerabah di Yogyakarta berada di desa...', 'opts': ['Kotagede', 'Kasongan', 'Manding', 'Bantul'], 'ans': 'Kasongan', 
       'fact': 'Desa Kasongan di Bantul, Yogyakarta, memiliki sejarah panjang sebagai pusat kerajinan tanah liat atau gerabah. Berawal dari kebiasaan warga miskin yang membuat peralatan dapur sederhana dari tanah, kini Kasongan telah berevolusi menjadi sentra industri kreatif yang memproduksi patung, pot raksasa, dan elemen dekorasi interior bernilai ekspor tinggi.'},
      {'q': 'Alat untuk membatik disebut...', 'opts': ['Sudi', 'Canting', 'Pahat', 'Kuas'], 'ans': 'Canting', 
       'fact': 'Canting adalah pena khusus yang terbuat dari tembaga dan bambu yang digunakan untuk menampung malam (lilin) cair yang panas. Ujung canting memiliki lubang kecil yang berfungsi layaknya mata pena, memungkinkan pembatik menorehkan pola-pola garis dan titik yang sangat presisi pada lembaran kain mori sebelum proses pewarnaan dilakukan.'},
      {'q': 'Motif batik Parang dulunya hanya boleh dipakai oleh...', 'opts': ['Petani', 'Pedagang', 'Keluarga Raja', 'Prajurit'], 'ans': 'Keluarga Raja', 
       'fact': 'Batik bermotif Parang yang bentuknya menyerupai huruf S miring yang saling menyambung ini adalah salah satu motif batik tertua di Indonesia. Pada masa lalu, motif ini masuk dalam kategori batik larangan, yang berarti hanya Sultan dan keturunan keluarga kerajaan Keraton saja yang diperbolehkan mengenakannya, sebagai simbol kekuasaan dan kekuatan yang tak terputus layaknya ombak lautan.'},
      {'q': 'Songket yang benangnya menggunakan emas berasal dari...', 'opts': ['Palembang', 'Papua', 'Bali', 'Aceh'], 'ans': 'Palembang', 
       'fact': 'Songket Palembang sering dijuluki sebagai "Ratu Segala Kain" karena kemewahannya yang tiada tara. Proses penenunannya memasukkan benang-benang emas atau perak yang berkilau di antara benang sutra, menciptakan motif timbul yang gemerlap dan biasa dipakai oleh kalangan bangsawan Kesultanan Palembang Darussalam pada acara-acara adat yang megah.'},
      {'q': 'Patung kayu dari Bali yang sangat detail biasanya dari daerah...', 'opts': ['Kuta', 'Ubud', 'Mas', 'Celuk'], 'ans': 'Mas', 
       'fact': 'Desa Mas yang terletak di kawasan Gianyar, Bali, adalah jantungnya seni ukir patung kayu di Pulau Dewata. Para pematung di desa ini sangat dihormati karena kemampuannya menghidupkan sebongkah kayu gelondongan menjadi patung dewa-dewi, tokoh pewayangan, hingga manusia dengan proporsi, anatomi, dan kehalusan detail yang sangat sempurna.'},
    ],
    3: [
      {'q': 'Tari Saman berasal dari provinsi...', 'opts': ['Sumatera Utara', 'Aceh', 'Jambi', 'Lampung'], 'ans': 'Aceh', 
       'fact': 'Tari Saman adalah kebanggaan masyarakat Gayo, Aceh. Yang membuat tarian ini memukau dunia adalah kecepatannya yang luar biasa namun tetap terkoordinasi dengan sangat sinkron antar penari. Uniknya, tarian ini sama sekali tidak diiringi alat musik eksternal, melainkan hanya menggunakan suara tepukan tangan ke dada dan paha, serta nyanyian syair dakwah dari sang pemimpin (Syekh).'},
      {'q': 'Tari tradisional Ponorogo yang memakai topeng singa adalah...', 'opts': ['Kuda Lumping', 'Reog', 'Barong', 'Jaipong'], 'ans': 'Reog', 
       'fact': 'Reog Ponorogo adalah salah satu kesenian paling ekstrem dan mistis di Indonesia. Penari utamanya, yang disebut Pembarong, harus menggunakan topeng raksasa berbentuk kepala singa berhiaskan bulu burung merak (Singo Barong) yang beratnya bisa mencapai 50 kilogram. Luar biasanya, beban seberat itu ditopang oleh sang penari hanya menggunakan kekuatan gigitan giginya saja.'},
      {'q': 'Tarian Bali yang menceritakan kisah Ramayana adalah...', 'opts': ['Pendet', 'Kecak', 'Legong', 'Barong'], 'ans': 'Kecak', 
       'fact': 'Tari Kecak diciptakan pada tahun 1930-an berkat kolaborasi seniman Bali Wayan Limbak dan pelukis Jerman Walter Spies. Tarian ini mengangkat epos epik Ramayana, terutama adegan penculikan Sita oleh Rahwana. Gerakan tarian ini diadaptasi dari ritual sanghyang, sebuah tradisi kuno di mana para penarinya masuk ke dalam kondisi trans atau kesurupan untuk mengusir roh jahat.'},
      {'q': 'Tari Jaipong dikembangkan oleh seniman bernama...', 'opts': ['Gugum Gumbira', 'Didik Nini Thowok', 'Bagong Kussudiardja', 'Sardono W. Kusumo'], 'ans': 'Gugum Gumbira', 
       'fact': 'Tari Jaipong merupakan tarian yang relatif modern karena baru diciptakan pada tahun 1970-an oleh Gugum Gumbira asal Bandung. Beliau sangat jenius karena berhasil memadukan keindahan gerak tari pergaulan Ketuk Tilu tradisional dengan dinamika gerakan seni bela diri Pencak Silat, menghasilkan tarian yang sangat enerjik, erotis, dan penuh semangat kebebasan.'},
      {'q': 'Tari Piring berasal dari daerah...', 'opts': ['Minangkabau', 'Melayu', 'Bugis', 'Dayak'], 'ans': 'Minangkabau', 
       'fact': 'Tari Piring (Tari Piriang) dari Sumatera Barat pada awalnya adalah sebuah ritual tarian syukur kepada para dewa atas panen yang melimpah sebelum masuknya agama Islam. Di akhir pertunjukan, para penari sering kali melemparkan piring-piringnya ke lantai dan menari dengan lincah di atas pecahan beling kaca yang tajam tanpa terluka sedikit pun, memamerkan unsur magis yang masih melekat.'},
      {'q': 'Tarian klasik keraton Yogyakarta/Solo adalah...', 'opts': ['Remo', 'Serimpi', 'Tayub', 'Gandrung'], 'ans': 'Serimpi', 
       'fact': 'Tari Serimpi adalah tarian pusaka yang sangat sakral di lingkungan keraton Jawa (Yogyakarta dan Surakarta). Pada masa lampau, tarian yang melambangkan keanggunan, budi pekerti luhur, dan keseimbangan alam semesta ini hanya boleh dipentaskan di dalam pendopo keraton dan hanya boleh ditarikan oleh empat orang putri yang memiliki garis keturunan bangsawan.'},
      {'q': 'Tari Kecak tidak menggunakan musik alat, melainkan...', 'opts': ['Gamelan', 'Suara Mulut Manusia', 'Angklung', 'Suling'], 'ans': 'Suara Mulut Manusia', 
       'fact': 'Daya magis Tari Kecak terletak pada paduan suara acapella dari puluhan hingga ratusan penari laki-laki bertelanjang dada yang duduk melingkar. Mereka terus-menerus meneriakkan kata "cak-cak-cak" dengan ritme yang bersahut-sahutan dan bertingkat, yang berfungsi sebagai pengganti instrumen gamelan sekaligus menciptakan suasana hipnotis yang luar biasa tegang.'},
      {'q': 'Tari Merak menggambarkan gerakan burung merak, berasal dari...', 'opts': ['Jawa Timur', 'Jawa Barat', 'Bali', 'Sumatera'], 'ans': 'Jawa Barat', 
       'fact': 'Tari Merak diciptakan oleh koreografer tari Sunda, Raden Tjetjep Somantri, pada tahun 1950-an. Tarian ini sangat memanjakan mata karena penarinya mengenakan kostum gemerlap dengan sayap yang menyerupai bulu merak. Secara filosofis, tarian ini sebenarnya menggambarkan tingkah laku burung merak jantan yang sedang memamerkan keindahan bulunya untuk memikat burung merak betina.'},
      {'q': 'Tarian untuk menyambut tamu di Bali adalah...', 'opts': ['Tari Barong', 'Tari Pendet', 'Tari Legong', 'Tari Janger'], 'ans': 'Tari Pendet', 
       'fact': 'Tari Pendet awalnya adalah tarian persembahan yang sangat sakral dan hanya ditarikan oleh para pemangku atau wanita di halaman pura saat upacara keagamaan. Seiring berjalannya waktu, para maestro seni Bali memodifikasi tarian ini menjadi tarian penyambutan selamat datang yang ikonik, di mana para penarinya membawa bokor perak berisi bunga yang kemudian ditaburkan ke arah tamu agung.'},
      {'q': 'Tari Tortor adalah tarian khas suku...', 'opts': ['Batak', 'Nias', 'Melayu', 'Minang'], 'ans': 'Batak', 
       'fact': 'Tortor bukanlah tarian yang sekadar untuk ditonton, melainkan sebuah medium komunikasi kultural. Ditarikan dengan iringan ensambel musik Gondang Sabangunan, orang Batak meyakini bahwa melalui hentakan kaki dan gerakan tangan Tortor, mereka dapat berkomunikasi dan menyampaikan harapan kepada roh leluhur (somba) serta kepada sesama sanak saudara.'},
    ],
    4: [
      {'q': 'Alat musik bambu goyang dari Jawa Barat adalah...', 'opts': ['Angklung', 'Kolintang', 'Saluang', 'Suling'], 'ans': 'Angklung', 
       'fact': 'Angklung adalah keajaiban teknik akustik bambu masyarakat Sunda. Karena satu alat angklung hanya memproduksi satu nada spesifik, maka untuk memainkan sebuah lagu dibutuhkan kerja sama puluhan orang yang menggoyangkan angklungnya pada ketukan yang tepat. Harmoni kebersamaan inilah yang membuat UNESCO menetapkannya sebagai Warisan Budaya Takbenda Dunia.'},
      {'q': 'Sasando adalah alat musik petik dari daerah...', 'opts': ['Papua', 'NTT', 'Maluku', 'Bali'], 'ans': 'NTT', 
       'fact': 'Berasal dari Pulau Rote di Nusa Tenggara Timur, Sasando merupakan alat musik berdawai yang memiliki bentuk dan material paling eksotis di dunia. Tabung utamanya terbuat dari bambu, sementara wadah resonansinya yang berfungsi memantulkan dan memperbesar suara petikan dawai dibuat dari anyaman daun lontar kering yang direntangkan hingga melengkung seperti cangkang.'},
      {'q': 'Kolintang terbuat dari bahan...', 'opts': ['Bambu', 'Logam', 'Kayu', 'Kulit Hewan'], 'ans': 'Kayu', 
       'fact': 'Kolintang adalah alat musik perkusi bernada dari masyarakat Minahasa, Sulawesi Utara, yang terbuat dari bilah-bilah kayu lokal ringan yang padat. Nama "Kolintang" sendiri konon berasal dari onomatope suara yang dihasilkannya: nada rendah yang berbunyi "Tong", nada tinggi berbunyi "Ting", dan nada tengah berbunyi "Tang", sehingga memunculkan ajakan "Mari ber-tong-ting-tang" atau Kolintang.'},
      {'q': 'Gamelan dimainkan dengan cara...', 'opts': ['Dipetik', 'Digesek', 'Dipukul', 'Ditiup'], 'ans': 'Dipukul', 
       'fact': 'Gamelan adalah orkestra atau ansambel musik tradisional terbesar di Indonesia, yang sangat populer di Jawa, Sunda, dan Bali. Sebagian besar instrumen di dalamnya, seperti saron, bonang, dan gong, terbuat dari logam perunggu atau kuningan yang dimainkan dengan cara dipukul menggunakan palu atau tabuh kayu berlapis kain untuk menghasilkan resonansi suara magis yang bertingkat-tingkat.'},
      {'q': 'Alat musik perkusi dari Papua dan Maluku adalah...', 'opts': ['Kendang', 'Tifa', 'Rebana', 'Gong'], 'ans': 'Tifa', 
       'fact': 'Bentuk Tifa memang menyerupai kendang tabung yang memanjang, namun suara yang dihasilkannya jauh lebih bergema. Tifa bukan sekadar alat musik, melainkan benda adat yang sakral. Badan kayunya sering kali diukir dengan motif-motif spiritual khas suku setempat, dan membran penutupnya biasanya menggunakan kulit biawak atau rusa yang dikencangkan dengan getah pohon.'},
      {'q': 'Saluang adalah alat musik tiup khas...', 'opts': ['Jawa Tengah', 'Minangkabau', 'Sunda', 'Bugis'], 'ans': 'Minangkabau', 
       'fact': 'Saluang adalah seruling tradisional yang terbuat dari bambu tipis (talang) asal Sumatera Barat. Alat musik ini sangat legendaris karena menuntut pemainnya menguasai teknik pernapasan rahasia yang disebut "Manyisiahkan Angok" (menyisihkan napas). Dengan teknik ini, pemain dapat meniup Saluang sambil menarik napas dari hidung secara bersamaan, sehingga alunan nada tidak terputus sama sekali.'},
      {'q': 'Sampe adalah alat musik petik dari suku...', 'opts': ['Dayak', 'Asmat', 'Batak', 'Dani'], 'ans': 'Dayak', 
       'fact': 'Sampe (atau Sape\') adalah gitar tradisional berdawai khas masyarakat Dayak di pedalaman hutan Kalimantan. Badan instrumen ini dipahat dari satu bongkahan kayu utuh dan dihiasi dengan ukiran motif burung enggang atau naga. Pada zaman dahulu, alunan dawai Sampe sering dimainkan di malam hari di balai rumah panjang (Betang) untuk memberikan ketenangan batin setelah lelah berburu.'},
      {'q': 'Pemain konduktor dalam gamelan adalah pemain...', 'opts': ['Gong', 'Kendang', 'Saron', 'Bonang'], 'ans': 'Kendang', 
       'fact': 'Dalam sebuah pergelaran gamelan Jawa yang melibatkan puluhan instrumen, tidak ada partitur nada yang tertulis. Semuanya diatur oleh pemain Kendang. Melalui pukulan tangan pada membran kulit kendangnya, ia bertugas layaknya seorang konduktor orkestra yang memberi isyarat ritmis kepada seluruh pemain lain untuk mempercepat, memperlambat, atau mengakhiri sebuah komposisi musik (Gending).'},
      {'q': 'Alat musik yang menggunakan selaput kulit hewan disebut...', 'opts': ['Aerofon', 'Membranofon', 'Idiofon', 'Kordofon'], 'ans': 'Membranofon', 
       'fact': 'Dalam ilmu etnomusikologi, instrumen penghasil suara yang sumber getarannya berasal dari selaput atau membran yang ditegangkan diklasifikasikan sebagai Membranofon. Di Nusantara, alat musik jenis ini sangat beragam bentuknya dan umumnya menggunakan kulit sapi, kambing, kerbau, atau biawak, seperti pada instrumen bedug masjid, kendang jawa, hingga rebana.'},
      {'q': 'Ceng-ceng adalah bagian dari gamelan...', 'opts': ['Jawa', 'Sunda', 'Bali', 'Madura'], 'ans': 'Bali', 
       'fact': 'Ceng-ceng adalah elemen kunci yang membedakan gamelan Bali dari gamelan daerah lain. Alat musik berbentuk seperti enam buah simbal perunggu kecil yang ditumpukkan terbalik ini dipukul dengan ritme yang sangat intens, cepat, dan menghentak. Suara "ceng-ceng-ceng" yang nyaring inilah yang memberikan nyawa dinamis, meledak-ledak, dan dramatis pada setiap pertunjukan tari Bali.'},
    ],
    5: [
      {'q': 'Museum MACAN di Jakarta adalah museum seni...', 'opts': ['Klasik', 'Prasejarah', 'Modern & Kontemporer', 'Arsitektur'], 'ans': 'Modern & Kontemporer', 
       'fact': 'Museum MACAN (Museum of Modern and Contemporary Art in Nusantara) adalah institusi pertama di Indonesia yang mendedikasikan fasilitasnya untuk seni kontemporer bertaraf internasional. Museum ini menjadi fenomena budaya pop di kalangan anak muda Jakarta, terutama ketika mereka menghadirkan karya instalasi legendaris "Infinity Mirrored Room" dari seniman avant-garde Jepang, Yayoi Kusama.'},
      {'q': 'Seniman kontemporer Jogja yang terkenal dengan mural alien adalah...', 'opts': ['Eko Nugroho', 'Heri Dono', 'Agus Suwage', 'Nyoman Masriadi'], 'ans': 'Eko Nugroho', 
       'fact': 'Eko Nugroho adalah ikon seni kontemporer generasi baru dari Yogyakarta yang mendirikan komunitas kreatif Daging Tumbuh (DGTMB). Karyanya sangat khas, menggabungkan elemen komik, kritik sosial masyarakat urban, dan bentuk-bentuk makhluk mutan berwajah tertutup (alien). Kesuksesannya membawanya berkolaborasi mendesain syal eksklusif untuk merek fesyen mewah dunia, Louis Vuitton.'},
      {'q': 'Karya seni instalasi biasanya dinikmati secara...', 'opts': ['2 Dimensi', '3 Dimensi/Ruang', 'Suara saja', 'Digital saja'], 'ans': '3 Dimensi/Ruang', 
       'fact': 'Berbeda dengan lukisan yang terpaku pada kanvas dua dimensi, seni instalasi dirancang untuk merespons dan mengubah keseluruhan ruang tiga dimensi. Seniman instalasi menyusun berbagai material, mulai dari benda sehari-hari, cahaya, hingga suara, untuk menciptakan pengalaman spasial yang utuh di mana penonton bisa berjalan di dalamnya dan merasakan emosi dari karya tersebut secara langsung.'},
      {'q': 'Patung GWK di Bali memiliki tinggi...', 'opts': ['75m', '100m', '121m', '150m'], 'ans': '121m', 
       'fact': 'Garuda Wisnu Kencana (GWK) adalah monumen patung tembaga dan kuningan seberat 3.000 ton karya visioner I Nyoman Nuarta. Berdiri setinggi 121 meter dari permukaan tanah, patung yang menggambarkan Dewa Wisnu mengendarai burung Garuda ini menjadi salah satu patung tertinggi di dunia, bahkan mengalahkan tinggi monumen Patung Liberty di Amerika Serikat.'},
      {'q': 'Taman Ismail Marzuki berlokasi di daerah...', 'opts': ['Menteng', 'Cikini', 'Kemang', 'Blok M'], 'ans': 'Cikini', 
       'fact': 'Taman Ismail Marzuki (TIM) yang terletak di kawasan Cikini, Jakarta Pusat, diresmikan oleh Gubernur Ali Sadikin pada tahun 1968. Tempat ini menjadi episentrum atau kawah candradimuka bagi pertumbuhan kesenian modern Indonesia. Nama tempat ini sendiri diambil dari nama pahlawan nasional dan komponis legendaris pencipta lagu "Gugur Bunga" dan "Rayuan Pulau Kelapa", yaitu Ismail Marzuki.'},
      {'q': 'Seniman Indonesia yang lukisannya termahal di lelang dunia adalah...', 'opts': ['Christine Ay Tjoe', 'Affandi', 'Basuki Abdullah', 'Heri Dono'], 'ans': 'Christine Ay Tjoe', 
       'fact': 'Christine Ay Tjoe, seorang seniwati asal Bandung, adalah salah satu fenomena terbesar di pasar seni global saat ini. Lukisan-lukisan abstraknya yang penuh dengan eksplorasi psikologis manusia sering kali menjadi rebutan para kolektor kakap di balai lelang Sotheby’s atau Christie’s di Hong Kong, di mana karya-karyanya bisa terjual dengan nilai fantastis mencapai puluhan miliar rupiah.'},
      {'q': 'Pameran Biennale Jogja diadakan setiap...', 'opts': ['1 Tahun', '2 Tahun', '3 Tahun', '5 Tahun'], 'ans': '2 Tahun', 
       'fact': 'Istilah "Biennale" berasal dari bahasa Italia yang secara harfiah berarti "setiap dua tahun". Biennale Jogja adalah pameran seni rupa berskala masif yang selalu menghadirkan ratusan karya inovatif. Sejak beberapa edisi terakhir, Biennale Jogja fokus mengusung konsep garis khatulistiwa (Equator), dengan mengundang seniman dari negara-negara yang dilintasi ekuator untuk berkolaborasi.'},
      {'q': 'Wayang Alien adalah kreasi dari...', 'opts': ['Eko Nugroho', 'Heri Dono', 'Tisna Sanjaya', 'Suwage'], 'ans': 'Heri Dono', 
       'fact': 'Heri Dono adalah pelopor seni rupa kontemporer eksperimental di Indonesia yang sangat dihormati di kancah internasional. Ia sering kali merakit benda-benda elektronik bekas dan menggabungkannya dengan figurologi pertunjukan wayang kulit tradisional. Hasilnya adalah instalasi makhluk-makhluk kinetik mekanis yang dijuluki "Wayang Alien" yang menyindir satir kondisi politik dan sosial modern.'},
      {'q': 'Museum Affandi terletak di pinggir sungai...', 'opts': ['Code', 'Gajah Wong', 'Winongo', 'Bengawan Solo'], 'ans': 'Gajah Wong', 
       'fact': 'Museum Affandi yang berdiri di tepi Sungai Gajah Wong, Yogyakarta, dirancang dan dibangun sendiri oleh sang maestro Affandi. Tidak seperti museum pada umumnya yang berbentuk kotak kaku, bangunan museum ini memiliki arsitektur organis dengan atap melengkung yang bentuknya terinspirasi dari daun pohon pisang (pelepah pisang), memberikan keunikan arsitektur yang sangat puitis dan personal.'},
      {'q': 'Galeri Nasional Indonesia terletak di kota...', 'opts': ['Bandung', 'Jakarta', 'Yogyakarta', 'Surabaya'], 'ans': 'Jakarta', 
       'fact': 'Berada tepat di seberang Stasiun Gambir dan Monas di jantung ibu kota Jakarta, Galeri Nasional Indonesia adalah lembaga museum rupa milik negara paling bergengsi. Tempat ini berfungsi sebagai pusat penyimpanan dan pameran ribuan karya seni rupa maestro nasional dari zaman kolonial hingga era kontemporer, sekaligus menjadi barometer utama perkembangan seni rupa di tanah air.'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('Nyeni Trivia', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: _selectedLevel != null ? IconButton(icon: const Icon(LucideIcons.chevronLeft, color: Colors.black), onPressed: () => setState(() => _selectedLevel = null)) : null,
      ),
      body: _selectedLevel == null ? _buildLevelGrid() : _buildQuizLayout(),
    );
  }

  Widget _buildLevelGrid() {
    final List<String> titles = [
      "Maestro Seni Rupa", "Ragam Hias & Kriya", "Seni Tari Tradisional", 
      "Alat Musik Daerah", "Seni Kontemporer"
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) {
        int level = index + 1;
        bool isLocked = level > _userMaxLevel; 

        return GestureDetector(
          onTap: isLocked ? () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selesaikan level sebelumnya dengan skor sempurna 10/10!"), backgroundColor: Colors.orange));
          } : () => _startLevel(level),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey[100] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isLocked ? Colors.transparent : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isLocked ? Colors.grey[300] : const Color(0xFF2C3E50),
                  child: Text("$level", style: TextStyle(color: isLocked ? Colors.grey[600] : Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titles[index], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLocked ? Colors.grey : Colors.black)),
                      const SizedBox(height: 4),
                      Text(isLocked ? "Terkunci" : "10 Pertanyaan • Siap Dimainkan", style: TextStyle(fontSize: 12, color: isLocked ? Colors.red : Colors.green)),
                    ],
                  ),
                ),
                Icon(isLocked ? LucideIcons.lock : LucideIcons.playCircle, color: isLocked ? Colors.grey : const Color(0xFF2C3E50), size: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizLayout() {
    if (_isQuizFinished) return _buildResultView();

    final currentQ = _activeQuestions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: (_currentQuestionIndex + 1) / 10, color: const Color(0xFF2C3E50), backgroundColor: Colors.grey[200], minHeight: 8, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Soal ${_currentQuestionIndex + 1} / 10", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("Skor: $_correctCount", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
            child: Text(currentQ['q'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.5), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 32),
          ...currentQ['opts'].map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              onPressed: () => _handleAnswer(opt),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Color(0xFF2C3E50), width: 1.5), alignment: Alignment.centerLeft),
              child: Text(opt, style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    bool isPassed = _correctCount == 10;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isPassed ? LucideIcons.trophy : LucideIcons.rotateCcw, size: 90, color: isPassed ? Colors.amber : Colors.orange),
            const SizedBox(height: 24),
            Text(isPassed ? "PERFECT CLEAR!" : "MISI GAGAL!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isPassed ? Colors.amber[700] : Colors.orange[800])),
            const SizedBox(height: 8),
            Text("Kamu berhasil menjawab $_correctCount dari 10 soal", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(isPassed ? "Luar biasa! Level berikutnya telah terbuka dan +200 XP ditambahkan ke akunmu." : "Kamu harus menjawab 10 soal dengan benar tanpa salah satu pun untuk membuka level berikutnya.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.5)),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => isPassed ? setState(() => _selectedLevel = null) : _startLevel(_selectedLevel!),
                icon: Icon(isPassed ? LucideIcons.list : LucideIcons.refreshCw, color: Colors.white),
                label: Text(isPassed ? "Pilih Level Selanjutnya" : "Coba Lagi (Restart)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            if (!isPassed)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(onPressed: () => setState(() => _selectedLevel = null), child: const Text("Kembali ke Menu", style: TextStyle(color: Colors.grey))),
              )
          ],
        ),
      ),
    );
  }
}