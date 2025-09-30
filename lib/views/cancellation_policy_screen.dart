import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

class CancellationPolicyScreen extends StatefulWidget {
  const CancellationPolicyScreen({super.key});

  @override
  State<CancellationPolicyScreen> createState() => _CancellationPolicyScreenState();
}

class _CancellationPolicyScreenState extends State<CancellationPolicyScreen> {
  bool _isLoading = true;
  String? _title;
  String? _description;
  String? _errorMessage;

  // Base URL for the API
  final String baseUrl = 'https://backend-olxs.onrender.com';

  @override
  void initState() {
    super.initState();
    _fetchCancellationPolicy();
  }

  // Method to fetch Cancellation Policy
  Future<void> _fetchCancellationPolicy() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/get-page/689c763e7fa4afbd4d286453'),
      );

      print('📩 Fetching Cancellation Policy');
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
          throw Exception('Failed to load cancellation policy: ${jsonData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load cancellation policy (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error fetching cancellation policy: $e');
      setState(() {
        _errorMessage = 'Error fetching cancellation policy: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title ?? 'Cancellation Policy',
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
                  _fetchCancellationPolicy();
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
                'ol': Style(
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
                // Handle link taps (e.g., open email or phone links)
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