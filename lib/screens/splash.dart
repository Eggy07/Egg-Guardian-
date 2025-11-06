import 'package:flutter/material.dart';
import 'login_page.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _AnimatedChickState();
}

class _AnimatedChickState extends State<Splash>
    with TickerProviderStateMixin {
  late AnimationController _jumpController;
  late AnimationController _popController;

  late Animation<double> _xAnimation;
  late Animation<double> _yAnimation;
  late Animation<double> _popAnimation;

  int _stage = 0; // 0 = full egg, 1 = cracked, 2 = chick

  @override
  void initState() {
    super.initState();

    // Controller for jump animation (left → center → right)
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // X movement: left → center → right
    _xAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(_jumpController);

    // Y movement: creates the "jump arc"
    _yAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.8) // jump up
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.8, end: 0.0) // fall down
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.8),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.8, end: 0.0),
        weight: 0.5,
      ),
    ]).animate(_jumpController);

    // Popup bounce for final chick
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _popAnimation = Tween<double>(begin: 0.7, end: 1.4).animate(
      CurvedAnimation(parent: _popController, curve: Curves.elasticOut),
    );

    // Stage switching
    _jumpController.addListener(() {
      final progress = _jumpController.value;
      if (progress < 0.5 && _stage != 0) {
        setState(() => _stage = 0); // full egg
      } else if (progress >= 0.5 && progress < 1.0 && _stage != 1) {
        setState(() => _stage = 1); // cracked egg
      }
    });

    _jumpController.forward().whenComplete(() {
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
    _jumpController.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _stage == 0
        ? '/fullegg.png'
        : _stage == 1
            ? '/brokenlogo.png'
            : '/chick_icon.png';

    return Scaffold(
      backgroundColor: const Color(0xFFFFC400),
      body: AnimatedBuilder(
        animation: Listenable.merge([_jumpController, _popController]),
        builder: (context, child) {
          // Chick jumps with alignment from -1..1 horizontally and -0.8..0 vertically
          final alignment = Alignment(_xAnimation.value, _yAnimation.value);

          return Align(
            alignment: _stage == 2 ? Alignment.center : alignment,
            child: ScaleTransition(
              scale: _stage == 2 ? _popAnimation : const AlwaysStoppedAnimation(1),
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
          );
        },
      ),
    );
  }
}
