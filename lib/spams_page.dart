import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

class ReportWaPage extends StatefulWidget {
  // 1. TERIMA DATA DARI HALAMAN SEBELUMNYA
  final String sessionKey;
  final String username;
  final String role;

  const ReportWaPage({
    super.key, 
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<ReportWaPage> createState() => _ReportWaPageState();
}

class _ReportWaPageState extends State<ReportWaPage> {
  // --- CONFIG ---
  // GANTI IP INI SESUAI IP SERVER NODE.JS LU
  static const String baseUrl = "http://blue-public.bluesrv.web.id:3392"; 

  // --- STYLE VARIABLES (Pink Aesthetic) ---
  final Color _primaryPink = const Color(0xFFFF4081);
  final Color _softPink = const Color(0xFFFF80AB);
  final Color _bgTheme = const Color(0xFF120509);
  final Color _cardTheme = const Color(0xFF1F0A10);
  final Color _textWhite = Colors.white;
  final Color _textGrey = const Color(0xFFB0A0A6);

  // --- CONTROLLERS ---
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();

  // --- STATE ---
  bool _isAttacking = false;
  bool _isLoadingSenders = false;
  List<dynamic> _availableSenders = []; 
  List<String> _logs = [];
  int _successCount = 0;
  int _failCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchRealSenders(); // Auto tarik data pas dibuka
  }

  @override
  void dispose() {
    _targetController.dispose();
    _amountController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  // 2. TARIK DATA SENDER PAKE sessionKey DARI WIDGET
  Future<void> _fetchRealSenders() async {
    setState(() => _isLoadingSenders = true);
    _addLog("[SYSTEM] Authenticating as ${widget.username}...");
    
    try {
      // Pake widget.sessionKey disini
      final uri = Uri.parse("$baseUrl/api/whatsapp/mySender?key=${widget.sessionKey}");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          final connections = data['connections'];
          List<dynamic> loaded = [];
          
          // Gabungin Private & Global Senders
          if (connections['private'] != null) loaded.addAll(connections['private']);
          if (connections['global'] != null) loaded.addAll(connections['global']);

          setState(() {
            _availableSenders = loaded;
          });
          _addLog("[ACCESS GRANTED] ${loaded.length} Agents Loaded.");
        } else {
          _addLog("[ERROR] Session Expired / Invalid Key.");
        }
      } else {
        _addLog("[ERROR] Server Offline (Status: ${response.statusCode})");
      }
    } catch (e) {
      _addLog("[FATAL] Connection Failed: $e");
    } finally {
      setState(() => _isLoadingSenders = false);
    }
  }

  // 3. EKSEKUSI REAL (MASS REPORT LOOP)
  Future<void> _executeProtocol() async {
    if (_availableSenders.isEmpty) {
      _showSnack("No active senders! Fetch data first.", Colors.red);
      return;
    }
    if (_targetController.text.isEmpty) {
      _showSnack("Target is required!", Colors.red);
      return;
    }

    // Ambil jumlah report, default 10 kalo kosong
    int totalAmount = int.tryParse(_amountController.text) ?? 10;

    setState(() {
      _isAttacking = true;
      _successCount = 0;
      _failCount = 0;
      _logs.add("[SYSTEM] Initializing Attack Protocol...");
      _logs.add("[TARGET] ${_targetController.text}");
      _logs.add("[AMOUNT] $totalAmount packets");
    });

    // LOGIC LOOPING REPORT
    for (int i = 0; i < totalAmount; i++) {
      if (!_isAttacking) break; // Tombol Stop ditekan

      // Pilih sender secara bergantian (Round Robin)
      var sender = _availableSenders[i % _availableSenders.length];
      String senderNum = sender['owner'] ?? 'Unknown';

      try {
        // Tembak ke Backend endpoint execute
        final response = await http.post(
          Uri.parse("$baseUrl/api/whatsapp/execute"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "key": widget.sessionKey, // PASS KEY DISINI
            "target": _targetController.text,
            "sender_number": senderNum,
            "amount": 1 
          }),
        );

        if (response.statusCode == 200) {
          setState(() => _successCount++);
          _addLog("[AGENT $senderNum] 🚀 PACKET ${i+1} SENT");
        } else {
          setState(() => _failCount++);
          _addLog("[AGENT $senderNum] ❌ FAILED");
        }
      } catch (e) {
        setState(() => _failCount++);
        _addLog("[AGENT $senderNum] 💀 ERROR");
      }

      // Delay dikit biar gak crash UI
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      _isAttacking = false;
      _logs.add("[SYSTEM] Mission Ended. Success: $_successCount, Fail: $_failCount");
    });
  }

  void _addLog(String log) {
    if (!mounted) return;
    setState(() {
      _logs.add(log);
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTheme,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _cardTheme.withOpacity(0.5), shape: BoxShape.circle),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: _primaryPink, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text("EXECUTION PANEL", style: TextStyle(color: _textWhite, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _primaryPink),
            onPressed: _fetchRealSenders,
          )
        ],
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: _bgTheme.withOpacity(0.5)),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [_primaryPink.withOpacity(0.15), _bgTheme],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // 1. INFO CARD USER
                _buildUserCard(),
                const SizedBox(height: 20),
                
                // 2. INPUTS
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildPinkTextField(
                        controller: _targetController,
                        label: "Target (e.g. 628xx)",
                        icon: Icons.gps_fixed,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: _buildPinkTextField(
                        controller: _amountController,
                        label: "Amount",
                        icon: Icons.confirmation_number,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. TOMBOL EKSEKUSI
                _buildActionButton(),
                const SizedBox(height: 20),

                // 4. TERMINAL LOGS
                Expanded(child: _buildTerminalLogs()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardTheme,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryPink.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: _primaryPink.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _primaryPink.withOpacity(0.2),
                child: Icon(FontAwesomeIcons.userAstronaut, color: _primaryPink, size: 20),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.username.toUpperCase(), style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                  Text("ROLE: ${widget.role.toUpperCase()}", style: TextStyle(color: _softPink, fontSize: 10, letterSpacing: 1)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _availableSenders.isNotEmpty ? Colors.green : Colors.red),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: _availableSenders.isNotEmpty ? Colors.green : Colors.red, size: 8),
                const SizedBox(width: 6),
                Text(
                  "${_availableSenders.length} AGENTS",
                  style: TextStyle(color: _textWhite, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPinkTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: _textWhite),
      cursorColor: _primaryPink,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textGrey),
        prefixIcon: Icon(icon, color: _softPink, size: 20),
        filled: true,
        fillColor: _cardTheme,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: _primaryPink.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: _primaryPink),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: _isAttacking ? () => setState(() => _isAttacking = false) : _executeProtocol,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isAttacking 
              ? [Colors.red.shade900, Colors.red] 
              : [_primaryPink, const Color(0xFFC2185B)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (_isAttacking ? Colors.red : _primaryPink).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Center(
          child: Text(
            _isAttacking ? "ABORT MISSION" : "LAUNCH ATTACK",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalLogs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _primaryPink.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("> SYSTEM LOGS", style: TextStyle(color: _primaryPink, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              if (_isAttacking) 
                const SizedBox(
                  height: 10, width: 10, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent)
                )
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          Expanded(
            child: ListView.builder(
              controller: _logScrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _logs[index],
                    style: TextStyle(
                      color: _logs[index].contains("ERROR") || _logs[index].contains("FAILED") 
                        ? Colors.redAccent 
                        : (_logs[index].contains("SUCCESS") || _logs[index].contains("SENT") ? Colors.greenAccent : _textGrey), 
                      fontSize: 11, 
                      fontFamily: 'monospace'
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}