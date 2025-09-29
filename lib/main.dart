import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_app/controllers/cart_provider.dart';
import 'package:user_app/controllers/location_controller.dart';

import 'package:user_app/controllers/order_controller.dart';
import 'package:user_app/controllers/user_controller.dart';
import 'package:user_app/services/api_services.dart';
import 'package:user_app/splash_screen.dart';

import 'controllers/home_conroller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocationController()),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => OrderController(apiService: ApiServices())),
      ],
      child: MaterialApp(
        title: "The Helply",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}