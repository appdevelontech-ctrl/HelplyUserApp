class ServiceCategory {
    String title;
    String imageUrl;

    ServiceCategory({required this.title, required this.imageUrl});

  @override
  String toString() => 'Service(title: $title, imageUrl: $imageUrl)';
}