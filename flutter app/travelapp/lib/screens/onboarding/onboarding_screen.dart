import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart';
import '../../utils/contants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _displayNameController = TextEditingController();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _locationGranted = false;

  final supabase = Supabase.instance.client;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.explore_outlined,
      'title': 'Discover Places',
      'subtitle': 'Find amazing locations around you — restaurants, activities, hidden gems and more.',
    },
    {
      'icon': Icons.map_outlined,
      'title': 'Your Travel Map',
      'subtitle': 'Track every place you\'ve visited and build your personal travel story.',
    },
    {
      'icon': Icons.stars_outlined,
      'title': 'Earn Rewards',
      'subtitle': 'Complete objectives, earn XP and unlock badges as you explore.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    setState(() {
      _locationGranted = status.isGranted;
    });
    _nextPage();
  }

  Future<void> _completeOnboarding() async {
    if (_displayNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your display name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('profiles').upsert({
        'id': userId,
        'display_name': _displayNameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done_$userId', true);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentPage = i),
          children: [
            // Slides 0, 1, 2
            ..._slides.asMap().entries.map((e) => _buildSlide(e.key, e.value)),
            // Location permission page
            _buildLocationPage(),
            // Profile setup page
            _buildProfilePage(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(int index, Map<String, dynamic> slide) {
    final isLast = index == _slides.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress dots
          _buildDots(5),
          const SizedBox(height: 48),

          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: Icon(slide['icon'] as IconData, color: AppColors.accent, size: 56),
          ),

          const SizedBox(height: 40),

          Text(
            slide['title'] as String,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            slide['subtitle'] as String,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 64),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isLast ? 'Almost There!' : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (index == 0) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                // Skip to profile setup
                _pageController.animateToPage(
                  4,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDots(5),
          const SizedBox(height: 48),

          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: const Icon(Icons.location_on, color: AppColors.accent, size: 56),
          ),

          const SizedBox(height: 40),

          const Text(
            'Enable Location',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Allow MY Map to access your location to find nearby places and personalize your experience.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 64),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _requestLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Allow Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: _nextPage,
            child: const Text(
              'Skip for now',
              style: TextStyle(color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDots(5),
          const SizedBox(height: 48),

          const Icon(Icons.person_outline, color: AppColors.accent, size: 64),

          const SizedBox(height: 24),

          const Text(
            'Set Up Profile',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'How should we call you?',
            style: TextStyle(color: Colors.white54, fontSize: 15),
          ),

          const SizedBox(height: 40),

          Container(
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: _displayNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Display Name',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.badge_outlined, color: Colors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF0D3B6E),
                      ),
                    )
                  : const Text(
                      'Get Started!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == i ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == i ? AppColors.accent : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}