import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hisotech/services/database_service.dart';
import 'package:hisotech/services/scraper_service.dart';
import 'package:hisotech/view/widgets/member_ranks_widget.dart';
import 'package:hisotech/view/widgets/category_banners_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:hisotech/view/screens/category_products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseService();
  int _productCount = 0;
  int _storeCount = 0;
  bool _isSyncing = false;
  bool _isLoadingHome = true;
  String? _lastSync;
  int _totalPartners = 950;
  List<MemberRank> _memberRanks = [];
  List<CategoryBanner> _categoryBanners = [];
  List<SliderImage> _sliderImages = [];
  late PageController _sliderPageController;
  int _currentSliderPage = 0;
  Timer? _sliderTimer;
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
  }

  @override
  void dispose() {
    _sliderPageController.dispose();
    _sliderTimer?.cancel();
    super.dispose();
  }

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
    if (mounted)
      setState(() {
        _productCount = p;
        _storeCount = s;
        _lastSync = t;
      });
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
      final productMaps = products.map((p) => p.toMap()).toList(); // Product → Map
      await _db.saveProducts(productMaps);
      await _db.saveStores(stores);
      await _db.setLastSync();
      await _loadStats();
      await _loadHomeData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            PhosphorIcon(PhosphorIcons.checkCircle(),
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Đã cập nhật ${products.length} sản phẩm!',
                    style: const TextStyle(color: Colors.white)))
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
              PhosphorIcon(PhosphorIcons.warning(),
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Không thể sync, dùng dữ liệu offline',
                      style: TextStyle(color: Colors.white))),
            ]),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
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
              IconButton(
                icon: _isSyncing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isSyncing ? null : _doSync,
              ),
            ],
          ),
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

                // ✅ Đã tách thành widget riêng – dễ nâng cấp / test độc lập
                CategoryBannersWidget(
                  banners: _categoryBanners,
                  isLoading: _isLoadingHome,
                  onTap: (url, title) {
                    // Tìm màu của banner tương ứng
                    final banner = _categoryBanners.firstWhere(
                          (b) => b.link == url,
                      orElse: () => CategoryBanner(
                        title: title, imageUrl: '', color: const Color(0xFF16A34A), link: url,
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

  // -------------------------------------------------------------------------
  // Stats banner
  // -------------------------------------------------------------------------

  Widget _buildStatsBanner() {
    String productText;
    String storeText;
    String partnerText;

    if (_isLoadingHome) {
      productText = "Đang tải...";
      storeText = "Đang tải...";
      partnerText = "Đang tải...";
    } else {
      productText = _productCount > 0
          ? '${_formatNumber(_productCount)} Sản phẩm'
          : '866 Sản phẩm';
      storeText = _storeCount > 0
          ? '${_formatNumber(_storeCount)} Cửa hàng'
          : '34 Cửa hàng';
      partnerText = _productCount > 0
          ? '$_totalPartners thành viên'
          : '1147 thành viên';
    }

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
              style: GoogleFonts.beVietnamPro(
                  color: Colors.white, fontSize: 16),
              children: [
                const TextSpan(text: 'Cộng đồng đối tác: '),
                TextSpan(
                  text: partnerText,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
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
        border:
        Border.all(color: Colors.white.withOpacity(0.4), width: 1),
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

  // -------------------------------------------------------------------------
  // Slider banner
  // -------------------------------------------------------------------------

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
                    errorBuilder: (_, __, ___) =>
                        _sliderPlaceholder(),
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
          colors: [
            _green.withOpacity(0.3),
            _darkGreen.withOpacity(0.5)
          ],
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

  // -------------------------------------------------------------------------
  // Section header
  // -------------------------------------------------------------------------

  Widget _buildSectionHeader(String title,
      {required IconData icon, Color? iconColor}) {
    final color = iconColor ?? _green;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: PhosphorIcon(icon, size: 17, color: color),
            ),
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
        PhosphorIcon(PhosphorIcons.clockCounterClockwise(),
            size: 12, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text('Cập nhật lần cuối: ${_formatDate(_lastSync!)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
      ]),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

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