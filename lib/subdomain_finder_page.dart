// subdomain_finder_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class SubdomainFinderPage extends StatefulWidget {
  final String sessionKey;

  const SubdomainFinderPage({super.key, required this.sessionKey});

  @override
  State<SubdomainFinderPage> createState() => _SubdomainFinderPageState();
}

class _SubdomainFinderPageState extends State<SubdomainFinderPage> {
  final TextEditingController _domainController = TextEditingController();
  List<String> _subdomains = [];
  bool _isLoading = false;

  // --- Theme Colors (Glowing Silver) ---
  static const Color primaryColor = Color(0xFFE0E0E0); // Silver/Abu-abu Menyala
  static const Color backgroundColor = Color(0xFF050505); // Hitam Pekat
  static const Color cardColor = Color(0xFF1A1A1A); // Abu-abu Gelap

  Future<void> _findSubdomains() async {
    if (_domainController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _subdomains = [];
    });
    try {
      final response = await http.get(Uri.parse('http://hannmodzzprivate.mysrv.web.id:2893/api/tools/subdomain-finder?key=${widget.sessionKey}&domain=${_domainController.text}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            final allSubdomains = <String>{};
            for (var item in data['data']) {
              final subdomainList = item.toString().split('\n');
              for (var subdomain in subdomainList) {
                if (subdomain.isNotEmpty) {
                  allSubdomains.add(subdomain.trim());
                }
              }
            }
            _subdomains = allSubdomains.toList();
            _subdomains.sort();
          });
        } else {
          _showSnackBar('Failed to find subdomains', isError: true);
        }
      } else {
        _showSnackBar('Failed to connect to subdomain service', isError: true);
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
            'Subdomain Finder', 
            style: TextStyle(
                color: primaryColor, 
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: primaryColor, blurRadius: 5)]
            )
        ),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.3))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Enter Domain', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _domainController,
                    style: const TextStyle(color: primaryColor),
                    cursorColor: primaryColor,
                    decoration: InputDecoration(
                      hintText: 'example.com',
                      hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: primaryColor)
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _findSubdomains,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        elevation: 5,
                        shadowColor: primaryColor.withOpacity(0.5)
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
                        : const Text('Find Subdomains', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : _subdomains.isEmpty
                ? Center(child: Text('No subdomains found', style: TextStyle(color: primaryColor.withOpacity(0.5))))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _subdomains.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryColor.withOpacity(0.1))
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: primaryColor, size: 16),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_subdomains[index], style: const TextStyle(color: primaryColor))),
                      IconButton(
                        icon: const Icon(Icons.copy, color: primaryColor, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _subdomains[index]));
                          _showSnackBar('Copied to clipboard!');
                        },
                      ),
                    ],
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