import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hisotech/services/database_service.dart';
import 'package:hisotech/services/scraper_service.dart';
import 'package:hisotech/view/widgets/member_ranks_widget.dart';
import 'package:hisotech/view/widgets/category_banners_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:hisotech/view/screens/category_products_screen.dart';
import 'package:hisotech/view/screens/wishlist_screen.dart';
import 'package:hisotech/view/screens/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseService();

  // ── Stats ──
  int _productCount = 0;
  int _storeCount = 0;
  bool _isSyncing = false;
  bool _isLoadingHome = true;
  String? _lastSync;
  int _totalPartners = 950;

  // ── Home data ──
  List<MemberRank> _memberRanks = [];
  List<CategoryBanner> _categoryBanners = [];
  List<SliderImage> _sliderImages = [];

  // ── Header badges (cào từ website) ──
  int _wishlistCount = 0;
  int _cartCount = 0;
  int _notifCount = 0;
  bool _isLoadingBadges = true;

  // ── Slider ──
  late PageController _sliderPageController;
  int _currentSliderPage = 0;
  Timer? _sliderTimer;

  // ── Theme colors ──
  final Color _green = const Color(0xFF16A34A);
  final Color _darkGreen = const Color(0xFF15803D);
  final Color _gold = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _sliderPageController = PageController();
    _loadStats();
    _autoSync();
    _loadHomeData();
    _loadHeaderBadges(); // ← Cào badge wishlist / cart / notif
  }

  @override
  void dispose() {
    _sliderPageController.dispose();
    _sliderTimer?.cancel();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Cào số badge Wishlist, Cart, Notification từ website
  // HTML mẫu:
  //   <span class="tp-header-action-badge" data-bb-value="wishlist-count">0</span>
  //   <span class="tp-header-action-badge" data-bb-value="cart-count">1</span>
  //   <span class="tp-header-action-badge">0</span>  ← notification
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _loadHeaderBadges() async {
    setState(() => _isLoadingBadges = true);
    try {
      final badges = await WebScraperService.scrapeHeaderBadges();
      if (mounted) {
        setState(() {
          _wishlistCount = badges['wishlist'] ?? 0;
          _cartCount = badges['cart'] ?? 0;
          _notifCount = badges['notif'] ?? 0;
          _isLoadingBadges = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi load badges: $e');
      if (mounted) setState(() => _isLoadingBadges = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Slider auto-play
  // ────────────────────────────────────────────────────────────────────────────
  void _startSliderAutoPlay() {
    _sliderTimer?.cancel();
    if (_sliderImages.length <= 1) return;
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_sliderPageController.hasClients) return;
      final next = (_currentSliderPage + 1) % _sliderImages.length;
      _sliderPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _openCategory(String url, String title, Color color) {
    if (url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(
          categoryUrl: url,
          categoryTitle: title,
          themeColor: color,
        ),
      ),
    );
  }

  Future<void> _loadStats() async {
    final p = await _db.countProducts();
    final s = await _db.countStores();
    final t = await _db.getLastSync();
    if (mounted) {
      setState(() {
        _productCount = p;
        _storeCount = s;
        _lastSync = t;
      });
    }
  }

  Future<void> _autoSync() async {
    if (await _db.needsSync()) await _doSync();
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoadingHome = true);
    try {
      final data = await WebScraperService.scrapeHomeData();
      if (mounted) {
        setState(() {
          _memberRanks = data.ranks;
          _categoryBanners = data.banners;
          _sliderImages = data.sliderImages;
          _totalPartners = data.totalPartners;
          if (data.totalProducts > 0) _productCount = data.totalProducts;
          if (data.totalStores > 0) _storeCount = data.totalStores;
          _isLoadingHome = false;
        });
        _startSliderAutoPlay();
      }
    } catch (e) {
      debugPrint('Lỗi load Home Data: $e');
      if (mounted) setState(() => _isLoadingHome = false);
    }
  }

  Future<void> _doSync() async {
    setState(() => _isSyncing = true);
    try {
      final products = await WebScraperService.scrapeAllCosmeticProducts();
      final stores = await WebScraperService.scrapeStores();
      final productMaps = products.map((p) => p.toMap()).toList();
      await _db.saveProducts(productMaps);
      await _db.saveStores(stores);
      await _db.setLastSync();
      await _loadStats();
      await _loadHomeData();
      await _loadHeaderBadges(); // ← Refresh badge khi sync
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            PhosphorIcon(PhosphorIcons.checkCircle(), color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Đã cập nhật ${products.length} sản phẩm!',
                  style: const TextStyle(color: Colors.white)),
            ),
          ]),
          backgroundColor: _green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange[800],
            content: Row(children: [
              PhosphorIcon(PhosphorIcons.warning(), color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Không thể sync, dùng dữ liệu offline',
                    style: TextStyle(color: Colors.white)),
              ),
            ]),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ── APP BAR ──
          SliverAppBar(
            backgroundColor: _green,
            pinned: true,
            elevation: 0,
            title: Text(
              'ANGEL LINH CHI',
              style: GoogleFonts.beVietnamPro(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              // ── Wishlist button ──
              _buildBadgeButton(
                icon: _buildWishlistIcon(),
                count: _wishlistCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WishlistScreen(),
                    ),
                  );
                },
              ),

              // ── Cart button ──
              _buildBadgeButton(
                icon: _buildCartIcon(),
                count: _cartCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),

              // ── Notification button ──
              _buildBadgeButton(
                icon: _buildNotifIcon(),
                count: _notifCount,
                onTap: () {
                  // TODO: mở màn hình thông báo
                },
              ),

              // ── Refresh / Sync button ──
              IconButton(
                icon: _isSyncing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isSyncing ? null : _doSync,
              ),
            ],
          ),

          // ── BODY ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsBanner(),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  'Hạng Thành Viên',
                  icon: PhosphorIcons.medal(),
                  iconColor: const Color(0xFFFFB300),
                ),
                const SizedBox(height: 12),
                MemberRanksWidget(
                  ranks: _memberRanks,
                  isLoading: _isLoadingHome,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Danh Mục Sản Phẩm',
                  icon: PhosphorIcons.shoppingBag(),
                  iconColor: const Color(0xFF6C63FF),
                ),
                const SizedBox(height: 12),
                CategoryBannersWidget(
                  banners: _categoryBanners,
                  isLoading: _isLoadingHome,
                  onTap: (url, title) {
                    final banner = _categoryBanners.firstWhere(
                          (b) => b.link == url,
                      orElse: () => CategoryBanner(
                        title: title,
                        imageUrl: '',
                        color: const Color(0xFF16A34A),
                        link: url,
                      ),
                    );
                    _openCategory(url, title, banner.color);
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Hình Ảnh Nổi Bật',
                  icon: PhosphorIcons.images(),
                  iconColor: const Color(0xFF00B8D9),
                ),
                const SizedBox(height: 12),
                _buildSliderBanner(),

                const SizedBox(height: 16),
                if (_lastSync != null) _buildSyncInfo(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Badge button wrapper — hiển thị số trên góc icon
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildBadgeButton({
    required Widget icon,
    required int count,
    required VoidCallback onTap,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: icon,
          onPressed: onTap,
          splashRadius: 22,
        ),
        if (count > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // ── Wishlist SVG (từ HTML gốc) ──
  Widget _buildWishlistIcon() {
    return SizedBox(
      width: 22,
      height: 20,
      child: CustomPaint(painter: _WishlistIconPainter()),
    );
  }

  // ── Cart SVG (từ HTML gốc) ──
  Widget _buildCartIcon() {
    return SizedBox(
      width: 21,
      height: 22,
      child: CustomPaint(painter: _CartIconPainter()),
    );
  }

  // ── Notification SVG (từ HTML gốc) ──
  Widget _buildNotifIcon() {
    return SizedBox(
      width: 21,
      height: 22,
      child: CustomPaint(painter: _NotifIconPainter()),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Stats banner
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildStatsBanner() {
    final productText = _isLoadingHome
        ? 'Đang tải...'
        : _productCount > 0
        ? '${_formatNumber(_productCount)} Sản phẩm'
        : '866 Sản phẩm';
    final storeText = _isLoadingHome
        ? 'Đang tải...'
        : _storeCount > 0
        ? '${_formatNumber(_storeCount)} Cửa hàng'
        : '34 Cửa hàng';
    final partnerText = _isLoadingHome
        ? 'Đang tải...'
        : '$_totalPartners thành viên';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 35),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_green, _darkGreen],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 20),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.eco, color: Colors.white, size: 80),
            ),
          ),
          Text(
            'ANGEL LINH CHI',
            style: GoogleFonts.beVietnamPro(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Hệ thống ghi nhận dữ liệu thực tế 24/7',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 16),
              children: [
                const TextSpan(text: 'Cộng đồng đối tác: '),
                TextSpan(
                  text: partnerText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statChip(productText, Icons.shopping_basket_outlined),
              const SizedBox(width: 12),
              _statChip(storeText, Icons.store_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Slider banner
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildSliderBanner() {
    final images = _sliderImages.isNotEmpty
        ? _sliderImages
        : WebScraperService.defaultSliderImages();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _sliderPageController,
            onPageChanged: (i) => setState(() => _currentSliderPage = i),
            itemCount: images.length,
            itemBuilder: (ctx, i) {
              final slide = images[i];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: slide.imageUrl.isNotEmpty
                      ? Image.network(
                    slide.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return _sliderPlaceholder();
                    },
                    errorBuilder: (_, __, ___) => _sliderPlaceholder(),
                  )
                      : _sliderPlaceholder(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (i) {
            final isActive = i == _currentSliderPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive ? _green : Colors.grey[300],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _sliderPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_green.withOpacity(0.3), _darkGreen.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: PhosphorIcon(
          PhosphorIcons.image(),
          size: 48,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Section header
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {required IconData icon, Color? iconColor}) {
    final color = iconColor ?? _green;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(child: PhosphorIcon(icon, size: 17, color: color)),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.beVietnamPro(
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        PhosphorIcon(PhosphorIcons.clockCounterClockwise(), size: 12, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          'Cập nhật lần cuối: ${_formatDate(_lastSync!)}',
          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
        ),
      ]),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────────────
  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ────────────────────────────────────────────────────────────────────────────
// SVG Icon Painters — giữ đúng SVG từ HTML gốc của website
// ────────────────────────────────────────────────────────────────────────────

/// Wishlist heart icon
class _WishlistIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Heart shape từ SVG gốc (viewBox 22x20)
    final sx = size.width / 22;
    final sy = size.height / 20;

    path.moveTo(11.239 * sx, 18.854 * sy);
    path.cubicTo(13.41 * sx, 17.518 * sy, 15.429 * sx, 15.946 * sy, 17.261 * sx, 14.165 * sy);
    path.cubicTo(18.549 * sx, 12.883 * sy, 19.529 * sx, 11.32 * sy, 20.127 * sx, 9.595 * sy);
    path.cubicTo(21.203 * sx, 6.25 * sy, 19.946 * sx, 2.421 * sy, 16.429 * sx, 1.288 * sy);
    path.cubicTo(14.58 * sx, 0.692 * sy, 12.562 * sx, 1.033 * sy, 11.004 * sx, 2.201 * sy);
    path.cubicTo(9.446 * sx, 1.034 * sy, 7.428 * sx, 0.694 * sy, 5.579 * sx, 1.288 * sy);
    path.cubicTo(2.062 * sx, 2.421 * sy, 0.796 * sx, 6.25 * sy, 1.872 * sx, 9.595 * sy);
    path.cubicTo(2.47 * sx, 11.32 * sy, 3.45 * sx, 12.883 * sy, 4.738 * sx, 14.165 * sy);
    path.cubicTo(6.57 * sx, 15.946 * sy, 8.589 * sx, 17.518 * sy, 10.76 * sx, 18.854 * sy);
    path.lineTo(10.995 * sx, 19 * sy);
    path.lineTo(11.239 * sx, 18.854 * sy);

    canvas.drawPath(path, paint);

    // Inner highlight line
    final path2 = Path();
    path2.moveTo(7.261 * sx, 5.053 * sy);
    path2.cubicTo(6.195 * sx, 5.393 * sy, 5.438 * sx, 6.35 * sy, 5.344 * sx, 7.475 * sy);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cart bag icon
class _CartIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final sx = size.width / 21;
    final sy = size.height / 22;

    // Bag body
    final bag = Path();
    bag.moveTo(6.486 * sx, 20.5 * sy);
    bag.lineTo(14.834 * sx, 20.5 * sy);
    bag.cubicTo(17.9 * sx, 20.5 * sy, 20.253 * sx, 19.392 * sy, 19.585 * sx, 14.935 * sy);
    bag.lineTo(18.807 * sx, 8.894 * sy);
    bag.cubicTo(18.395 * sx, 6.669 * sy, 16.976 * sx, 5.818 * sy, 15.731 * sx, 5.818 * sy);
    bag.lineTo(5.553 * sx, 5.818 * sy);
    bag.cubicTo(4.289 * sx, 5.818 * sy, 2.953 * sx, 6.733 * sy, 2.477 * sx, 8.894 * sy);
    bag.lineTo(1.699 * sx, 14.935 * sy);
    bag.cubicTo(1.132 * sx, 18.889 * sy, 3.42 * sx, 20.5 * sy, 6.486 * sx, 20.5 * sy);
    bag.close();
    canvas.drawPath(bag, paint);

    // Handle
    final handle = Path();
    handle.moveTo(6.349 * sx, 5.598 * sy);
    handle.cubicTo(6.349 * sx, 3.212 * sy, 8.283 * sx, 1.278 * sy, 10.669 * sx, 1.278 * sy);
    handle.cubicTo(11.818 * sx, 1.273 * sy, 12.922 * sx, 1.726 * sy, 13.736 * sx, 2.537 * sy);
    handle.cubicTo(14.55 * sx, 3.348 * sy, 15.008 * sx, 4.449 * sy, 15.008 * sx, 5.598 * sy);
    canvas.drawPath(handle, paint);

    // Dots
    canvas.drawCircle(Offset(7.727 * sx, 10.102 * sy), 1.5, paint..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(13.557 * sx, 10.102 * sy), 1.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bell notification icon
class _NotifIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final sx = size.width / 24;
    final sy = size.height / 24;

    // Bell body
    final bell = Path();
    bell.moveTo(10 * sx, 5 * sy);
    bell.cubicTo(10 * sx, 3.343 * sy, 11.343 * sx, 2 * sy, 13 * sx, 2 * sy);
    bell.cubicTo(14.657 * sx, 2 * sy, 16 * sx, 3.343 * sy, 16 * sx, 5 * sy);
    bell.cubicTo(18.761 * sx, 6.208 * sy, 20 * sx, 8.785 * sy, 20 * sx, 11 * sy);
    bell.lineTo(20 * sx, 14 * sy);
    bell.cubicTo(20 * sx, 15.105 * sy, 20.895 * sx, 15.895 * sy, 22 * sx, 17 * sy);
    bell.lineTo(4 * sx, 17 * sy);
    bell.cubicTo(5.105 * sx, 15.895 * sy, 6 * sx, 15.105 * sy, 6 * sx, 14 * sy);
    bell.lineTo(6 * sx, 11 * sy);
    bell.cubicTo(6 * sx, 8.785 * sy, 7.239 * sx, 6.208 * sy, 10 * sx, 5 * sy);
    canvas.drawPath(bell, paint);

    // Clapper
    final clapper = Path();
    clapper.moveTo(9 * sx, 17 * sy);
    clapper.lineTo(9 * sx, 18 * sy);
    clapper.cubicTo(9 * sx, 19.657 * sy, 10.343 * sx, 21 * sy, 12 * sx, 21 * sy);
    clapper.cubicTo(13.657 * sx, 21 * sy, 15 * sx, 19.657 * sy, 15 * sx, 18 * sy);
    clapper.lineTo(15 * sx, 17 * sy);
    canvas.drawPath(clapper, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}