// tools_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // Ditambahkan untuk VideoPlayer Background
import 'chat_ai_page.dart';
import 'nik_check_page.dart';
import 'phone_lookup.dart'; // Tambahkan import untuk PhoneLookupPage
import 'subdomain_finder_page.dart';
import 'anime.dart';

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerAnimation;
  late List<Animation<double>> _itemAnimations;

  // --- NEW: Controller untuk Video Background ---
  late VideoPlayerController _videoController;

  // Definisi Warna Tema Baru (Glowing Grey/Silver) -> Disimpan untuk referensi lama
  static const Color primaryColor = Color(0xFFE0E0E0); // Abu-abu menyala (Silver)

  @override
  void initState() {
    super.initState();
    
    // --- NEW: Inisialisasi Video Background ---
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0.0); // Mute video background
        _videoController.play();
        setState(() {}); // Refresh UI saat video siap
      });

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _itemAnimations = List.generate(
      5, // Perbarui menjadi 5 karena kita menambahkan tool baru
          (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _listController,
          curve: Interval(
            index * 0.1,
            0.5 + (index * 0.1),
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );

    _headerController.forward();
    _listController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    _videoController.dispose(); // --- NEW: Hancurkan controller video ---
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /* --- KODE LAMA BACKGROUND SAYA KOMENTARI ---
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _headerController,
              builder: (context, child) {
                return Opacity(
                  opacity: _headerAnimation.value * 0.05,
                  child: CustomPaint(
                    painter: GridPatternPainter(),
                  ),
                );
              },
            ),
          ),
          ------------------------------------------ */

          // --- NEW: Video Background ---
          SizedBox.expand(
            child: _videoController.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(color: Colors.black), // Hitam saat loading
          ),
          
          // Layer gelap semi-transparan agar grid menu tetap terbaca jelas
          Container(
            color: Colors.black.withOpacity(0.5), 
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildAnimatedHeader(), // --- KODE LAMA HEADER SAYA KOMENTARI ---
                _buildNewHeader(), // --- NEW HEADER ---
                const SizedBox(height: 10),
                // Expanded(child: _buildToolsList()), // --- KODE LAMA LIST SAYA KOMENTARI ---
                Expanded(child: _buildNewGridList()), // --- NEW GRID LIST ---
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW HEADER BERJALAN (MARQUEE) ---
  Widget _buildNewHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TOOLS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: "Orbitron", 
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          // Teks berjalan (Slide Out / Marquee)
          SizedBox(
            height: 20,
            child: MarqueeText(
              text: "tools available utilities",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontFamily: "ShareTechMono",
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW GRID LIST SESUAI FOTO ---
  Widget _buildNewGridList() {
    final newTools = [
      {'icon': Icons.article_outlined, 'label': 'Chat AI', 'description': 'AI Assistant'},
      {'icon': Icons.badge_outlined, 'label': 'NIK Check', 'description': 'ID Validator'},
      {'icon': Icons.phone_android_rounded, 'label': 'Phone Lookup', 'description': 'Number Info'},
      {'icon': Icons.dns_outlined, 'label': 'Subdomain', 'description': 'Domain Finder'},
      {'icon': Icons.movie_creation_outlined, 'label': 'Anime', 'description': 'Streaming'},
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95, // Rasio agar proporsional mirip foto
      ),
      itemCount: newTools.length,
      itemBuilder: (context, index) {
        final tool = newTools[index];
        return _buildAnimatedToolItem(
          icon: tool['icon'] as IconData,
          label: tool['label'] as String,
          description: tool['description'] as String,
          animation: _itemAnimations[index],
          onTap: () => _navigateToTool(tool['label'] as String),
        );
      },
    );
  }

  // --- KODE LAMA HEADER & LIST SAYA KOMENTARI TAPI TIDAK DIHAPUS ---
  /*
  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _headerAnimation.value) * 30),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
                border: Border.all(
                  color: primaryColor.withOpacity(0.3), // Silver opacity
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15), // Silver opacity
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.apps, color: primaryColor, size: 24), // Silver
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Digital Tools",
                        style: TextStyle(
                          color: primaryColor, // Silver
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: primaryColor,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a tool to begin",
                    style: TextStyle(
                      color: primaryColor.withOpacity(0.7), // Silver opacity
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolsList() {
    final tools = [
      {'icon': Icons.chat, 'label': 'Chat AI', 'description': 'AI-powered conversation assistant'},
      {'icon': Icons.badge, 'label': 'NIK Check', 'description': 'Validate Indonesian identity numbers'},
      {'icon': Icons.phone, 'label': 'Phone Lookup', 'description': 'Find information about phone numbers'},
      {'icon': Icons.language, 'label': 'Subdomain Finder', 'description': 'Discover subdomains of any domain'},
      {'icon': Icons.movie_filter_outlined, 'label': 'Anime', 'description': 'Tempat Nya Para Wibu Marathon Anime'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildAnimatedToolItem(
          icon: tool['icon'] as IconData,
          label: tool['label'] as String,
          description: tool['description'] as String,
          animation: _itemAnimations[index],
          onTap: () => _navigateToTool(tool['label'] as String),
        );
      },
    );
  }
  */

  void _navigateToTool(String toolName) {
    Widget page;
    switch (toolName) {
      case 'Chat AI':
        page = ChatAIPage(sessionKey: widget.sessionKey);
        break;
      case 'NIK Check':
        page = NIKCheckPage(sessionKey: widget.sessionKey);
        break;
      case 'Phone Lookup':
        page = PhoneLookupPage(sessionKey: widget.sessionKey);
        break;
      case 'Anime':
        page = HomeAnimePage();
        break;
      case 'Subdomain Finder':
      case 'Subdomain': // Ditambahkan mapping baru karena teks label dipersingkat
        page = SubdomainFinderPage(sessionKey: widget.sessionKey);
        break;
      default:
        return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // --- Ini dimodifikasi padding-nya sedikit agar sesuai bentuk Grid ---
  Widget _buildAnimatedToolItem({
    required IconData icon,
    required String label,
    required String description,
    required Animation<double> animation,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Animasi dari bawah (opsional, disesuaikan)
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 50),
          child: Opacity(
            opacity: animation.value,
            child: _InteractiveToolItem(icon: icon, label: label, description: description, onTap: onTap),
          ),
        );
      },
    );
  }
}

// --- NEW MARQUEE TEXT WIDGET UNTUK TEKS BERJALAN ---
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  
  const MarqueeText({super.key, required this.text, required this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Durasi animasi menentukan kecepatan teks berjalan
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Menghitung pergerakan dari kanan ke kiri
              final width = MediaQuery.of(context).size.width;
              final dx = width - (_controller.value * (width + 300)); 
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
        );
      },
    );
  }
}

class _InteractiveToolItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _InteractiveToolItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  State<_InteractiveToolItem> createState() => _InteractiveToolItemState();
}

class _InteractiveToolItemState extends State<_InteractiveToolItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Definisi Warna (Silver) -> Disimpan untuk referensi lama
  static const Color primaryColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            // --- NEW: KOTAK CARD UNTUK GRID (Berdasarkan Screenshot) ---
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1512).withOpacity(0.9), // Warna gelap kehijauan sesuai foto
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPressed
                      ? const Color(0xFF25D366).withOpacity(0.6) // Hijau menyala saat ditekan
                      : Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: const Color(0xFF25D366).withOpacity(0.15),
                          blurRadius: 15,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ikon Tool
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2F23), // Warna background kotak ikon
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: const Color(0xFF25D366), size: 24), // Hijau tema
                      ),
                      // Ikon panah pojok kanan
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white30, size: 20),
                    ],
                  ),
                  const Spacer(),
                  // Teks Judul
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: "ShareTechMono",
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Teks Subjudul
                  Text(
                    widget.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontFamily: "ShareTechMono",
                    ),
                  ),
                ],
              ),
            ),
            
            /* --- KODE LAMA TAMPILAN CARD SAYA KOMENTARI ---
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPressed
                      ? primaryColor.withOpacity(0.6) // Silver lebih terang saat ditekan
                      : primaryColor.withOpacity(0.2), // Silver normal
                  width: 1,
                ),
                boxShadow: _isPressed
                    ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1), // Silver opacity
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Icon(widget.icon, color: primaryColor, size: 24), // Silver
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: primaryColor, // Silver
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: primaryColor,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: TextStyle(
                              color: primaryColor.withOpacity(0.6), // Silver opacity
                              fontSize: 12
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: primaryColor.withOpacity(0.4), // Silver opacity
                    size: 16,
                  ),
                ],
              ),
            ),
            ------------------------------------------------ */
          );
        },
      ),
    );
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0) // Silver/Abu-abu menyala
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    const gridSize = 30.0;
    for (double x = 0; x < size.width; x += gridSize) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += gridSize) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}