import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../models/serviceCategoryDetail.dart';
import '../services/api_services.dart';

class ProductDetailController extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  ProductDetail? _productDetail;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  ProductDetail? get productDetail => _productDetail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductDetailController();

  Future<void> fetchProductDetails(String slug) async {
    if (_isDisposed) return;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await EasyLoading.show(status: 'Loading product details...');
      _productDetail = await _apiServices.fetchProductDetails(slug);
      await EasyLoading.dismiss();


      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error fetching product details: $e';
      await EasyLoading.showError(_errorMessage!);
      notifyListeners();
      debugPrint(_errorMessage);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}