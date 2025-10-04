import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_app/splash_screen.dart';
import 'controllers/home_conroller.dart';
import 'controllers/socket_controller.dart';

import 'controllers/cart_provider.dart';
import 'controllers/location_controller.dart';
import 'controllers/user_controller.dart';
import 'controllers/order_controller.dart';
import 'services/api_services.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocationController()),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => OrderController(apiService: ApiServices())),
        ChangeNotifierProvider(create: (_) => SocketController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketController = context.read<SocketController>();
      final orderController = context.read<OrderController>();

      // Assign callback
      socketController.onMaidStartedOrder = (orderId, maidInfo) {
        orderController.updateMaidInfo(orderId, maidInfo);
        debugPrint('✅ OrderController updated for orderId: $orderId');
      };

      // Connect socket
      socketController.connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "The Helply",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}
