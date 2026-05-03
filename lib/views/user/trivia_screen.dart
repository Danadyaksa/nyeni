import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/game_controller.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  int? _selectedLevel;
  List<Map<String, dynamic>> _activeQuestions = [];
  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  int _userMaxLevel = 1; 
  bool _isQuizFinished = false;
  bool _isLoading = true;
  
  final _profileController = ProfileController();
  final _gameController = GameController();

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  // MENGGUNAKAN MYSQL VIA NODE.JS
  Future<void> _loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_data');
      if (userStr != null) {
        final user = jsonDecode(userStr);
        final freshUser = await _profileController.getUserProfile(user['id'].toString());
        
        if (freshUser != null) {
          setState(() {
            _userMaxLevel = freshUser.completedLevelsTrivia;
            _isLoading = false;
          });
        }
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

  // MENGGUNAKAN MYSQL VIA NODE.JS DENGAN LOGIKA LEVELMU YANG LAMA
  Future<void> _processLevelResult() async {
    setState(() => _isQuizFinished = true);

    if (_correctCount == 10) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userStr = prefs.getString('user_data');
        
        if (userStr != null) {
          final user = jsonDecode(userStr);
          final userId = user['id'].toString();
          
          // Ambil data terbaru
          final freshUser = await _profileController.getUserProfile(userId);
          if (freshUser == null) return;
          
          int currentXp = freshUser.totalXp;
          int newXp = currentXp + 100; // Reward 100 XP per level
          
          // Hitung Level Berdasarkan Total XP Baru menggunakan GameController
          int newLevel = _gameController.calculateLevel(newXp);
          
          int updatedCompletedLevel = _userMaxLevel;
          if (_selectedLevel == _userMaxLevel) {
            updatedCompletedLevel = _userMaxLevel + 1;
          }

          // UPDATE KE DATABASE MYSQL
          await _gameController.updateProgress(
            userId: userId,
            totalXp: newXp,
            level: newLevel,
            triviaLevel: updatedCompletedLevel,
            labirinLevel: freshUser.completedLevelsLabirin,
          );

          setState(() => _userMaxLevel = updatedCompletedLevel);
        }
      } catch (e) {
        debugPrint('🔥 Error Simpan Trivia: $e');
        setState(() {
           if (_selectedLevel == _userMaxLevel) _userMaxLevel = _userMaxLevel + 1;
        });
      }
    }
  }

  // ==========================================
  // DATA KUIS 
  // ==========================================
  // ==========================================
  // DATA KUIS FINAL: 50 SOAL (5 LEVEL x 10 SOAL)
  // ==========================================
  final Map<int, List<Map<String, dynamic>>> _allQuizData = {
    1: [
      {'q': 'Pelukis maestro Indonesia beraliran ekspresionisme adalah...', 'opts': ['Raden Saleh', 'Affandi', 'Basuki Abdullah', 'Sudjojono'], 'ans': 'Affandi', 'fact': 'Affandi dikenal dunia karena teknik eksentriknya dalam melukis langsung tanpa kuas.'},
      {'q': 'Festival seni rupa kontemporer di Yogyakarta disebut...', 'opts': ['ARTJOG', 'FKY', 'Sekaten', 'Biennale'], 'ans': 'ARTJOG', 'fact': 'ARTJOG merupakan pameran seni rupa tahunan yang fasad gedungnya selalu dirombak total tiap tahun.'},
      {'q': 'Bapak Seni Rupa Modern Indonesia adalah...', 'opts': ['Affandi', 'Raden Saleh', 'S. Sudjojono', 'Hendra Gunawan'], 'ans': 'S. Sudjojono', 'fact': 'S. Sudjojono pendiri PERSAGI untuk mencari corak seni rupa asli Indonesia.'},
      {'q': 'Wayang Kulit ditetapkan UNESCO sebagai warisan dunia pada...', 'opts': ['2001', '2003', '2005', '2010'], 'ans': '2003', 'fact': 'Pada tanggal 7 November 2003, UNESCO secara resmi mengakui Wayang Kulit.'},
      {'q': 'Candi Buddha terbesar di dunia di Indonesia adalah...', 'opts': ['Prambanan', 'Mendut', 'Borobudur', 'Sewu'], 'ans': 'Borobudur', 'fact': 'Candi Borobudur dibangun pada abad ke-8 dan ke-9 Masehi oleh Dinasti Syailendra.'},
      {'q': 'Raden Saleh berguru seni lukis di negara...', 'opts': ['Prancis', 'Belanda', 'Inggris', 'Jerman'], 'ans': 'Belanda', 'fact': 'Raden Saleh adalah pelukis pertama keturunan Jawa yang belajar di Eropa.'},
      {'q': 'Patung Dirgantara di Jakarta juga dikenal sebagai...', 'opts': ['Patung Tugu Tani', 'Patung Pancoran', 'Patung Monas', 'Patung Selamat Datang'], 'ans': 'Patung Pancoran', 'fact': 'Patung ini dirancang oleh pematung Edhi Sunarso atas instruksi Soekarno.'},
      {'q': 'Motif batik Megamendung berasal dari...', 'opts': ['Solo', 'Yogyakarta', 'Cirebon', 'Pekalongan'], 'ans': 'Cirebon', 'fact': 'Motif Megamendung terpengaruh oleh seni keramik kebudayaan Tiongkok.'},
      {'q': 'Warna dominan pada lukisan Hendra Gunawan biasanya...', 'opts': ['Gelap', 'Monokrom', 'Cerah & Berani', 'Pastel'], 'ans': 'Cerah & Berani', 'fact': 'Hendra Gunawan menggunakan warna cerah dan bertabrakan melukis kehidupan rakyat.'},
      {'q': 'Teater tradisional dari Betawi disebut...', 'opts': ['Lenong', 'Ketoprak', 'Ludruk', 'Randai'], 'ans': 'Lenong', 'fact': 'Lenong berkembang sejak akhir abad 19, dimainkan tanpa menggunakan naskah (spontan).'},
    ],
    2: [
      {'q': 'Kain tenun khas masyarakat Batak disebut...', 'opts': ['Ulos', 'Songket', 'Tapis', 'Ikat'], 'ans': 'Ulos', 'fact': 'Ulos merupakan simbol ikatan kasih sayang dan restu dalam ritual siklus hidup Batak.'},
      {'q': 'Rumah adat berbentuk limas di Sumatera Selatan disebut...', 'opts': ['Rumah Gadang', 'Rumah Limas', 'Joglo', 'Honai'], 'ans': 'Rumah Limas', 'fact': 'Lantai berjenjang di Rumah Limas digunakan untuk membedakan status sosial tamu.'},
      {'q': 'Suku di Papua yang terkenal dengan seni ukir kayunya adalah...', 'opts': ['Dani', 'Asmat', 'Biak', 'Sentani'], 'ans': 'Asmat', 'fact': 'Mereka percaya nenek moyang tercipta dari patung kayu pahatan dewa.'},
      {'q': 'Senjata tradisional Jawa yang diakui UNESCO adalah...', 'opts': ['Keris', 'Kujang', 'Rencong', 'Mandau'], 'ans': 'Keris', 'fact': 'Keris diakui sebagai mahakarya seni kriya logam dan nilai spiritual tinggi.'},
      {'q': 'Batik yang dibuat dengan canting disebut batik...', 'opts': ['Cap', 'Tulis', 'Printing', 'Ikat'], 'ans': 'Tulis', 'fact': 'Batik tulis membutuhkan ketelitian manual hingga waktu bulan-bulanan.'},
      {'q': 'Pusat gerabah di Yogyakarta berada di desa...', 'opts': ['Kotagede', 'Kasongan', 'Manding', 'Bantul'], 'ans': 'Kasongan', 'fact': 'Kasongan adalah sentra kerajinan tanah liat dan elemen dekorasi.'},
      {'q': 'Alat untuk membatik disebut...', 'opts': ['Sudi', 'Canting', 'Pahat', 'Kuas'], 'ans': 'Canting', 'fact': 'Canting adalah alat dari tembaga untuk menampung dan menorehkan malam (lilin) panas.'},
      {'q': 'Motif batik Parang dulunya hanya boleh dipakai oleh...', 'opts': ['Petani', 'Pedagang', 'Keluarga Raja', 'Prajurit'], 'ans': 'Keluarga Raja', 'fact': 'Motif parang termasuk motif larangan yang dikhususkan bagi bangsawan kraton.'},
      {'q': 'Songket yang benangnya menggunakan emas berasal dari...', 'opts': ['Palembang', 'Papua', 'Bali', 'Aceh'], 'ans': 'Palembang', 'fact': 'Sering dijuluki ratu segala kain karena corak timbul benang emas yang mewah.'},
      {'q': 'Patung kayu dari Bali yang sangat detail biasanya dari daerah...', 'opts': ['Kuta', 'Ubud', 'Mas', 'Celuk'], 'ans': 'Mas', 'fact': 'Desa Mas adalah jantung seni ukir patung dewa dan tokoh di Bali.'},
    ],
    3: [
      {'q': 'Tari Saman yang diakui UNESCO sebagai warisan budaya takbenda berasal dari provinsi...', 'opts': ['Sumatera Utara', 'Aceh', 'Riau', 'Sumatera Barat'], 'ans': 'Aceh', 'fact': 'Tari Saman dimainkan tanpa alat musik, hanya mengandalkan suara tepukan tangan dan paha penarinya.'},
      {'q': 'Tarian dari Bali yang dibawakan oleh puluhan laki-laki bertelanjang dada dan meneriakkan kata "cak" adalah...', 'opts': ['Tari Barong', 'Tari Legong', 'Tari Kecak', 'Tari Pendet'], 'ans': 'Tari Kecak', 'fact': 'Tari Kecak diciptakan pada 1930-an oleh Wayan Limbak dan pelukis Jerman Walter Spies.'},
      {'q': 'Kesenian tari tradisional yang menggunakan topeng singa raksasa berhias bulu merak berasal dari...', 'opts': ['Banyuwangi', 'Ponorogo', 'Madiun', 'Malang'], 'ans': 'Ponorogo', 'fact': 'Topeng Reog (Singo Barong) yang beratnya 50 kg hanya ditopang menggunakan gigitan penarinya.'},
      {'q': 'Tari Jaipong yang sangat dinamis dan populer di Jawa Barat diciptakan oleh seniman...', 'opts': ['Gugum Gumbira', 'Bagong Kussudiardja', 'Didik Nini Thowok', 'Sardono W. Kusumo'], 'ans': 'Gugum Gumbira', 'fact': 'Jaipong merupakan gabungan dari kesenian tradisional Ketuk Tilu dan pencak silat.'},
      {'q': 'Tari Piring, di mana penarinya menari lincah membawa piring di telapak tangannya, berasal dari...', 'opts': ['Bengkulu', 'Lampung', 'Sumatera Barat', 'Sumatera Selatan'], 'ans': 'Sumatera Barat', 'fact': 'Pada akhir pertunjukan, penari sering memecahkan piring dan menari di atas pecahan kaca tanpa terluka.'},
      {'q': 'Tarian klasik dan sakral dari Keraton Jawa yang ditarikan oleh empat penari putri adalah...', 'opts': ['Tari Bedhaya', 'Tari Serimpi', 'Tari Gambyong', 'Tari Golek'], 'ans': 'Tari Serimpi', 'fact': 'Empat penari pada tari Serimpi melambangkan empat elemen alam: air, api, angin, dan bumi.'},
      {'q': 'Tarian kreasi baru dari Sunda yang mengekspresikan keindahan burung merak jantan adalah...', 'opts': ['Tari Merak', 'Tari Kupu-Kupu', 'Tari Cendrawasih', 'Tari Garuda'], 'ans': 'Tari Merak', 'fact': 'Diciptakan oleh Raden Tjetjep Somantri pada 1950-an dengan kostum bersayap layaknya bulu merak yang mekar.'},
      {'q': 'Tari Tortor adalah tarian komunal penyampaian batin bagi masyarakat...', 'opts': ['Minahasa', 'Dayak', 'Batak', 'Toraja'], 'ans': 'Batak', 'fact': 'Tortor diiringi alat musik Gondang Sabangunan dan dulunya ditarikan untuk berkomunikasi dengan roh leluhur.'},
      {'q': 'Tari Pendet awalnya adalah tarian sakral di pura, namun kini sering digunakan sebagai tarian...', 'opts': ['Perang', 'Penyambutan Tamu', 'Panen Raya', 'Tolak Bala'], 'ans': 'Penyambutan Tamu', 'fact': 'Ciri khas Tari Pendet adalah gerakan menaburkan bunga dari bokor (nampan perak) ke arah tamu.'},
      {'q': 'Tarian penyambutan tamu agung yang menggambarkan kejayaan kerajaan maritim di Sumatera Selatan adalah...', 'opts': ['Tari Tanggai', 'Tari Sekapur Sirih', 'Tari Gending Sriwijaya', 'Tari Zapin'], 'ans': 'Tari Gending Sriwijaya', 'fact': 'Penari utama memakai atribut kuku palsu dari emas (Tanggai) untuk menekankan keanggunan jari.'},
    ],
    4: [
      {'q': 'Alat musik tabung bambu yang dimainkan dengan cara digoyangkan khas Jawa Barat adalah...', 'opts': ['Kolintang', 'Angklung', 'Saluang', 'Saron'], 'ans': 'Angklung', 'fact': 'Angklung diakui UNESCO pada 2010. Butuh puluhan orang menggoyangkan angklungnya untuk memainkan satu lagu utuh.'},
      {'q': 'Sasando adalah alat musik petik berdawai yang memiliki wadah resonansi dari daun lontar, berasal dari...', 'opts': ['Pulau Rote (NTT)', 'Pulau Nias (Sumut)', 'Pulau Lombok (Bali)', 'Pulau Biak (Papua)'], 'ans': 'Pulau Rote (NTT)', 'fact': 'Nama Sasando berasal dari kata "sasandu" yang berarti alat yang bergetar atau berbunyi.'},
      {'q': 'Alat musik perkusi bernada dari bilah-bilah kayu khas masyarakat Minahasa adalah...', 'opts': ['Talempong', 'Gamelan', 'Calung', 'Kolintang'], 'ans': 'Kolintang', 'fact': 'Nama Kolintang berasal dari bunyi kayunya: "Tong" (rendah), "Ting" (tinggi), dan "Tang" (tengah).'},
      {'q': 'Saluang adalah alat musik tiup sejenis seruling bambu yang berasal dari daerah...', 'opts': ['Jawa Tengah', 'Minangkabau', 'Sunda', 'Madura'], 'ans': 'Minangkabau', 'fact': 'Pemain Saluang mahir teknik pernapasan melingkar agar bisa meniup tanpa terputus sama sekali.'},
      {'q': 'Alat musik pukul yang sering mengiringi tarian perang di Papua dan Maluku adalah...', 'opts': ['Rebana', 'Tifa', 'Gendang', 'Taganing'], 'ans': 'Tifa', 'fact': 'Tifa biasanya dilapisi kulit biawak atau rusa liar agar menghasilkan suara yang sangat nyaring.'},
      {'q': 'Dalam ansambel Gamelan Jawa, alat musik yang berfungsi sebagai konduktor pengatur irama adalah...', 'opts': ['Gong', 'Saron', 'Kendang', 'Bonang'], 'ans': 'Kendang', 'fact': 'Pemain kendang mengatur cepat lambatnya tempo irama tanpa adanya partitur tertulis.'},
      {'q': 'Sampe adalah alat musik petik tradisional yang badannya diukir dengan motif khas suku...', 'opts': ['Batak', 'Asmat', 'Dayak', 'Toraja'], 'ans': 'Dayak', 'fact': 'Sape dulunya digunakan dalam ritual penyembuhan, kini dimainkan untuk mengiringi tarian.'},
      {'q': 'Alat musik perkusi mirip bonang yang berasal dari Minangkabau adalah...', 'opts': ['Talempong', 'Ceng-ceng', 'Gordang', 'Aramba'], 'ans': 'Talempong', 'fact': 'Talempong bisa dimainkan sambil duduk atau sambil berjalan dalam arak-arakan budaya.'},
      {'q': 'Sepasang simbal perunggu kecil yang menjadi ciri khas musik Gamelan Bali adalah...', 'opts': ['Tari Piring', 'Ceng-ceng', 'Kempul', 'Gong Kebyar'], 'ans': 'Ceng-ceng', 'fact': 'Ceng-ceng memberi aksen suara meledak-ledak yang membuat musik Bali terdengar sangat dinamis.'},
      {'q': 'Alat musik ritmis bundar pipih berlapis kulit yang erat kaitannya dengan penyebaran Islam di Nusantara adalah...', 'opts': ['Tifa', 'Kendang', 'Rebana', 'Beduq'], 'ans': 'Rebana', 'fact': 'Rebana sering dimainkan untuk mengiringi kesenian bernafaskan Islam seperti Qasidah dan Hadroh.'},
    ],
    5: [
      {'q': 'Museum seni modern dan kontemporer bertaraf internasional pertama di Indonesia (Jakarta) adalah...', 'opts': ['Galeri Nasional', 'Museum MACAN', 'Art:1 New Museum', 'Museum Affandi'], 'ans': 'Museum MACAN', 'fact': 'Museum MACAN pernah sangat viral karena pameran "Infinity Mirrored Room" karya Yayoi Kusama.'},
      {'q': 'Pelukis kontemporer Bali yang karya lukisannya menampilkan sosok hitam besar bersatir komedi adalah...', 'opts': ['I Nyoman Nuarta', 'Nyoman Masriadi', 'Agus Suwage', 'Heri Dono'], 'ans': 'Nyoman Masriadi', 'fact': 'Masriadi adalah salah satu pelukis Indonesia dengan harga lukisan termahal di balai lelang dunia.'},
      {'q': 'Seniman kontemporer dari Yogyakarta (pendiri DGTMB) yang terkenal dengan visual alien/mutan adalah...', 'opts': ['Tisna Sanjaya', 'Eko Nugroho', 'Heri Dono', 'Ugo Untoro'], 'ans': 'Eko Nugroho', 'fact': 'Eko Nugroho berhasil memasukkan unsur mural jalanan ke galeri elit, bahkan berkolaborasi dengan Louis Vuitton.'},
      {'q': 'Karya seni rupa yang dirancang secara tiga dimensi untuk merespons dan menyatu dengan ruang pameran disebut...', 'opts': ['Seni Lukis', 'Seni Kriya', 'Seni Instalasi', 'Seni Grafis'], 'ans': 'Seni Instalasi', 'fact': 'Seni instalasi tidak hanya dilihat, tapi seringkali bisa dimasuki dan dirasakan langsung oleh pengunjung.'},
      {'q': 'Seniman yang sering menggabungkan elemen wayang kulit tradisional dengan mesin elektronik menjadi patung kinetik adalah...', 'opts': ['Heri Dono', 'Eko Nugroho', 'Entang Wiharso', 'Raden Saleh'], 'ans': 'Heri Dono', 'fact': 'Heri Dono sering menyebut karya kinetiknya sebagai "Wayang Mesin" untuk kritik sosial politik.'},
      {'q': 'Pameran seni rupa tahunan di Yogyakarta yang terkenal selalu mengubah fasad (wajah) gedungnya adalah...', 'opts': ['Biennale Jogja', 'FKY', 'ARTJOG', 'Indonesian Contemporary Art'], 'ans': 'ARTJOG', 'fact': 'ARTJOG merupakan salah satu bursa seni rupa kontemporer terbesar dan paling dinanti di Asia Tenggara.'},
      {'q': 'Patung tembaga raksasa Garuda Wisnu Kencana (GWK) di Bali merupakan mahakarya dari pematung...', 'opts': ['Edhi Sunarso', 'I Nyoman Nuarta', 'G. Sidharta', 'Dolorosa Sinaga'], 'ans': 'I Nyoman Nuarta', 'fact': 'Patung GWK setinggi 121 meter ini dibangun dengan merakit ribuan modul tembaga selama hampir 30 tahun.'},
      {'q': 'Seniwati abstrak ekspresif asal Bandung yang lukisannya memecahkan rekor lelang termahal di Asia adalah...', 'opts': ['Arahmaiani', 'Christine Ay Tjoe', 'Dolorosa Sinaga', 'Mella Jaarsma'], 'ans': 'Christine Ay Tjoe', 'fact': 'Karya Christine sangat diincar kolektor global karena kedalaman eksplorasi emosi manusianya.'},
      {'q': 'Seni kontemporer di mana tubuh senimannya sendiri menjadi medium utama karya di depan penonton disebut...', 'opts': ['Seni Patung', 'Performance Art', 'Seni Instalasi', 'Seni Kinetik'], 'ans': 'Performance Art', 'fact': 'Seniman performance art seperti Melati Suryodarmo sering melakukan aksi teatrikal ekstrem untuk menyampaikan pesan.'},
      {'q': 'Pusat kesenian dan kebudayaan modern yang didirikan pada tahun 1968 oleh Gubernur Ali Sadikin di Jakarta adalah...', 'opts': ['Taman Mini (TMII)', 'Taman Ismail Marzuki', 'Gedung Kesenian Jakarta', 'Pasar Seni Ancol'], 'ans': 'Taman Ismail Marzuki', 'fact': 'TIM di Cikini menjadi kawah candradimuka bagi lahirnya banyak seniman rupa, film, dan teater legendaris.'},
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
                      const SizedBox(height: 6),
                      // UI LAMA KAMU TETAP ADA DI SINI
                      Row(
                        children: [
                          Icon(isLocked ? LucideIcons.lock : LucideIcons.playCircle, size: 14, color: isLocked ? Colors.red : Colors.green),
                          const SizedBox(width: 4),
                          Text(isLocked ? "Terkunci" : "Siap Dimainkan", style: TextStyle(fontSize: 12, color: isLocked ? Colors.red : Colors.green)),
                          const SizedBox(width: 8),
                          if (!isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text("+100 XP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[900])),
                            )
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: Colors.grey.shade400, size: 24),
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
            Text(isPassed ? "Luar biasa! Level berikutnya telah terbuka dan +100 XP ditambahkan ke akunmu." : "Kamu harus menjawab 10 soal dengan benar tanpa salah satu pun untuk membuka level berikutnya.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.5)),
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