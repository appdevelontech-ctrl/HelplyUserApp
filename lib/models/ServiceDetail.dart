import '../models/Service.dart';

class ServiceDetail {
  final Service service;
  final List<String> features;
  final List<String> whatIsIncluded;
  final List<String> whatIsExcluded;
  final List<Map<String, List<Map<String, String>>>> specifications; // List of maps, each with a 'heading' key (String) and 'labels' key (List<Map<String, String>>)

  ServiceDetail({
    required this.service,
    required this.features,
    required this.whatIsIncluded,
    required this.whatIsExcluded,
    required this.specifications,
  });
}