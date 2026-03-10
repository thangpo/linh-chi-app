import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hisotech/services/database_service.dart';
import 'package:hisotech/view/screens/home_screen.dart';
import 'package:hisotech/view/screens/products_screen.dart';
import 'package:hisotech/view/screens/store_screen.dart';
import 'package:hisotech/view/screens/profile_screen.dart';
import 'package:hisotech/view/screens/app_webview.dart';
import 'package:hisotech/view/screens/loading_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();

  final WidgetsBinding widgetsBinding =
  WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await DatabaseService().init();

  runApp(const AngelLinhChiApp());

  FlutterNativeSplash.remove();
}

class AngelLinhChiApp extends StatelessWidget {
  const AngelLinhChiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ANGEL LINH CHI',
      theme: ThemeData(
        primaryColor: const Color(0xFF16A34A),
        primarySwatch: Colors.green,
      ),
      home: const AppStarter(),
    );
  }
}

class AppStarter extends StatefulWidget {
  const AppStarter({Key? key}) : super(key: key);

  @override
  State<AppStarter> createState() => _AppStarterState();
}

class _AppStarterState extends State<AppStarter> {

  void _onLoadingFinished() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigation(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen(
      loadingScreenBackgroundColor: const Color(0xFF16A34A),
      onAnimationComplete: _onLoadingFinished,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    Key? key,
    required this.loadingScreenBackgroundColor,
    required this.onAnimationComplete,
  }) : super(key: key);

  final Color loadingScreenBackgroundColor;
  final VoidCallback onAnimationComplete;

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

    Future.delayed(const Duration(milliseconds: 700), () {
      _controller.forward();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: widget.loadingScreenBackgroundColor,
      body: Stack(
        children: [

          const Center(
            child: Text(
              "ANGEL\nLINH CHI",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-screenWidth * _animation.value, 0),
                child: ClipPath(
                  clipper: LeftTriangleClipper(),
                  child: Container(
                    color: widget.loadingScreenBackgroundColor,
                  ),
                ),
              );
            },
          ),

          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(screenWidth * _animation.value, 0),
                child: ClipPath(
                  clipper: RightTriangleClipper(),
                  child: Container(
                    color: widget.loadingScreenBackgroundColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _AnimatedNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback onFabTapped;
  final bool showFab;

  const _AnimatedNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onFabTapped,
    this.showFab = true,
  }) : super(key: key);

  @override
  State<_AnimatedNavBar> createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<_AnimatedNavBar> with TickerProviderStateMixin {
  static const _items = [
    _NavItem(Icons.home_rounded, 'Trang chủ'),
    _NavItem(Icons.shopping_bag_rounded, 'Sản phẩm'),
    _NavItem(Icons.person_rounded, 'Tài khoản'),
    _NavItem(Icons.store_rounded, 'Cửa hàng'),
  ];

  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _items.length,
          (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      ),
    );
    _scaleAnims = _controllers
        .map((c) => Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: c, curve: Curves.elasticOut),
    ))
        .toList();

    if (widget.selectedIndex < _controllers.length) {
      _controllers[widget.selectedIndex].forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      if (oldWidget.selectedIndex < _controllers.length) {
        _controllers[oldWidget.selectedIndex].reverse();
      }
      if (widget.selectedIndex < _controllers.length) {
        _controllers[widget.selectedIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildNavItem(0)),
          Expanded(child: _buildNavItem(1)),
          SizedBox(
            width: 74,
            child: widget.showFab
                ? _buildFabButton()
                : const SizedBox.shrink(),
          ),
          Expanded(child: _buildNavItem(2)),
          Expanded(child: _buildNavItem(3)),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = widget.selectedIndex == index;
    final item = _items[index];

    return GestureDetector(
      onTap: () => widget.onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controllers[index],
        builder: (context, child) {
          return SizedBox(
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _scaleAnims[index].value,
                  child: Icon(
                    item.icon,
                    size: 24,
                    color: isSelected
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFB0B0B0),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFB0B0B0),
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFabButton() {
    return GestureDetector(
      onTap: widget.onFabTapped,
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.language_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const String _homePageURL = 'https://angelunigreen.com.vn/';

  late final List<Widget> _screens = [
    const HomeScreen(),
    const ProductsScreen(),
    const WebViewAppPage(webviewURL: _homePageURL),
    const AccountScreen(),
    const StoreScreen(),
  ];

  void _onNavTap(int navIndex) {
    const screenMap = [0, 1, 3, 4];
    setState(() {
      _selectedIndex = screenMap[navIndex];
    });
  }

  int get _navBarIndex {
    const screenMap = [0, 1, -1, 2, 3];
    final idx = _selectedIndex < screenMap.length ? screenMap[_selectedIndex] : 0;
    return idx == -1 ? 0 : idx;
  }

  void _onFabTapped() {
    setState(() => _selectedIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    final bool isWebView = _selectedIndex == 2;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: isWebView
          ? null
          : _AnimatedNavBar(
        selectedIndex: _navBarIndex,
        onItemTapped: _onNavTap,
        onFabTapped: _onFabTapped,
        showFab: true,
      ),
    );
  }
}