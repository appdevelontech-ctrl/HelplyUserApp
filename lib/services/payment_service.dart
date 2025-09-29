import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../services/api_services.dart';
import 'package:provider/provider.dart';

class PaymentService {
  final Razorpay _razorpay = Razorpay();
  final ApiServices _apiServices;
  final BuildContext context;
  String? _currentOrderId;

  PaymentService(this.context, this._apiServices) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> initiatePayment(Order order) async {
    try {
      print('🚀 Initiating payment for order ID: ${order.orderId}, _id: ${order.id}');

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        print('⚠️ User ID not found. Please log in again.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in!")),
        );
        return;
      }

      final orderResponse = await _apiServices.createPaymentOrder({
        "orderId": order.id,
        "totalAmount": order.totalAmount.toString(),
        "callback_url": "(not required) -> {{url}}/order-payment-verification"
      });

      print('Order Response: $orderResponse');

      if (orderResponse['success'] != true) {
        print("❌ Failed to create payment order: ${orderResponse['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create payment order: ${orderResponse['message']}")),
        );
        return;
      }

      final razorpayOrderId = orderResponse['Order']['razorpay_order_id'];
      if (razorpayOrderId == null) {
        print("❌ Backend did not return a valid Razorpay order ID.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid Razorpay order ID!")),
        );
        return;
      }

      _currentOrderId = razorpayOrderId;
      print('✅ Razorpay Order Created: $razorpayOrderId');

      var options = {
        'key': 'rzp_test_uAogD6y8XGq1H0', // Your Razorpay Key
        'amount': (order.totalAmount * 100).toInt(),
        'name': 'Your App Name',
        'description': 'Payment for Order #${order.orderId}',
        'order_id': razorpayOrderId,
        'prefill': {'contact': '9334274325', 'email': 'rk9600460@gmail.com'},
        'external': {'wallets': ['paytm']},
      };

      print('🛠 Opening Razorpay Checkout with options: $options');
      _razorpay.open(options);
    } catch (e) {
      print('❌ Error initiating payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error initiating payment: $e")),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      print("✅ Payment Success Callback: paymentId=${response.paymentId}, signature=${response.signature}");

      if (_currentOrderId == null || response.paymentId == null) {
        print("❌ Payment verification failed: missing orderId or paymentId");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment verification failed!")),
        );
        return;
      }

      final verifyResponse = await _apiServices.verifyPayment(
        razorpayOrderId: _currentOrderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature ?? '',
      );

      print("📋 Verify Response: $verifyResponse");

      if (verifyResponse['success'] == true) {
        print("✅ Payment Verified Successfully!");
        // ✅ Update UI immediately
        if (context.mounted) {
          await Provider.of<OrderController>(context, listen: false).fetchOrders();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Successful!")),
          );
        }
      } else {
        print("❌ Payment Verification Failed: ${verifyResponse['message']}");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Payment Successfully")),
          );
        }
      }
    } catch (e) {
      print('❌ Error verifying payment: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error verifying payment: $e")),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("❌ Payment Failed: ${response.message ?? 'Unknown error'}");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment Failed: ${response.message ?? 'Unknown error'}")),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("💳 External Wallet Selected: ${response.walletName}");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
      );
    }
  }

  void dispose() {
    _razorpay.clear();
    _currentOrderId = null;
    print('🗑️ PaymentService disposed');
  }
}
