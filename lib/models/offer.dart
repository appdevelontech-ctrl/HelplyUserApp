class Offer {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? url; // Optional URL for navigation

  Offer({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.url,
  });
}