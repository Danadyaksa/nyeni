import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

class MoreMenuSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const Padding(padding: EdgeInsets.all(16.0), child: Text("Menu Lainnya", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
            const Divider(height: 1),
            _buildMenuTile(context, LucideIcons.refreshCcw, "Konversi Mata Uang", Colors.green, () => _showCurrencyDialog(context)),
            _buildMenuTile(context, LucideIcons.clock, "Konversi Waktu", Colors.blue, () => _showTimeDialog(context)),
            _buildMenuTile(context, LucideIcons.messageSquare, "Kritik & Saran TPM", Colors.orange, () => _showFeedbackDialog(context)),
            _buildMenuTile(context, LucideIcons.info, "About Us", Colors.purple, () => _showAboutDialog(context)),
            const Divider(),
            _buildMenuTile(context, LucideIcons.logOut, "Keluar", Colors.red, () async {
              await AuthService().logout();
              if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            }, isLogout: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _buildMenuTile(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isLogout ? Colors.red : const Color(0xFF2C3E50))),
      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
      onTap: () {
        if (isLogout) Navigator.pop(context); 
        onTap();
      },
    );
  }

  // ==========================================
  // 1. DIALOG KONVERSI MATA UANG
  // ==========================================
  static void _showCurrencyDialog(BuildContext context) {
    String fromCurrency = 'USD';
    String toCurrency = 'IDR';
    TextEditingController amountCtrl = TextEditingController();
    String resultText = "Hasil akan muncul di sini";
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [Icon(LucideIcons.refreshCcw, color: Colors.green), SizedBox(width: 8), Text("Konversi Kurs")]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Jumlah", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownButton<String>(
                    value: fromCurrency,
                    items: ['USD', 'EUR', 'GBP', 'JPY', 'IDR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => fromCurrency = val!),
                  ),
                  const Icon(LucideIcons.arrowRightLeft, color: Colors.grey),
                  DropdownButton<String>(
                    value: toCurrency,
                    items: ['USD', 'EUR', 'GBP', 'JPY', 'IDR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => toCurrency = val!),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              isLoading 
                ? const CircularProgressIndicator()
                : Container(padding: const EdgeInsets.all(12), width: double.infinity, decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(resultText, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
              onPressed: () async {
                if (amountCtrl.text.isEmpty) return;
                setState(() => isLoading = true);
                try {
                  final res = await http.get(Uri.parse("https://api.frankfurter.app/latest?amount=${amountCtrl.text}&from=$fromCurrency&to=$toCurrency"));
                  if (res.statusCode == 200) {
                    final data = jsonDecode(res.body);
                    setState(() => resultText = "${data['rates'][toCurrency]} $toCurrency");
                  } else {
                    setState(() => resultText = "Gagal memuat kurs");
                  }
                } catch (e) {
                  setState(() => resultText = "Error jaringan");
                } finally {
                  setState(() => isLoading = false);
                }
              },
              child: const Text("Konversi", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. DIALOG KONVERSI WAKTU
  // ==========================================
  static void _showTimeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(LucideIcons.clock, color: Colors.blue), SizedBox(width: 8), Text("Waktu Nusantara")]),
        content: StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            final now = DateTime.now().toUtc();
            final wib = now.add(const Duration(hours: 7));
            final wita = now.add(const Duration(hours: 8));
            final wit = now.add(const Duration(hours: 9));

            String format(DateTime t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}";

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTimeRow("WIB", "Waktu Ind. Barat", format(wib)),
                const Divider(),
                _buildTimeRow("WITA", "Waktu Ind. Tengah", format(wita)),
                const Divider(),
                _buildTimeRow("WIT", "Waktu Ind. Timur", format(wit)),
                const Divider(),
                _buildTimeRow("GMT", "Greenwich Time", format(now)),
              ],
            );
          },
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))],
      ),
    );
  }

  static Widget _buildTimeRow(String title, String sub, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey))]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF2C3E50), borderRadius: BorderRadius.circular(8)), child: Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2))),
        ],
      ),
    );
  }

  // ==========================================
  // 3. DIALOG ABOUT US
  // ==========================================
  static void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.code2, size: 60, color: Color(0xFF2C3E50)),
            const SizedBox(height: 16),
            const Text("Aplikasi Nyeni", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Dikembangkan untuk memenuhi tugas mata kuliah TPM.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Column(
                children: [
                  Text("Mohammad Atilla Danadyaksa", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple), textAlign: TextAlign.center),
                  Text("123230134", style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                  SizedBox(height: 12),
                  Text("Dida Attallah Elfasdi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple), textAlign: TextAlign.center),
                  Text("123230145", style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            )
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))],
      ),
    );
  }

  // ==========================================
  // 4. MUNCULIN FORUM KRITIK & SARAN
  // ==========================================
  static void _showFeedbackDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const FeedbackForumWidget());
  }
}

// ==========================================
// WIDGET FORUM KRITIK & SARAN INTERAKTIF
// ==========================================
class FeedbackForumWidget extends StatefulWidget {
  const FeedbackForumWidget({super.key});

  @override
  State<FeedbackForumWidget> createState() => _FeedbackForumWidgetState();
}

class _FeedbackForumWidgetState extends State<FeedbackForumWidget> {
  List<dynamic> _feedbacks = [];
  bool _isLoading = true;
  
  final TextEditingController _feedbackCtrl = TextEditingController();
  double _selectedRating = 5.0; // Default rating
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchFeedbacks();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user_data');
    if (userStr != null) {
      setState(() => _currentUser = jsonDecode(userStr));
    }
  }

  Future<void> _fetchFeedbacks() async {
    try {
      final res = await http.get(Uri.parse("${AuthService.baseUrl}/feedbacks")).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        setState(() => _feedbacks = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("Gagal menarik data feedback: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackCtrl.text.trim().isEmpty || _currentUser == null) return;
    
    final currentText = _feedbackCtrl.text;
    final currentRating = _selectedRating; 
    
    _feedbackCtrl.clear();
    FocusScope.of(context).unfocus(); 

    setState(() => _isLoading = true); 

    try {
      final res = await http.post(
        Uri.parse("${AuthService.baseUrl}/feedbacks"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": _currentUser!['id'],
          "username": _currentUser!['full_name'],
          "feedback": currentText,
          "rating": currentRating 
        })
      ).timeout(const Duration(seconds: 5));
      
      if (res.statusCode == 200) {
        _fetchFeedbacks(); 
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan (Status: ${res.statusCode})')));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error jaringan: Server Node.js mati')));
      setState(() => _isLoading = false);
    }
  }

  // LOGIKA PENGHITUNGAN RATING SAAT JARIMU MENGGESER/MENGKLIK BINTANG
  void _updateRating(double dx) {
    // Lebar 1 bintang adalah 32px + 4px margin = 36px
    double widthPerStar = 36.0; 
    double val = dx / widthPerStar;
    
    // Konversi posisi jari menjadi bintang (dibulatkan per 0.5)
    double rating = (val * 2).ceilToDouble() / 2;
    if (rating < 1.0) rating = 1.0;
    if (rating > 5.0) rating = 5.0;
    
    setState(() => _selectedRating = rating);
  }

  // WIDGET BUAT NAMPILIN BINTANG DI LIST REVIEW
  Widget _buildStarDisplay(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    List<Widget> stars = [];
    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star_rounded, color: Colors.amber, size: 16));
    }
    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half_rounded, color: Colors.amber, size: 16));
    }
    for (int i = 0; i < emptyStars; i++) {
      stars.add(const Icon(Icons.star_outline_rounded, color: Colors.amber, size: 16));
    }
    return Row(children: stars);
  }

  // WIDGET BUAT FORMAT TANGGAL MYSQL JADI CAKEP
  String _formatDate(String isoString) {
    try {
      final DateTime t = DateTime.parse(isoString).toLocal();
      final months = ["", "Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Ags", "Sep", "Okt", "Nov", "Des"];
      return "${t.day} ${months[t.month]} ${t.year}, ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} WIB";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75, 
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [Icon(LucideIcons.messageSquare, color: Colors.orange), SizedBox(width: 8), Text("Forum Review TPM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                CloseButton()
              ],
            ),
            const Divider(),
            
            // LIST REVIEW DARI DATABASE
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : _feedbacks.isEmpty
                  ? const Center(child: Text("Belum ada saran, jadilah yang pertama!", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _feedbacks.length,
                      itemBuilder: (context, index) {
                        final fb = _feedbacks[index];
                        bool isMe = _currentUser != null && fb['user_id'] == _currentUser!['id'];
                        double userRating = fb['rating'] != null ? double.parse(fb['rating'].toString()) : 5.0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: isMe ? Colors.orange.withOpacity(0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: isMe ? Colors.orange.withOpacity(0.3) : Colors.transparent)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Nama, Bintang, dan Waktu
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(fb['username'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isMe ? Colors.orange[800] : const Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis)),
                                  _buildStarDisplay(userRating),
                                ],
                              ),
                              const SizedBox(height: 2),
                              if (fb['created_at'] != null)
                                Text(_formatDate(fb['created_at']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 8),
                              
                              // Isi Pesan
                              Text(fb['feedback'], style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            
            // BAGIAN INPUT (BINTANG INTERAKTIF + TEXTFIELD)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
              child: Column(
                children: [
                  // RATING BINTANG YANG BISA DI-SLIDE ATAU DI-KLIK!
                  Row(
                    children: [
                      const Text("Rating:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(width: 8),
                      Expanded(
                        // Ini dia rahasianya: GestureDetector membungkus barisan bintang!
                        child: GestureDetector(
                          onPanUpdate: (details) => _updateRating(details.localPosition.dx),
                          onTapDown: (details) => _updateRating(details.localPosition.dx),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (index) {
                              double starValue = index + 1.0;
                              IconData icon;
                              if (_selectedRating >= starValue) {
                                icon = Icons.star_rounded;
                              } else if (_selectedRating >= starValue - 0.5) {
                                icon = Icons.star_half_rounded;
                              } else {
                                icon = Icons.star_outline_rounded;
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Icon(icon, color: Colors.amber, size: 32),
                              );
                            }),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(_selectedRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Kotak Teks
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _feedbackCtrl,
                          decoration: const InputDecoration(hintText: "Tulis saranmu di sini...", border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                          onSubmitted: (_) => _submitFeedback(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _submitFeedback,
                        child: const CircleAvatar(radius: 16, backgroundColor: Color(0xFF2C3E50), child: Icon(LucideIcons.send, color: Colors.white, size: 14)),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}