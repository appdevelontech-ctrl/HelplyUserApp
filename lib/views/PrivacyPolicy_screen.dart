import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _isLoading = true;
  String? _title;
  String? _description;
  String? _errorMessage;

  // Base URL for the API
  final String baseUrl = 'https://backend-olxs.onrender.com'; // Replace with your actual base URL

  @override
  void initState() {
    super.initState();
    _fetchPrivacyPolicy();
  }

  // Method to fetch Privacy Policy
  Future<void> _fetchPrivacyPolicy() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/get-page/689c77097fa4afbd4d286457'),
      );

      print('📩 Fetching Privacy Policy');
      print('📩 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['Mpage'] != null) {
          setState(() {
            _title = jsonData['Mpage']['title'];
            _description = jsonData['Mpage']['description'];
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load privacy policy: ${jsonData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load privacy policy (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error fetching privacy policy: $e');
      setState(() {
        _errorMessage = 'Error fetching privacy policy: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title ?? 'Privacy Policy',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchPrivacyPolicy();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_title != null)

            Html(
              data: _description ?? '',
              style: {
                'body': Style(
                  fontSize: FontSize(16),
                  color: Colors.black87,
                ),
                'h1': Style(
                  fontSize: FontSize(28),
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                'h2': Style(
                  fontSize: FontSize(22),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                'h3': Style(
                  fontSize: FontSize(18),
                  fontWeight: FontWeight.w600,
                ),
                'p': Style(
                  fontSize: FontSize(16),
                  lineHeight: LineHeight(1.5),
                ),
                'ul': Style(
                  margin: Margins(left: Margin(16)),
                ),
                'li': Style(
                  fontSize: FontSize(16),
                  margin: Margins(bottom: Margin(8)),
                ),
                'a': Style(
                  color: Colors.blueAccent,
                  textDecoration: TextDecoration.none,
                ),
              },
              onLinkTap: (url, _, __) {
                // Handle link taps if needed (e.g., open URLs)
                if (url != null) {
                  // Example: Launch URL using url_launcher
                  // launchUrl(Uri.parse(url));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}