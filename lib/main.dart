import 'package:Helply/services/socketservice.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'controllers/home_conroller.dart';
import 'controllers/socket_controller.dart';
import 'controllers/cart_provider.dart';
import 'controllers/location_controller.dart';
import 'controllers/user_controller.dart';
import 'controllers/order_controller.dart';
import 'services/api_services.dart';
import 'splash_screen.dart';

void main() {
  // Call configLoading to set up EasyLoading
  _MyAppState.configLoading(); // Call the static method from _MyAppState

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SocketLiveTrackingController(),
        ),
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
      builder: EasyLoading.init(), // EasyLoading is initialized with configured settings
    );
  }

  static void configLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.circle
      ..loadingStyle = EasyLoadingStyle.dark
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..backgroundColor = Colors.black.withOpacity(0.7)
      ..indicatorColor = Colors.white
      ..maskColor = Colors.black.withOpacity(0.5)
      ..userInteractions = false
      ..dismissOnTap = false;
  }
}

