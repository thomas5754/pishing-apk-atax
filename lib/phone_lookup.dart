// phone_lookup_page.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class PhoneLookupPage extends StatefulWidget {
  final String sessionKey;

  const PhoneLookupPage({super.key, required this.sessionKey});

  @override
  State<PhoneLookupPage> createState() => _PhoneLookupPageState();
}

class _PhoneLookupPageState extends State<PhoneLookupPage> {
  final TextEditingController _phoneController = TextEditingController();
  Map<String, String>? _phoneData;
  bool _isLoading = false;

  // --- Theme Colors (Glowing Silver) ---
  static const Color primaryColor = Color(0xFFE0E0E0); // Silver/Abu-abu Menyala
  static const Color backgroundColor = Color(0xFF050505); // Hitam Pekat
  static const Color cardColor = Color(0xFF1A1A1A); // Abu-abu Gelap
  static const Color highlightColor = Color(0xFFFFFFFF); // Putih untuk highlight

  // List of user agents similar to the JavaScript code
  final List<String> _userAgents = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
  ];

  // Function to get a random user agent
  String _getRandomUA() {
    final random = Random();
    return _userAgents[random.nextInt(_userAgents.length)];
  }

  Future<void> _lookupPhone() async {
    if (_phoneController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _phoneData = null;
    });

    try {
      final phoneNumber = _phoneController.text.trim();
      final url = Uri.parse('https://free-lookup.net/$phoneNumber');

      final response = await http.get(
        url,
        headers: {
          "User-Agent": _getRandomUA(),
          "Accept-Language": "en-US,en;q=0.9"
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Parse HTML
        final document = html_parser.parse(response.body);

        // Extract information similar to the JavaScript code
        final items = document.querySelectorAll('.report-summary__list div');

        Map<String, String> info = {};

        for (int i = 0; i < items.length; i += 2) {
          if (i + 1 < items.length) {
            final key = items[i].text.trim();
            final value = items[i + 1].text.trim();
            info[key] = value.isNotEmpty ? value : 'Not found';
          }
        }

        setState(() {
          _phoneData = info;
        });
      } else {
        _showSnackBar('Failed to connect to phone lookup service', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? Colors.red.shade900 : cardColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
            'Phone Lookup', 
            style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: primaryColor, blurRadius: 5)]
            )
        ),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.1))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                      'Enter Phone Number',
                      style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    style: const TextStyle(color: primaryColor),
                    cursorColor: primaryColor,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number with country code',
                      hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor.withOpacity(0.3))
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: primaryColor)
                      ),
                      filled: true,
                      fillColor: backgroundColor,
                      prefixIcon: Icon(Icons.phone, color: primaryColor.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _lookupPhone,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 5,
                        shadowColor: primaryColor.withOpacity(0.3)
                    ),
                    child: _isLoading
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2
                        )
                    )
                        : const Text('Lookup Phone', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_phoneData != null) _buildPhoneResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.1))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Phone Information',
              style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(color: primaryColor, blurRadius: 2)])
          ),
          const SizedBox(height: 16),
          if (_phoneData!.isNotEmpty)
            ..._phoneData!.entries.where((entry) => entry.value != 'Not found').map((entry) {
              return _buildInfoRow(entry.key, entry.value);
            }).toList()
          else
            const Text(
              'No information found for this phone number',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(
                  '$label:',
                  style: TextStyle(
                      color: primaryColor.withOpacity(0.6),
                      fontSize: 14
                  )
              )
          ),
          Expanded(
              child: Text(
                  value,
                  style: const TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500
                  )
              )
          ),
        ],
      ),
    );
  }
}