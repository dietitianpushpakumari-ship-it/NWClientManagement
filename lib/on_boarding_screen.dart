import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/authwrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "heading": "Precision Care",
      "description": "Design personalized diet plans with clinical precision. Tailor every macro and micro for your patients' unique needs.",
      "icon": Icons.verified_user_outlined,
    },
    {
      "heading": "Real-Time Vitals",
      "description": "Monitor client progress instantly. Track steps, hydration, sleep, and vital signs in a unified dashboard.",
      "icon": Icons.monitor_heart_outlined,
    },
    {
      "heading": "Automated Nudges",
      "description": "Set smart alarms for meals and habits. Let the system handle the reminders while you focus on the care.",
      "icon": Icons.notifications_active_outlined,
    },
    {
      "heading": "Master Control",
      "description": "A powerful command center for your practice. Manage clients, content, and schedules seamlessly.",
      "icon": Icons.admin_panel_settings_outlined,
    },
  ];

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colorScheme.primaryContainer,
        colorScheme.surface,
        colorScheme.surface,
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Layer
          Container(decoration: BoxDecoration(gradient: backgroundGradient)),

          // 2. Decorative Background Glow (FIXED)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // 🎯 FIX: Moved blurRadius into boxShadow
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 60,
                    spreadRadius: 20,
                  )
                ],
              ),
            ),
          ),

          // 3. Main Content
          Column(
            children: [
              Expanded(
                flex: 3,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingData.length,
                  onPageChanged: (int page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) => _PremiumOnboardingPage(
                    data: onboardingData[index],
                    isActive: _currentPage == index,
                  ),
                ),
              ),

              // 4. Bottom Glass Sheet
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.8),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5))),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            onboardingData.length,
                                (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: _currentPage == index ? 32 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            if (_currentPage != onboardingData.length - 1)
                              TextButton(
                                onPressed: _completeOnboarding,
                                child: Text(
                                  "Skip",
                                  style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.w600),
                                ),
                              ),

                            const Spacer(),

                            ElevatedButton(
                              onPressed: () {
                                if (_currentPage == onboardingData.length - 1) {
                                  _completeOnboarding();
                                } else {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutQuint,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                                shadowColor: colorScheme.primary.withOpacity(0.4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentPage == onboardingData.length - 1 ? "Get Started" : "Next",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumOnboardingPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isActive;

  const _PremiumOnboardingPage({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isActive ? 1.0 : 0.8,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                data['icon'],
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 60),

          AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Column(
              children: [
                Text(
                  data['heading'],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  data['description'],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}