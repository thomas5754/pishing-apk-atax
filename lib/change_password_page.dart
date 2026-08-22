// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = "https://clicks-attending-valium-manufacturing.trycloudflare.com";

class ChangePasswordPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const ChangePasswordPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool isLoading = false;

  // Warna Tema (Abu-abu menyala & Background Gelap)
  final Color primaryColor = const Color(0xFFE0E0E0);
  final Color darkBgStart = const Color(0xFF02050A);
  final Color darkBgEnd = const Color(0xFF0A1020);
  final Color cardBg = const Color(0xFF0D1322).withOpacity(0.7);

  Future<void> _changePassword() async {
    final oldPass = oldPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMessage("All fields are required");
      return;
    }

    if (newPass != confirmPass) {
      _showMessage("New password doesn't match confirmation");
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/changepass"),
        body: {
          "username": widget.username,
          "oldPass": oldPass,
          "newPass": newPass,
          "key": widget.sessionKey,
        },
      );

      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        _showMessage("Password changed successfully", isSuccess: true);
      } else {
        _showMessage(data['message'] ?? "Failed to change password");
      }
    } catch (e) {
      _showMessage("Server error: $e");
    }

    setState(() => isLoading = false);
  }

  void _showMessage(String msg, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1),
        ),
        title: Text(
          isSuccess ? "✅ Success" : "⚠️ Info",
          style: TextStyle(
            color: isSuccess ? Colors.greenAccent : primaryColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white70, fontFamily: 'ShareTechMono'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CLOSE", style: TextStyle(color: primaryColor)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBgStart,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Change Password",
          style: TextStyle(
            color: primaryColor,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBgStart, darkBgEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Gambar Banner 16:9
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/bokep.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),

                // 2. Kotak Form Security Settings
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Security Settings",
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildField("Old Password", "Enter Old Password", oldPassCtrl, obscure: true),
                      const SizedBox(height: 20),
                      
                      _buildField("New Password", "Enter New Password", newPassCtrl, obscure: true),
                      const SizedBox(height: 20),
                      
                      _buildField("Confirm Password", "Enter Confirm Password...", confirmPassCtrl, obscure: true),
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // Hollow button
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: primaryColor.withOpacity(0.5), 
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 24, 
                                  height: 24, 
                                  child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5),
                                )
                              : Text(
                                  "CHANGE PASSWORD",
                                  style: TextStyle(
                                    color: primaryColor,
                                    letterSpacing: 1.5,
                                    fontFamily: 'Orbitron',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fungsi helper untuk merender input box sesuai dengan screenshot
  Widget _buildField(String label, String hint, TextEditingController controller, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: primaryColor.withOpacity(0.8),
            fontFamily: 'ShareTechMono',
            fontSize: 13,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(color: primaryColor, fontFamily: 'ShareTechMono'),
          cursorColor: primaryColor,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: primaryColor.withOpacity(0.3), 
              fontFamily: 'ShareTechMono',
              fontSize: 14,
            ),
            suffixIcon: Icon(
              Icons.lock_outline, 
              color: primaryColor.withOpacity(0.5), 
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFF03050C), // Warna isi form sangat gelap
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor.withOpacity(0.8), width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}