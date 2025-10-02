import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/user_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Check login status after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final userController =
        Provider.of<UserController>(context, listen: false);
        userController.checkLoginStatus(context);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          "assets/images/splash.jpeg",
          fit: BoxFit.contain,
        ),
        Container(
          color: Colors.black.withOpacity(0.3),
        ),
        const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ],
    );
  }
}
