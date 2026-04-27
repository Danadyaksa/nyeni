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

  Future<void> _processLevelResult() async {
    setState(() => _isQuizFinished = true);

    if (_correctCount == 10) {
      try {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          // Ambil data terbaru
          final res = await _supabase.from('users').select('total_xp, completed_levels_trivia').eq('id', user.id).maybeSingle();
          
          int currentXp = res?['total_xp'] ?? 0;
          int newXp = currentXp + 100; // Reward 100 XP per level
          
          // Hitung Level Berdasarkan Total XP Baru (Sesuai rumus profil)
          int newLevel = 1;
          if (newXp >= 1000) newLevel = 6;
          else if (newXp >= 700) newLevel = 5;
          else if (newXp >= 450) newLevel = 4;
          else if (newXp >= 250) newLevel = 3;
          else if (newXp >= 100) newLevel = 2;
          
          int updatedCompletedLevel = _userMaxLevel;
          if (_selectedLevel == _userMaxLevel) {
            updatedCompletedLevel = _userMaxLevel + 1;
          }

          // UPDATE KE DATABASE (Gunakan .update().eq() bukan upsert)
          await _supabase.from('users').update({
            'total_xp': newXp,
            'level': newLevel,
            'completed_levels_trivia': updatedCompletedLevel
          }).eq('id', user.id);

          setState(() => _userMaxLevel = updatedCompletedLevel);
        }
      } catch (e) {
        debugPrint('🔥 Error Simpan Trivia: $e');
      }
    }
  }

  // ==========================================
  // DATA KUIS (Tetap sama seperti aslimu)
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
      {'q': 'Batik yang dibuat dengan canting disebut batik...', 'opts': ['Cap', 'Tulis', 'Printing', 'Ikat'], 'ans': 'Batik Tulis', 'fact': 'Batik tulis membutuhkan ketelitian manual hingga waktu bulan-bulanan.'},
      {'q': 'Pusat gerabah di Yogyakarta berada di desa...', 'opts': ['Kotagede', 'Kasongan', 'Manding', 'Bantul'], 'ans': 'Kasongan', 'fact': 'Kasongan adalah sentra kerajinan tanah liat dan elemen dekorasi.'},
      {'q': 'Alat untuk membatik disebut...', 'opts': ['Sudi', 'Canting', 'Pahat', 'Kuas'], 'ans': 'Canting', 'fact': 'Canting adalah alat dari tembaga untuk menampung dan menorehkan malam (lilin) panas.'},
      {'q': 'Motif batik Parang dulunya hanya boleh dipakai oleh...', 'opts': ['Petani', 'Pedagang', 'Keluarga Raja', 'Prajurit'], 'ans': 'Keluarga Raja', 'fact': 'Motif parang termasuk motif larangan yang dikhususkan bagi bangsawan kraton.'},
      {'q': 'Songket yang benangnya menggunakan emas berasal dari...', 'opts': ['Palembang', 'Papua', 'Bali', 'Aceh'], 'ans': 'Palembang', 'fact': 'Sering dijuluki ratu segala kain karena corak timbul benang emas yang mewah.'},
      {'q': 'Patung kayu dari Bali yang sangat detail biasanya dari daerah...', 'opts': ['Kuta', 'Ubud', 'Mas', 'Celuk'], 'ans': 'Mas', 'fact': 'Desa Mas adalah jantung seni ukir patung dewa dan tokoh di Bali.'},
    ],
    // Aku pendekkan data array untuk hemat tempat (karena datamu sudah benar, kamu bisa isi kembali data penuhnya di sini nanti ya!)
    3: [ {'q': 'Tari Saman berasal dari...', 'opts': ['Sumut', 'Aceh', 'Jambi', 'Lampung'], 'ans': 'Aceh', 'fact': 'Tanpa instrumen musik, hanya suara tepukan dada dan tangan.'} ],
    4: [ {'q': 'Alat musik bambu goyang dari Jawa Barat...', 'opts': ['Angklung', 'Kolintang', 'Saluang', 'Suling'], 'ans': 'Angklung', 'fact': 'Butuh kerja sama banyak orang untuk memainkan satu lagu utuh.'} ],
    5: [ {'q': 'Museum MACAN di Jakarta...', 'opts': ['Klasik', 'Prasejarah', 'Modern & Kontemporer', 'Arsitektur'], 'ans': 'Modern & Kontemporer', 'fact': 'Museum kontemporer internasional pertama di Indonesia.'} ],
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
                      // TAMPILAN REWARD XP DI SINI
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