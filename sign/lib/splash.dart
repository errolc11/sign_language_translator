import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign/main.dart'; // Make sure this import is correct

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final Color _shadowColor = Colors.black.withOpacity(0.5); // Shadow color variable

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00796B), Color(0xFF7B1FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      'images/sup.png', // Make sure this path is correct
                      width: 400,
                      height: 400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder(
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeIn,
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, double opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: child,
                      );
                    },
                    child: Text( // Removed const here
                      'Sign Language Translator',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: _shadowColor, // Use the variable here
                            blurRadius: 10,
                            offset: const Offset(3, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
    );
  }
}
