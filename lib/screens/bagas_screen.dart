import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BagasScreen extends StatefulWidget {
  const BagasScreen({super.key});

  @override
  State<BagasScreen> createState() => _BagasScreenState();
}

class _BagasScreenState extends State<BagasScreen> {
  // TODO: Nanti ganti pakai API Key kamu sendiri
  static const _apiKey = 'AIzaSyCYKKjwPkWj4If57kbzd1sMinqEw0RrKPY'; 
  
  late final GenerativeModel _model;
  late final ChatSession _chat;
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initAI();
  }

  void _initAI() {
    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'Nama kamu adalah BAGAS (Bot Asisten Galeri & Seni). '
        'Kamu adalah asisten virtual pintar untuk aplikasi bernama "Nyeni". '
        'Tugas utamamu hanya DUA: 1) Menjawab pertanyaan seputar seni, budaya, pameran, dan seniman Indonesia. '
        '2) Membantu pengguna menggunakan aplikasi Nyeni (seperti cara beli tiket, lihat profil, main trivia, atau pakai fitur peta). '
        'Gunakan bahasa yang asyik, anak muda, tapi tetap sopan. '
        'PENTING: Jika pengguna bertanya di luar topik seni, budaya, atau aplikasi Nyeni (misalnya bertanya matematika, coding, politik, atau resep makanan), TOLAK dengan sopan dan ingatkan bahwa kamu hanya asisten kesenian.'
      ),
    );

    _chat = _model.startChat();
    
    _messages.add({
      'isUser': false, 
      'text': 'Halo! Aku BAGAS(Bot Asisten Galeri & Seni), asisten virtual Nyeni. Ada yang bisa aku bantu soal kesenian atau info pameran hari ini?'
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // ==========================================
    // LOGIKA LIMITER (5 Pesan per 15 Menit)
    // ==========================================
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Ambil data memori lokal
    final lastWindowStr = prefs.getString('bagas_time_window');
    int msgCount = prefs.getInt('bagas_msg_count') ?? 0;

    // Tentukan waktu mulai jendela 15 menit
    DateTime windowStart = lastWindowStr != null ? DateTime.parse(lastWindowStr) : now;

    // Jika sudah lewat 15 menit dari pesan pertama, reset hitungan!
    if (now.difference(windowStart).inMinutes >= 10) {
      windowStart = now;
      msgCount = 0;
    }

    // Jika batas 5 pesan sudah tercapai
    if (msgCount >= 5) {
      int sisaWaktu = 15 - now.difference(windowStart).inMinutes;
      // Pastikan sisa waktu tidak 0 jika pembulatannya mepet
      if (sisaWaktu <= 0) sisaWaktu = 1; 

      setState(() {
        _messages.add({
          'isUser': false, 
          'text': 'Waduh, limit ngobrol kita udah habis nih (Maksimal 5 pertanyaan per 15 menit). Biar otak BAGAS nggak *overheat*, coba tanya lagi dalam $sisaWaktu menit ya! ⏳'
        });
      });
      _scrollToBottom();
      return; // Stop pengiriman ke Gemini
    }

    // Jika aman, update data penyimpanan lokal
    msgCount++;
    await prefs.setInt('bagas_msg_count', msgCount);
    await prefs.setString('bagas_time_window', windowStart.toIso8601String());
    // ==========================================

    // Lanjut kirim pesan
    setState(() {
      _messages.add({'isUser': true, 'text': text});
      _isLoading = true;
    });
    
    _textController.clear();
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final responseText = response.text;

      setState(() {
        _messages.add({'isUser': false, 'text': responseText ?? 'Maaf, BAGAS lagi error nih.'});
      });
    } catch (e) {
      setState(() {
        _messages.add({'isUser': false, 'text': 'Waduh, koneksi ke otak BAGAS terputus. Coba cek internetmu ya! Error: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bot, color: Color(0xFF2C3E50)),
            SizedBox(width: 8),
            Text('Tanya BAGAS', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          ],
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF2C3E50) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser ? null : Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))
                      ]
                    ),
                    child: Text(
                      msg['text'] as String,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2C3E50))),
                  SizedBox(width: 8),
                  Text("BAGAS sedang mengetik...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Tanya info pameran atau seni...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(color: Color(0xFF2C3E50), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}