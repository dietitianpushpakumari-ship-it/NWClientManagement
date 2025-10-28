import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/authwrapper.dart';
import 'package:nutricare_client_management/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import your LoginScreen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  // Data for your onboarding slides (Wellness Focus)
  final List<Map<String, String>> onboardingData = [
    {
      "heading": "Track Your Wellness Journey",
      "description": "Log your meals, vital statistics, and physical activity with ease to keep your progress visible.",
      "image_path": "assets/onboarding_track.png",
    },
    {
      "heading": "Personalized Diet & Goals",
      "description": "Receive and view diet plans customized by your dietitian, perfectly aligned with your health objectives.",
      "image_path": "assets/onboarding_plan.png",
    },
    {
      "heading": "Direct Expert Connection",
      "description": "Use the integrated chat to communicate instantly with your coach for real-time support and advice.",
      "image_path": "assets/onboarding_chat.png",
    },
  ];

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    // Set flag to true so the user bypasses this screen next time
    await prefs.setBool('hasSeenOnboarding', true);

    // Navigate to the LoginScreen and remove all previous routes
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        // ✅ Navigate to the AuthWrapper when onboarding is done
        builder: (context) => const AuthWrapper(),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // --- Page View for Swiping Slides ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, index) => _OnboardingPage(
                  data: onboardingData[index],
                ),
              ),
            ),

            // --- Dots Indicator & Buttons ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                          (index) => _buildDot(context, index: index),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // The main Call-to-Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == onboardingData.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      // Uses the ElevatedButton theme defined in app_theme.dart
                      child: Text(
                        _currentPage == onboardingData.length - 1 ? 'Get Started' : 'Next',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onPrimary, // Text color is based on primary color
                        ),
                      ),
                    ),
                  ),

                  // Skip button on first page
                  if (_currentPage < onboardingData.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the indicator dots
  Widget _buildDot(BuildContext context, {required int index}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? colorScheme.primary : colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Widget for a single onboarding page content
class _OnboardingPage extends StatelessWidget {
  final Map<String, String> data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Placeholder for your image/illustration
          Container(
            height: 300,
            width: 300,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                Icons.favorite_border,
                size: 80,
                color: colorScheme.primary,
              ),
            ),
            // Replace with Image.asset(data["image_path"]!)
          ),
          const SizedBox(height: 50),
          Text(
            data["heading"]!,
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            data["description"]!,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}