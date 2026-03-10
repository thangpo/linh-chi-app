import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    Key? key,
    required this.loadingScreenBackgroundColor,
    this.onAnimationComplete,
  }) : super(key: key);

  final Color loadingScreenBackgroundColor;
  final VoidCallback? onAnimationComplete;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [

          /// CENTER TEXT
          Center(
            child: Text(
              "ANGEL\nLINH CHI",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),

          /// LEFT TRIANGLE
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {

              return Transform.translate(
                offset: Offset(-MediaQuery.of(context).size.width * _animation.value, 0),
                child: ClipPath(
                  clipper: LeftTriangleClipper(),
                  child: Container(
                    color: const Color(0xFF1FA64A),
                  ),
                ),
              );
            },
          ),

          /// RIGHT TRIANGLE
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {

              return Transform.translate(
                offset: Offset(MediaQuery.of(context).size.width * _animation.value, 0),
                child: ClipPath(
                  clipper: RightTriangleClipper(),
                  child: Container(
                    color: const Color(0xFF179444),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LeftTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {

    Path path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class RightTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {

    Path path = Path();

    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}