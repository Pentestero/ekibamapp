import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/screens/home_page.dart';
import 'package:provisions/screens/auth_screen.dart';
import 'package:provisions/screens/reset_password_screen.dart';
import 'package:provisions/widgets/app_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _handleNavigation();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleNavigation() {
    // Wait for a minimum duration for the animation to be seen
    final minDuration = Future.delayed(const Duration(seconds: 3));

    // Listen to the first auth state
    final authStateFuture = AuthService.instance.authStateChanges.first;

    // When both are complete, navigate
    Future.wait([minDuration, authStateFuture]).then((results) {
      if (!mounted) return; // Ensure widget is still in the tree
      final authState = results.last as AuthState;

      // Check for password recovery link
      final uri = Uri.parse(Uri.base.toString());
      final fragment = uri.fragment;
      final fragmentParams = Uri.splitQueryString(fragment);

      if (fragmentParams['type'] == 'recovery' && fragmentParams.containsKey('access_token')) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
        return;
      }

      final session = authState.session;
      if (session != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage(user: session.user)));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
      }
    }).catchError((error) { // ADDED CATCHERROR BLOCK
      if (!mounted) return;
      debugPrint("Error during splash screen navigation: $error");
      // Fallback to AuthScreen on error
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: const AppBrand(height: 120, showText: true),
          ),
        ),
      ),
    );
  }
}

