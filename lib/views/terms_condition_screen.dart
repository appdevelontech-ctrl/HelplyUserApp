import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  bool _isLoading = true;
  String? _title;
  String? _description;
  String? _errorMessage;

  // Base URL for the API
  final String baseUrl = 'https://backend-olxs.onrender.com'; // Replace with your actual base URL

  @override
  void initState() {
    super.initState();
    _fetchTermsConditions();
  }

  // Method to fetch Terms and Conditions
  Future<void> _fetchTermsConditions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/get-page/689c75687fa4afbd4d28644f'),
      );

      print('📩 Fetching Terms and Conditions');
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
          throw Exception('Failed to load terms and conditions: ${jsonData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load terms and conditions (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error fetching terms and conditions: $e');
      setState(() {
        _errorMessage = 'Error fetching terms and conditions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title ?? 'Terms and Conditions',
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
                  _fetchTermsConditions();
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
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _title!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
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