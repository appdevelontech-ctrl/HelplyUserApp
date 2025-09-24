import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_app/controllers/cart_provider.dart';
import 'package:user_app/controllers/service_category_controller.dart';

import 'controllers/home_conroller.dart';
import 'main_screen.dart';


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
        ChangeNotifierProvider(create: (_) => CartProvider()), // 👈 Global Provider
      ],
      child: MaterialApp(
        title: "The Helply",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const MainScreen(),
      ),
    );
  }
}