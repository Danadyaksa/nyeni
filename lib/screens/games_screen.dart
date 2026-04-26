import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showResult = false;

  // Data Pertanyaan Kuis (Bisa ditambahin nanti)
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Event seni rupa kontemporer tahunan terbesar yang diadakan di Yogyakarta adalah...',
      'options': ['Prambanan Jazz', 'ARTJOG', 'We The Fest', 'Dieng Culture Festival'],
      'answer': 'ARTJOG',
    },
    {
      'question': 'Siapakah pelukis legendaris Indonesia yang terkenal dengan aliran ekspresionisme?',
      'options': ['Raden Saleh', 'Basuki Abdullah', 'Affandi', 'Sudjojono'],
      'answer': 'Affandi',
    },
    {
      'question': 'Seni pertunjukan bayangan boneka tradisional yang sudah diakui UNESCO adalah...',
      'options': ['Wayang Kulit', 'Ketoprak', 'Ludruk', 'Sintren'],
      'answer': 'Wayang Kulit',
    },
  ];

  void _answerQuestion(String selectedOption) {
    final isCorrect = selectedOption == _questions[_currentQuestionIndex]['answer'];

    if (isCorrect) {
      setState(() {
        _score += 50; // Dapet 50 XP kalau bener
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Benar! +50 XP 🎯'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yah, kurang tepat! 🥲'), backgroundColor: Colors.red, duration: Duration(seconds: 1)),
      );
    }

    // Lanjut ke pertanyaan berikutnya atau tampilkan hasil
    Future.delayed(const Duration(seconds: 1), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
      } else {
        setState(() {
          _showResult = true;
        });
      }
    });
  }

  void _resetGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nyeni Games', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2C3E50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('$_score XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _showResult
            ? _buildResultScreen()
            : _buildQuizScreen(),
      ),
    );
  }

  // Tampilan saat kuis sedang berjalan
  Widget _buildQuizScreen() {
    final question = _questions[_currentQuestionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pertanyaan ${_currentQuestionIndex + 1} dari ${_questions.length}',
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Text(
            question['question'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        ...List.generate(question['options'].length, (index) {
          final option = question['options'][index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: OutlinedButton(
              onPressed: () => _answerQuestion(option),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFF2C3E50), width: 1.5),
              ),
              child: Text(
                option,
                style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50), fontWeight: FontWeight.w600),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Tampilan saat kuis selesai
  Widget _buildResultScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(LucideIcons.trophy, size: 80, color: Colors.amber),
        const SizedBox(height: 24),
        const Text('Kuis Selesai!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Kamu mendapatkan total $_score XP', style: const TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: _resetGame,
          icon: const Icon(LucideIcons.rotateCcw, color: Colors.white),
          label: const Text('Main Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C3E50),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}