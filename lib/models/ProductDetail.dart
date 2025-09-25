import '../models/serviceCategoryDetail.dart';

class Productdetail {
  final Servicecategorydetail servicecategorydetail;
  final List<String> features;
  final List<String> whatIsIncluded;
  final List<String> whatIsExcluded;
  final List<Map<String, List<Map<String, String>>>> specifications; // List of maps, each with a 'heading' key (String) and 'labels' key (List<Map<String, String>>)

  Productdetail({
    required this.servicecategorydetail,
    required this.features,
    required this.whatIsIncluded,
    required this.whatIsExcluded,
    required this.specifications,
  });
}