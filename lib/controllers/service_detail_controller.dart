import 'package:flutter/material.dart';
import '../models/Service.dart';
import '../models/ServiceDetail.dart';

class ServiceDetailController extends ChangeNotifier {
  late ServiceDetail _serviceDetail;

  ServiceDetailController(Service service) {
    try {
      _serviceDetail = ServiceDetail(
        service: service,
        features: [
          '🚿 Quick & Efficient – Basic cleaning completed in minimal time.',
          '🧴 Hygienic Cleaning – Pot, sink, tiles, mirror, and exhaust fan covered.',
          '👩‍🔧 Trained Helper – Reliable and verified staff for safe service.',
          '💰 Affordable – Cost-effective solution for daily bathroom upkeep.',
        ],
        whatIsIncluded: [
          'Toilet seat will be cleaned. Deep',
          'Sink will be cleaned.',
          'Fixtures will be wiped.',
          'Tiles will be cleaned.',
          'Surfaces will be cleaned.',
          'All taps will be cleaned.',
        ],
        whatIsExcluded: [
          'Walls will not be wet wiped.',
          'Cabinet interiors and bucket will not be cleaned.',
          'Mug and stool will not be cleaned.',
        ],
        specifications: [
          {
            'heading': [
              {'title': 'FAQs'}, // wrapped inside a list of maps
            ],
            'labels': [
              {
                'label': '1. What does the Instant Bathroom Clean include?',
                'value': 'It covers pot, sink, tiles, mirror, and exhaust fan cleaning – all done with basic surface cleaning.'
              },
              {
                'label': '2. Is deep cleaning included?',
                'value': 'No, this service is for basic upkeep only. Deep cleaning and hard stain removal are not part of it.'
              },
              {
                'label': '3. Do I need to provide cleaning supplies?',
                'value': 'Yes, all detergents, brushes, and cleaning items must be provided by you. The helper will use your supplies.'
              },
              {
                'label': '4. How long does an intense bathroom cleaning take?',
                'value': 'It depends on the size and condition of the bathroom, but most cleanings take 1.5 to 3 hours per bathroom.'
              },
              {
                'label': '5. Can I book the same helper again?',
                'value': 'Yes, you can rebook the same helper, subject to availability.'
              },
            ],
          },
        ],

      );
    } catch (e) {
      debugPrint('Error initializing ServiceDetail: $e');
      // Fallback to a default ServiceDetail if initialization fails
      _serviceDetail = ServiceDetail(
        service: service,
        features: [],
        whatIsIncluded: [],
        whatIsExcluded: [],
        specifications: [],
      );
    }
  }

  ServiceDetail get serviceDetail => _serviceDetail;

  // Optional: Method to update service detail if needed
  void updateServiceDetail(Service newService) {
    _serviceDetail = ServiceDetail(
      service: newService,
      features: _serviceDetail.features,
      whatIsIncluded: _serviceDetail.whatIsIncluded,
      whatIsExcluded: _serviceDetail.whatIsExcluded,
      specifications: _serviceDetail.specifications,
    );
    notifyListeners();
  }
}