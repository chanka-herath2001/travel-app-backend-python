import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/bucket_list/bucket_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'widgets/app_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://prwuukgzlxijdeyjyjnm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByd3V1a2d6bHhpamRleWp5am5tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4MDc2MTMsImV4cCI6MjA4NjM4MzYxM30.AGCpPfCiKMz2Npny7i3kCv795E26W5D1dKt5CZsxd7s',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MY Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D3B6E)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D3B6E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFB8F04A)),
            ),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return const OnboardingGate();
        }

        return const LoginScreen();
      },
    );
  }
}

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _loading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = supabase.auth.currentUser?.id ?? '';
    final key = 'onboarding_done_$userId';
    final done = prefs.getBool(key) ?? false;
    setState(() {
      _showOnboarding = !done;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D3B6E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB8F04A)),
        ),
      );
    }
    if (_showOnboarding) {
      return const OnboardingScreen();
    }
    return const MainShell();
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      // Gamification — wire to global state later
      level: 12,
      xpProgress: 0.65,
      coins: 450,
      showChatBadge: true,
      onProfileTap: () {
        // Navigate to Profile tab (index 4)
      },
      pages: const [
        AppPage(title: 'Home', body: HomeScreen()),
        AppPage(title: 'Search', body: SearchScreen()),
        AppPage(title: 'Bucket List', body: BucketListScreen()),
        AppPage(title: 'Chat', body: ChatScreen()),
        AppPage(title: 'Profile', body: ProfileScreen()),
      ],
    );
  }
}