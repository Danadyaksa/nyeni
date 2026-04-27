import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GyroGameScreen extends StatefulWidget {
  const GyroGameScreen({super.key});

  @override
  State<GyroGameScreen> createState() => _GyroGameScreenState();
}

class _GyroGameScreenState extends State<GyroGameScreen> {
  final _supabase = Supabase.instance.client;

  int? _selectedLevel;
  int _userMaxLevel = 1;
  bool _isLoading = true;

  // Variabel Fisika & Game Loop
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  Timer? _gameLoop;
  Timer? _countdownTimer; // Tambahan Timer Mundur
  
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
  
  int _timeLeft = 0; // Sisa waktu

  // Batas waktu per level (dalam detik)
  final Map<int, int> _timeLimits = {
    1: 15,
    2: 20,
    3: 25,
    4: 30,
    5: 35,
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

  Future<void> _loadUserProgress() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase.from('users').select('completed_levels').eq('id', user.id).single();
        setState(() {
          _userMaxLevel = data['completed_levels'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  final Map<int, List<String>> _mazes = {
    1: [
      "WWWWWWWWWW",
      "WS.......W",
      "WWWWWWWW.W",
      "W........W",
      "W.WWWWWWWW",
      "W........W",
      "WWWWWWWW.W",
      "W........W",
      "W.WWWWWWWW",
      "W........W",
      "WWWWWWWW.W",
      "W........W",
      "W.WWWWWWWW",
      "W.......FW",
      "WWWWWWWWWW",
    ],
    2: [
      "WWWWWWWWWW",
      "WS..W....W",
      "W.W.W.WW.W",
      "W.W....W.W",
      "W.WWWW.W.W",
      "W....W.W.W",
      "WWWW.W.W.W",
      "W....W...W",
      "W.WWWWWW.W",
      "WH.......W",
      "W.WWWWWW.W",
      "W.W....W.W",
      "W.W.WW.W.W",
      "W.W.WH...F",
      "WWWWWWWWWW",
    ],
    3: [
      "WWWWWWWWWW",
      "WS.......W",
      "W.WWWWWW.W",
      "W.WH...W.W",
      "W.W.WW.W.W",
      "W.W..W.W.W",
      "W.WW.W.W.W",
      "W....W.W.W",
      "WWWWWW.W.W",
      "WH.....W.W",
      "W.WWWWWW.W",
      "W.W.H..W.W",
      "W.W.WWWW.W",
      "W........F",
      "WWWWWWWWWW",
    ],
    4: [
      "WWWWWWWWWW",
      "WS.W.H...W",
      "WW.W.WWW.W",
      "W..W.W...W",
      "W.WW.W.WHW",
      "W....W.W.W",
      "WWWW.W.W.W",
      "WH...W...W",
      "W.WWWWWWWW",
      "W........W",
      "W.WWWWWW.W",
      "W.WH...W.W",
      "W.WWWW.W.W",
      "W......WFW",
      "WWWWWWWWWW",
    ],
    5: [
      "WWWWWWWWWW",
      "WS.W...H.W",
      "WH.W.WWW.W",
      "W..W...W.W",
      "W.WWWW.W.W",
      "W.H..W.W.W",
      "WWWW.W.W.W",
      "WH...W...W",
      "W.WWWWWWWW",
      "W.H......W",
      "WWWWWWWW.W",
      "W.H....W.W",
      "W.WWWW.W.W",
      "W......WFW",
      "WWWWWWWWWW",
    ]
  };

  void _startLevel(int level, double screenWidth) {
    _currentMaze = _mazes[level]!;
    _cellSize = screenWidth / 10; 
    _ballRadius = _cellSize * 0.35; 
    _timeLeft = _timeLimits[level] ?? 20; // Set waktu awal

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

    // Mulai Timer Mundur
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _loseGame(isTimeout: true); // Kalah karena waktu habis
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
          _loseGame(isTimeout: false); // Kalah karena masuk lubang
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

          double distanceX = x - closestX;
          double distanceY = y - closestY;

          if ((distanceX * distanceX + distanceY * distanceY) < (_ballRadius * _ballRadius)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _winGame() async {
    _isPlaying = false;
    _accelSubscription?.cancel();
    _gameLoop?.cancel();
    _countdownTimer?.cancel(); // Stop timer
    setState(() => _isProcessingResult = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final res = await _supabase.from('users').select('total_xp, level, completed_levels').eq('id', user.id).single();
        int newXp = (res['total_xp'] ?? 0) + 200;
        int newLevel = (newXp ~/ 100) + 1;
        
        int updatedCompletedLevel = _userMaxLevel;
        if (_selectedLevel == _userMaxLevel) {
          updatedCompletedLevel = _userMaxLevel + 1;
        }

        await _supabase.from('users').update({
          'total_xp': newXp,
          'level': newLevel,
          'completed_levels': updatedCompletedLevel
        }).eq('id', user.id);

        setState(() { _userMaxLevel = updatedCompletedLevel; });
      }
    } catch (e) {
      debugPrint('Update Error: $e');
    }

    if (mounted) {
      _showResultDialog(true, false);
    }
  }

  void _loseGame({required bool isTimeout}) {
    _isPlaying = false;
    _accelSubscription?.cancel();
    _gameLoop?.cancel();
    _countdownTimer?.cancel(); // Stop timer
    _showResultDialog(false, isTimeout);
  }

  void _showResultDialog(bool isWin, bool isTimeout) {
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
            const SizedBox(height: 16),
            Text(isWin 
              ? "Luar biasa! Level berikutnya terbuka dan kamu mendapat +200 XP." 
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
          // ===================================
          // UI TIMER BARU
          // ===================================
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
          // ===================================

          Center(
            child: Container(
              width: boardWidth,
              height: boardHeight,
              decoration: BoxDecoration(
                color: Colors.brown[50], 
                border: Border.all(color: const Color(0xFF2C3E50), width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 10))],
              ),
              child: Stack(
                children: [
                  for (int r = 0; r < 15; r++)
                    for (int c = 0; c < 10; c++)
                      if (_currentMaze[r][c] == 'W')
                        Positioned(
                          left: c * _cellSize,
                          top: r * _cellSize,
                          child: Container(
                            width: _cellSize,
                            height: _cellSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3E50), 
                              border: Border.all(color: Colors.black12, width: 1),
                            ),
                          ),
                        )
                      else if (_currentMaze[r][c] == 'F')
                        Positioned(
                          left: c * _cellSize,
                          top: r * _cellSize,
                          child: Center(
                            child: Container(
                              width: _cellSize * 0.7,
                              height: _cellSize * 0.7,
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 5, spreadRadius: 1, offset: Offset(0, 2) )]),
                            ),
                          ),
                        )
                      else if (_currentMaze[r][c] == 'H')
                        Positioned(
                          left: c * _cellSize,
                          top: r * _cellSize,
                          child: Center(
                            child: Container(
                              width: _cellSize * 0.7,
                              height: _cellSize * 0.7,
                              decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                            ),
                          ),
                        ),

                  Positioned(
                    left: _ballX - _ballRadius,
                    top: _ballY - _ballRadius,
                    child: Container(
                      width: _ballRadius * 2,
                      height: _ballRadius * 2,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(2, 2))],
                        gradient: const RadialGradient(colors: [Colors.red, Colors.redAccent], center: Alignment(-0.3, -0.3)),
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
        ],
      ),
    );
  }
}