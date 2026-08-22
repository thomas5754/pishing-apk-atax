import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

// Import ini berisi DashboardPage
import 'loader_page.dart';

class SplashPage extends StatefulWidget {
  // Menerima data user dari rute (arguments)
  final Map<String, dynamic> data;

  const SplashPage({super.key, required this.data});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    // Menggunakan video yang sama dengan login atau video khusus splash
    _controller = VideoPlayerController.asset('assets/videos/load.mp4')
      ..initialize().then((_) {
        // Sembunyikan status bar untuk kesan cinematic
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        
        setState(() {
          _isInitialized = true;
        });
        
        _controller.play();
        _controller.setVolume(1.0); // Full suara sesuai permintaan sebelumnya
      });

    // Listener untuk mendeteksi video selesai
    _controller.addListener(() {
      if (_controller.value.isInitialized && 
          _controller.value.position >= _controller.value.duration) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    // 1. Matikan video dan lepaskan listener agar tidak memory leak
    _controller.pause();
    
    // 2. Kembalikan UI Mode ke normal
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 3. Pindah ke DashboardPage (di loader_page.dart)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            username: widget.data['username'] ?? '',
            password: widget.data['password'] ?? '',
            role: widget.data['role'] ?? 'user',
            expiredDate: widget.data['expiredDate'] ?? '-',
            sessionKey: widget.data['key'] ?? '', 
            listBug: List<Map<String, dynamic>>.from(widget.data['listBug'] ?? []),
            listPayload: List<Map<String, dynamic>>.from(widget.data['listPayload'] ?? []),
            listDDoS: List<Map<String, dynamic>>.from(widget.data['listDDoS'] ?? []),
            news: List<Map<String, dynamic>>.from(widget.data['news'] ?? []),
          ),
        ), 
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. VIDEO LAYER
          if (_isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white24)),

          // 2. OVERLAY TEXT (Aesthetic Cyberpunk)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Parapam",
                  style: TextStyle(
                    fontFamily: 'Orbitron', // Mengikuti font login Anda
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        blurRadius: 15.0,
                        color: Colors.white.withOpacity(0.5),
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Spesial Edition By @mizukisnji",
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 5.0,
                  ),
                ),
              ],
            ),
          ),

          // 3. SKIP BUTTON
          Positioned(
            top: 50,
            right: 25,
            child: GestureDetector(
              onTap: _navigateToDashboard,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "SKIP",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
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