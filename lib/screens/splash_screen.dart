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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _pulseAnimation;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    ));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _controller.repeat(reverse: true);
    _handleNavigation();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleNavigation() {
    final minDuration = Future.delayed(const Duration(seconds: 3));
    final authStateFuture = AuthService.instance.authStateChanges.first;

    Future.wait([minDuration, authStateFuture]).then((results) {
      if (!mounted) return;
      final authState = results.last as AuthState;

      final uri = Uri.parse(Uri.base.toString());
      final fragment = uri.fragment;
      final fragmentParams = Uri.splitQueryString(fragment);

      if (fragmentParams['type'] == 'recovery' &&
          fragmentParams.containsKey('access_token')) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
        return;
      }

      final session = authState.session;
      if (session != null) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomePage(user: session.user)));
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthScreen()));
      }
    }).catchError((error) {
      if (!mounted) return;
      debugPrint("Error during splash screen navigation: $error");
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withAlpha(20),
                  cs.secondary.withAlpha(10),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: const AppBrand(height: 120, showText: true),
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: Text(
                            'Gestion d\'achats simplifiée',
                            style: TextStyle(
                              fontSize: 16,
                              color: cs.onSurface.withAlpha(160),
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
