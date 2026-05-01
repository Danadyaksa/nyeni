import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';


class GyroGameScreen extends StatefulWidget {
  const GyroGameScreen({super.key});

  @override
  State<GyroGameScreen> createState() => _GyroGameScreenState();
}

class _GyroGameScreenState extends State<GyroGameScreen> {
  int? _selectedLevel;
  int _userMaxLevel = 1;
  bool _isLoading = true;

  // Variabel Fisika & Game Loop
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  Timer? _gameLoop;
  Timer? _countdownTimer; 
  
  double _ballX = 0;
  double _ballY = 0;
  double _vx = 0;
  double _vy = 0;
  double _ax = 0;
  double _ay = 0;
  
  double _cellSize = 0;
  double _ballRadius = 0;
  List<String> _currentMaze = [];
  bool _isPlaying = false;
  bool _isProcessingResult = false;
  
  int _timeLeft = 0; 

  final Map<int, int> _timeLimits = {
    1: 15, 2: 20, 3: 25, 4: 30, 5: 35,
  };

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _gameLoop?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ==========================================
  // LOAD PROGRESS DARI MYSQL / NODE.JS
  // ==========================================
  Future<void> _loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_data');
      if (userStr != null) {
        final user = jsonDecode(userStr);
        final response = await http.get(Uri.parse("${AuthService.baseUrl}/user/${user['id']}"));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _userMaxLevel = data['completed_levels_labirin'] ?? 1;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error Load Labirin Progress: $e');
      setState(() => _isLoading = false);
    }
  }

  final Map<int, List<String>> _mazes = {
    1: [
      "WWWWWWWWWW", "WS.W.....W", "W..W.WWW.W", "W....W...W", "WWWW.W.W.W",
      "W......W.W", "W.WWWWWW.W", "W.W......W", "W.W.WWWWWW", "W.W......W",
      "W.WWWWWW.W", "W........W", "W.WWWWWWWW", "W.......FW", "WWWWWWWWWW",
    ],
    2: [
      "WWWWWWWWWW", "WS.......W", "W.WWWWWW.W", "W.W.H..W.W", "W.W.WW.W.W",
      "W.W....W.W", "W.WWWW.W.W", "W.H....W.W", "WWWWWWWW.W", "W........W",
      "W.WWWWWW.W", "W.W...HW.W", "W.W.WWWW.W", "W......WFW", "WWWWWWWWWW",
    ],
    3: [
      "WWWWWWWWWW", "WS.W.....W", "W..W.WWW.W", "W.HW.W...W", "W..W.W.W.W",
      "WW.W.W.WHW", "W..W.W...W", "W.WWWWWW.W", "W........W", "W.WWWWWW.W",
      "WHW....W.W", "W.W.WW.W.W", "W.W.WH.W.W", "W........F", "WWWWWWWWWW",
    ],
    4: [
      "WWWWWWWWWW", "WS.W.H...W", "W..W.WWW.W", "WH...W...W", "W.WWWW.W.W",
      "W.H....W.W", "WWWWWW.W.W", "W......W.W", "W.WWWWWW.W", "W.W.H..W.W",
      "W.W.WW.W.W", "W.H.W..W.H", "W.W.WWWWWW", "W........F", "WWWWWWWWWW",
    ],
    5: [
      "WWWWWWWWWW", "WS..H..H.W", "W.WWWWWW.W", "W......W.W", "WHWWWW.W.W",
      "W.H....W.W", "W.WWWWWW.W", "W.W..H.W.W", "W.W.WW.W.W", "W.H.W..W.H",
      "W.W.W.WW.W", "W.W...W..W", "W.WWWWW.WW", "WH......FW", "WWWWWWWWWW",
    ]
  };

  void _startLevel(int level, double screenWidth) {
    _currentMaze = _mazes[level]!;
    _cellSize = screenWidth / 10; 
    _ballRadius = _cellSize * 0.35; 
    _timeLeft = _timeLimits[level] ?? 20;

    for (int r = 0; r < 15; r++) {
      for (int c = 0; c < 10; c++) {
        if (_currentMaze[r][c] == 'S') {
          _ballX = c * _cellSize + (_cellSize / 2);
          _ballY = r * _cellSize + (_cellSize / 2);
        }
      }
    }

    setState(() {
      _selectedLevel = level;
      _vx = 0;
      _vy = 0;
      _isPlaying = true;
      _isProcessingResult = false;
    });

    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted && _isPlaying) {
        _ax = -event.x * 0.5; 
        _ay = event.y * 0.5;  
      }
    });

    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_isPlaying) _updatePhysics();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _loseGame(isTimeout: true); 
          }
        });
      }
    });
  }

  void _updatePhysics() {
    setState(() {
      _vx += _ax;
      _vy += _ay;
      _vx *= 0.92;
      _vy *= 0.92;

      double nextX = _ballX + _vx;
      double nextY = _ballY + _vy;

      if (!_checkWallCollision(nextX, _ballY)) {
        _ballX = nextX;
      } else {
        _vx *= -0.4; 
      }

      if (!_checkWallCollision(_ballX, nextY)) {
        _ballY = nextY;
      } else {
        _vy *= -0.4; 
      }

      int col = (_ballX / _cellSize).floor().clamp(0, 9);
      int row = (_ballY / _cellSize).floor().clamp(0, 14);
      
      String currentTile = _currentMaze[row][col];
      double centerX = col * _cellSize + (_cellSize / 2);
      double centerY = row * _cellSize + (_cellSize / 2);
      double dist = (centerX - _ballX) * (centerX - _ballX) + (centerY - _ballY) * (centerY - _ballY);
      
      if (dist < (_cellSize * 0.3) * (_cellSize * 0.3)) {
        if (currentTile == 'F') {
          _winGame();
        } else if (currentTile == 'H') {
          _loseGame(isTimeout: false);
        }
      }
    });
  }

  bool _checkWallCollision(double x, double y) {
    int startCol = ((x - _ballRadius) / _cellSize).floor().clamp(0, 9);
    int endCol = ((x + _ballRadius) / _cellSize).floor().clamp(0, 9);
    int startRow = ((y - _ballRadius) / _cellSize).floor().clamp(0, 14);
    int endRow = ((y + _ballRadius) / _cellSize).floor().clamp(0, 14);

    for (int r = startRow; r <= endRow; r++) {
      for (int c = startCol; c <= endCol; c++) {
        if (_currentMaze[r][c] == 'W') {
          double rectLeft = c * _cellSize;
          double rectRight = rectLeft + _cellSize;
          double rectTop = r * _cellSize;
          double rectBottom = rectTop + _cellSize;

          double closestX = x.clamp(rectLeft, rectRight);
          double closestY = y.clamp(rectTop, rectBottom);

          if (((x - closestX) * (x - closestX) + (y - closestY) * (y - closestY)) < (_ballRadius * _ballRadius)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // ==========================================
  // UPDATE PROGRESS KE MYSQL / NODE.JS
  // ==========================================
  void _winGame() async {
    _isPlaying = false;
    _accelSubscription?.cancel();
    _gameLoop?.cancel();
    _countdownTimer?.cancel();
    setState(() => _isProcessingResult = true);

    int currentLevel = _selectedLevel ?? 1;
    int timeTaken = (_timeLimits[currentLevel] ?? 20) - _timeLeft;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_data');
      
      if (userStr != null) {
        final user = jsonDecode(userStr);

        // 1. Simpan Rekor Waktu ke Node.js (game_scores)
        await http.post(
          Uri.parse("${AuthService.baseUrl}/game/save-score"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": user['id'],
            "username": user['full_name'] ?? 'Pemain Nyeni',
            "game_name": "Labirin Gyro",
            "level": currentLevel,
            "best_time": timeTaken
          })
        );

        // 2. Ambil total_xp terbaru dari database
        final res = await http.get(Uri.parse("${AuthService.baseUrl}/user/${user['id']}"));
        final data = jsonDecode(res.body);
        
        int currentXp = data['total_xp'] ?? 0;
        int newXp = currentXp + 100; // Reward sama 100 XP
        
        // Logika Progresif Level (Dipertahankan sesuai kodingan aslimu)
        int newLevel = 1;
        if (newXp >= 2700) newLevel = 10;
        else if (newXp >= 2200) newLevel = 9;
        else if (newXp >= 1750) newLevel = 8;
        else if (newXp >= 1350) newLevel = 7;
        else if (newXp >= 1000) newLevel = 6;
        else if (newXp >= 700) newLevel = 5;
        else if (newXp >= 450) newLevel = 4;
        else if (newXp >= 250) newLevel = 3;
        else if (newXp >= 100) newLevel = 2;
        
        int updatedCompletedLevel = _userMaxLevel;
        if (currentLevel == _userMaxLevel) {
          updatedCompletedLevel = _userMaxLevel + 1;
        }

        // 3. Update Progress ke Node.js (tabel users)
        await http.post(
          Uri.parse("${AuthService.baseUrl}/user/update-progress"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "id": user['id'],
            "total_xp": newXp,
            "level": newLevel,
            "completed_levels_trivia": data['completed_levels_trivia'] ?? 1,
            "completed_levels_labirin": updatedCompletedLevel
          })
        );

        setState(() { _userMaxLevel = updatedCompletedLevel; });
      }
    } catch (e) {
      debugPrint('Labirin Update Error: $e');
      setState(() {
        if (currentLevel == _userMaxLevel) {
          _userMaxLevel = _userMaxLevel + 1;
        }
      });
    }

    if (mounted) {
      _showResultDialog(true, false, timeTaken: timeTaken);
    }
  }

  void _loseGame({required bool isTimeout}) {
    _isPlaying = false;
    _accelSubscription?.cancel();
    _gameLoop?.cancel();
    _countdownTimer?.cancel();
    _showResultDialog(false, isTimeout);
  }

  void _showResultDialog(bool isWin, bool isTimeout, {int? timeTaken}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isWin ? LucideIcons.trophy : (isTimeout ? LucideIcons.timer : LucideIcons.skull), size: 80, color: isWin ? Colors.amber : Colors.red),
            const SizedBox(height: 24),
            Text(isWin ? "LEVEL SELESAI!" : (isTimeout ? "WAKTU HABIS!" : "KAMU TERJATUH!"), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isWin ? Colors.amber[700] : Colors.red[800])),
            
            if (isWin && timeTaken != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text("Waktu kamu: $timeTaken Detik ⏱️", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900])),
              )
            ],

            const SizedBox(height: 16),
            Text(isWin 
              ? "Luar biasa! Kamu mendapat +100 XP. Kalau kamu memecahkan rekor lamamu, datanya sudah masuk ke Leaderboard!" 
              : (isTimeout ? "Kamu terlalu lambat mencapai garis finish. Coba lagi lebih cepat!" : "Bola masuk ke lubang jebakan. Konsentrasi dan atur kemiringan HP-mu perlahan-lahan."), 
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _selectedLevel = null);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(isWin ? "Kembali ke Menu" : "Coba Lagi", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('Nyeni Labyrinth', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: _selectedLevel != null ? IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black), 
          onPressed: () {
            _isPlaying = false;
            _accelSubscription?.cancel();
            _gameLoop?.cancel();
            _countdownTimer?.cancel();
            setState(() => _selectedLevel = null);
          }
        ) : null,
      ),
      body: _selectedLevel == null ? _buildLevelGrid() : _buildMazeArea(),
    );
  }

  Widget _buildLevelGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) {
        int level = index + 1;
        bool isLocked = level > _userMaxLevel;

        return GestureDetector(
          onTap: isLocked ? () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selesaikan labirin sebelumnya dulu!"), backgroundColor: Colors.orange));
          } : () => _startLevel(level, MediaQuery.of(context).size.width - 48), 
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
                      Text("Labirin Tantangan $level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLocked ? Colors.grey : Colors.black)),
                      const SizedBox(height: 4),
                      Text(isLocked ? "Terkunci" : "Batas Waktu: ${_timeLimits[level]} Detik", style: TextStyle(fontSize: 12, color: isLocked ? Colors.red : Colors.green)),
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

  Widget _buildMazeArea() {
    double boardWidth = MediaQuery.of(context).size.width - 48; 
    double boardHeight = _cellSize * 15;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Miringkan HP-mu!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _timeLeft <= 5 ? Colors.red.withOpacity(0.1) : const Color(0xFF2C3E50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _timeLeft <= 5 ? Colors.red : const Color(0xFF2C3E50).withOpacity(0.3))
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.timer, size: 16, color: _timeLeft <= 5 ? Colors.red : const Color(0xFF2C3E50)),
                    const SizedBox(width: 6),
                    Text(
                      "00:${_timeLeft.toString().padLeft(2, '0')}", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _timeLeft <= 5 ? Colors.red : const Color(0xFF2C3E50))
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),

          Center(
            child: Container(
              width: boardWidth,
              height: boardHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED), // Warna lantai labirin sedikit lebih hangat
                border: Border.all(color: const Color(0xFF2C3E50), width: 4),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 10))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    for (int r = 0; r < 15; r++)
                      for (int c = 0; c < 10; c++)
                        if (_currentMaze[r][c] == 'W')
                          Positioned(
                            left: c * _cellSize,
                            top: r * _cellSize,
                            width: _cellSize,
                            height: _cellSize,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C3E50), 
                                borderRadius: BorderRadius.circular(4), // Dinding agak melengkung
                                border: Border.all(color: Colors.black26, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: const Offset(2, 2)
                                  )
                                ]
                              ),
                            ),
                          )
                        else if (_currentMaze[r][c] == 'F')
                          Positioned(
                            left: c * _cellSize,
                            top: r * _cellSize,
                            width: _cellSize, // Posisinya diatur pakai width agar Center() akurat
                            height: _cellSize, 
                            child: Center(
                              child: Container(
                                width: _cellSize * 0.8,
                                height: _cellSize * 0.8,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent, 
                                  shape: BoxShape.circle, 
                                  border: Border.all(color: Colors.white, width: 2),
                                  gradient: RadialGradient(
                                    colors: [Colors.white, Colors.green.shade600],
                                    center: Alignment.center,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(0.8), 
                                      blurRadius: 10, 
                                      spreadRadius: 2, 
                                      offset: const Offset(0, 0) 
                                    )
                                  ]
                                ),
                                child: Icon(LucideIcons.flag, size: _cellSize * 0.4, color: Colors.white),
                              ),
                            ),
                          )
                        else if (_currentMaze[r][c] == 'H')
                          Positioned(
                            left: c * _cellSize,
                            top: r * _cellSize,
                            width: _cellSize, 
                            height: _cellSize, 
                            child: Center(
                              child: Container(
                                width: _cellSize * 0.7,
                                height: _cellSize * 0.7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                                  gradient: const RadialGradient(
                                    colors: [Colors.black, Color(0xFF1A1A1A), Color(0xFF4A4A4A)],
                                    stops: [0.0, 0.6, 1.0], // Efek kedalaman lubang (3D shadow dalam)
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2, offset: const Offset(1, 1))
                                  ]
                                ),
                              ),
                            ),
                          ),

                    // Bola Player
                    Positioned(
                      left: _ballX - _ballRadius,
                      top: _ballY - _ballRadius,
                      child: Container(
                        width: _ballRadius * 2,
                        height: _ballRadius * 2,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4, offset: const Offset(2, 2))],
                          gradient: const RadialGradient(
                            colors: [Colors.white70, Colors.red, Colors.redAccent], 
                            stops: [0.0, 0.4, 1.0],
                            center: Alignment(-0.3, -0.3) // Efek kilapan cahaya pada bola
                          ),
                        ),
                      ),
                    ),
                    
                    if (_isProcessingResult)
                      Container(
                        color: Colors.white.withOpacity(0.8),
                        child: const Center(child: CircularProgressIndicator(color: Color(0xFF2C3E50))),
                      )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}