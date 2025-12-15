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

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/maid1.jpg",
      "title": "Find Trusted Maids",
      "sub": "Search verified & trained household helpers near you."
    },
    {
      "image": "assets/images/maid2.jpg",
      "title": "Live Tracking",
      "sub": "Track arrival & service status in real-time."
    },
    {
      "image": "assets/images/maid3.jpg",
      "title": "Secure & Reliable",
      "sub": "All maids are identity verified and background checked."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// ---------------- Background Pages ----------------
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => currentPage = index),
            itemCount: onboardingData.length,
            itemBuilder: (_, index) {
              return Stack(
                children: [
                  /// Full background image
                  Positioned.fill(
                    child: Image.asset(
                      onboardingData[index]["image"]!,
                      fit: BoxFit.cover,
                    ),
                  ),

                  /// Black overlay gradient bottom
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// Text Section
                  Positioned(
                    bottom: 140,
                    left: 25,
                    right: 25,
                    child: Column(
                      children: [
                        Text(
                          onboardingData[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          onboardingData[index]["sub"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              );
            },
          ),


          /// ---------------- Skip Button ----------------
          Positioned(
            top: 55,
            right: 25,
            child: GestureDetector(
              onTap: () async {
                if (currentPage == onboardingData.length - 1) {
                  await StorageService.markOnboardingDone();
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreen()));
                } else {
                  _controller.jumpToPage(onboardingData.length - 1);
                }
              },
              child: Text(
                "Skip",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),


          /// ---------------- Indicators + Next/Get Started ----------------
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                /// Dot Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingData.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 9,
                      width: currentPage == index ? 26 : 9,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: currentPage == index
                            ? Colors.blueAccent
                            : Colors.white54,
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                /// Get Started / Next Buttons
                currentPage == onboardingData.length - 1
                    ? SizedBox(
                  width: 220,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                    onPressed: () async {
                      await StorageService.markOnboardingDone();
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreen()));
                    },
                    child: const Text(
                      "Get Started",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.white),
                    ),
                  ),
                )
                    : GestureDetector(
                  onTap: () {
                    _controller.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut);
                  },
                  child: Container(
                    width: 190,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: Colors.white.withOpacity(0.8)),
                      color: Colors.white.withOpacity(0.15),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Next",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
