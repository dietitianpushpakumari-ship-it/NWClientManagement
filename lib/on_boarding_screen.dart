import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/authwrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  // 🎯 UPDATED DATA: Incorporating Diet Plans, Tracking, Goals, and Reminders/Alarms
  final List<Map<String, dynamic>> onboardingData = [
    {
      "heading": "Personalized Diet Plans",
      "description": "Create and manage patient-specific diet plans tailored to their unique health needs and dietary preferences.",
      "icon": Icons.restaurant_menu_rounded, // Feature: Diet Plan Creation
    },
    {
      "heading": "Track & Monitor Progress",
      "description": "Monitor client activity, log vitals, and track progress towards targeted health goals in real-time.",
      "icon": Icons.query_stats_rounded, // Feature: Tracking & Goals
    },
    {
      "heading": "Smart Reminders & Alarms",
      "description": "Configure custom alarms and reminders for meals, hydration, and medication to keep patients on track.",
      "icon": Icons.alarm_on_rounded, // 🎯 NEW Feature: Reminders & Alarms
    },
    {
      "heading": "Comprehensive Care",
      "description": "From onboarding to daily management, access all the tools you need to ensure your patients' success.",
      "icon": Icons.health_and_safety_rounded,
    },
  ];

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    // Set flag to true so the user bypasses this screen next time
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;
    // Navigate to the AuthWrapper (or Login) when done
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
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
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // --- 1. SKIP BUTTON (Top Right) ---
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // --- 2. SLIDING CONTENT AREA ---
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

            // --- 3. BOTTOM CONTROLS (Dots & Button) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
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
                  const SizedBox(height: 40),

                  // Main Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == onboardingData.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 4,
                        shadowColor: colorScheme.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == onboardingData.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  // Helper: Animated Dot
  Widget _buildDot(BuildContext context, {required int index}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isActive = _currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 32 : 8, // Elongate active dot
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primary : colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// --- Helper Widget: Single Page Content ---
class _OnboardingPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // --- Feature Icon/Illustration ---
          // Using a Container with a soft background to highlight the icon
          Container(
            height: 280,
            width: 280,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Icon(
                  data["icon"],
                  size: 100,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // --- Heading ---
          Text(
            data["heading"]!,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // --- Description ---
          Text(
            data["description"]!,
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}