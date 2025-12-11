import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  /// Only Images (No Title/Text needed because it's already in image)
  final List<String> onboardingImages = [
    "assets/imagesforscreen/4.jpg",
    "assets/imagesforscreen/5.jpg",
  ];

  Future<void> finishOnboarding() async {
    await StorageService.markOnboardingDone();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// ---------- Fullscreen PageView Images ----------
          PageView.builder(
            controller: _controller,
            itemCount: onboardingImages.length,
            onPageChanged: (index) => setState(() => currentPage = index),
            itemBuilder: (_, index) => Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(onboardingImages[index]),
                  fit: BoxFit.fill
                  ,
                ),
              ),
            ),
          ),

          /// ---------- Skip Button ----------
          Positioned(
            top: 50,
            right: 20,
            child: currentPage < onboardingImages.length - 1
                ? GestureDetector(
              onTap: () => _controller.jumpToPage(onboardingImages.length - 1),
              child: const Text(
                "Skip",
                style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            )
                : const SizedBox.shrink(),
          ),

          /// ---------- Indicators + Buttons ----------
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [

                /// --- Page Indicators ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingImages.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 10,
                      width: currentPage == index ? 28 : 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: currentPage == index ? Colors.blue : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// --- Next / Get Started Button ---
                currentPage == onboardingImages.length - 1
                    ? ElevatedButton(
                  onPressed: finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                  ),
                  child: const Text("Get Started", style: TextStyle(fontSize: 18, color: Colors.white)),
                )
                    : ElevatedButton(
                  onPressed: () {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 16),
                  ),
                  child: const Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
