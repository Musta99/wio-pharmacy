import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wio_pharmacy/main_container.dart';
import 'package:wio_pharmacy/view/screens/authentication/login_screen.dart';
import 'package:wio_pharmacy/viewmodel/authentication/authentication_view_model.dart';

const Color _kNavy = Color(0xFF0E1B33);
const Color _kNavySoft = Color(0xFF16294A);
const Color _kCoral = Color(0xFFFF5A45);
const Color _kMint = Color(0xFF17A673);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    // A short pause so the splash animation/branding is visible at all —
    // trimmed from 2s since that was adding flat dead time on every launch.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final authViewModel = context.read<AuthenticationViewModel>();
    final isLoggedIn = await authViewModel.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn && authViewModel.role == 'pharmacy') {
      // FCM setup (permission dialog, token fetch, backend registration)
      // can easily take several seconds — none of it needs to finish
      // before the hospital user sees their dashboard, so it's intentionally
      // NOT awaited here. It keeps running in the background after we
      // navigate away.
      // unawaited(
      //   FcmService.initialize(
      //     onNotificationTap: (data) {
      //       // TODO: navigate based on data — e.g. data['url'] or
      //       // data['type'] == 'lab_order' -> push to the relevant tab.
      //       print('Notification tapped with data: $data');
      //     },
      //   ),
      // );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainContainerScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kNavy, _kNavySoft],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_kCoral, Color(0xFFFF8A65)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kCoral.withOpacity(0.35),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_outlined,
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Wio Pharmacy',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Partner Portal',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.55),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 44),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: _kMint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
