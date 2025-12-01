import 'package:flutter/material.dart';
import 'login_page.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late AnimationController _rollController;
  late AnimationController _popController;

  late Animation<double> _xAnimation;
  late Animation<double> _yAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _popAnimation;

  int _stage = 0; // 0 = full egg, 1 = cracked, 2 = chick

  @override
  void initState() {
    super.initState();

    // Controller for roll + bounce
    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Horizontal movement: left -> center
    _xAnimation = Tween<double>(begin: -1.2, end: 0.0).animate(
      CurvedAnimation(parent: _rollController, curve: Curves.easeInOutCubic),
    );

    // Vertical bounce: 2 bounces, moderate height
    _yAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween:
            Tween(begin: 0.0, end: -0.8) // moderate bounce height
                .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.8,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 0.0, end: -0.5) // second bounce slightly smaller
                .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.5,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_rollController);

    // Rotation while rolling
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(parent: _rollController, curve: Curves.linear));

    // Pop animation for chick
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _popAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _popController, curve: Curves.elasticOut),
    );

    // Stage switching based on animation progress
    _rollController.addListener(() {
      final progress = _rollController.value;
      if (progress < 0.5 && _stage != 0) {
        setState(() => _stage = 0); // full egg
      } else if (progress >= 0.5 && _stage != 1) {
        setState(() => _stage = 1); // cracked
      }
    });

    // Start the rolling + bounce animation
    _rollController.forward().whenComplete(() {
      setState(() => _stage = 2); // final chick
      _popController.forward().whenComplete(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    });
  }

  @override
  void dispose() {
    _rollController.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _stage == 0
        ? 'assets/fullegg.png'
        : _stage == 1
        ? 'assets/brokenlogo.png'
        : 'assets/chick_icon.png';

    return Scaffold(
      backgroundColor: const Color(0xFFFFC400),
      body: AnimatedBuilder(
        animation: Listenable.merge([_rollController, _popController]),
        builder: (context, child) {
          final alignment = Alignment(_xAnimation.value, _yAnimation.value);
          return Align(
            alignment: _stage == 2 ? Alignment.center : alignment,
            child: ScaleTransition(
              scale: _stage == 2
                  ? _popAnimation
                  : const AlwaysStoppedAnimation(1),
              child: Transform.rotate(
                angle: _stage == 2 ? 0 : _rotationAnimation.value,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Image.asset(
                    image,
                    key: ValueKey(image),
                    width: 150,
                    height: 150,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
