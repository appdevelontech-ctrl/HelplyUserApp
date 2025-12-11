import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_app/services/storage_service.dart';
import 'package:user_app/views/auth/login_screen.dart';
import 'package:user_app/views/onboarding.dart';
import 'controllers/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';


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

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    _checkNavigation(); // 🚀
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(seconds: 2));

    bool onboarded = await StorageService.isOnboardingDone();
    final prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool("isLoggedIn") ?? false;

    // ⛔️ FIRST PRIORITY: Onboarding
    if (!onboarded) {
      _goTo(OnboardingScreen());
      return;
    }

    // ⛔️ SECOND PRIORITY: Login
    if (!loggedIn) {
      _goTo(const LoginScreen());
      return;
    }

    // ⛔️ THIRD PRIORITY: If logged in → verify user data
    final userController = Provider.of<UserController>(context, listen: false);
    await userController.checkLoginStatus(context);
  }


  void _goTo(Widget page){
    if(!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/splash_screen.png",
              fit: BoxFit.fill
              ,
            ),
          ),

          Container(color: Colors.black.withOpacity(0.4)),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
