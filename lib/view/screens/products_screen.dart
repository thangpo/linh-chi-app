import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hisotech/services/database_service.dart';
import 'package:hisotech/services/scraper_service.dart';
import 'package:hisotech/view/screens/product_detail_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _databaseService = DatabaseService();

  Timer? _searchDebounce;

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String _loadingMessage = 'Đang kết nối...';
  String _selectedCategory = 'Tất cả';
  String _errorMessage = '';
  String _searchQuery = '';

  int _productsVersion = 0;
  int _lastFilterVersion = -1;
  String _lastFilterCategory = '';
  String _lastFilterQuery = '';
  List<Map<String, dynamic>> _filteredCache = const [];

  int _lastCategoryVersion = -1;
  List<String> _categoriesCache = const ['Tất cả'];

  final Color _green = const Color(0xFF16A34A);
  final Color _greenDark = const Color(0xFF15803D);

  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadProducts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _shimmerController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final hadDataBeforeLoad = _products.isNotEmpty;

    setState(() {
      _isLoading = !hadDataBeforeLoad;
      _isRefreshing = hadDataBeforeLoad;
      _errorMessage = '';
      _loadingMessage = hadDataBeforeLoad
          ? 'Đang cập nhật dữ liệu mới...'
          : 'Đang kết nối website...';
    });

    if (!hadDataBeforeLoad) {
      try {
        final cachedProducts = await _databaseService.getProducts();
        if (mounted && cachedProducts.isNotEmpty) {
          setState(() {
            _setProducts(cachedProducts);
            _isLoading = false;
            _isRefreshing = true;
            _loadingMessage = 'Đang đồng bộ dữ liệu mới từ website...';
          });
        }
      } catch (_) {
        // Không chặn luồng online
      }
    }

    try {
      final products = await ScrapingService.scrapeProducts(
        onProgress: (msg) {
          if (mounted) {
            setState(() => _loadingMessage = msg);
          }
        },
      );

      if (!mounted) return;

      if (products.isNotEmpty) {
        await _databaseService.saveProducts(products);
      }

      setState(() {
        _setProducts(products);
        _isLoading = false;
        _isRefreshing = false;
        if (products.isEmpty) {
          _errorMessage = 'Không tìm thấy sản phẩm nào.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        if (_products.isEmpty) {
          _errorMessage = 'Lỗi tải dữ liệu: $e';
        }
      });
    }
  }

  void _setProducts(List<Map<String, dynamic>> products) {
    _products = products;
    _productsVersion++;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final query = value.trim().toLowerCase();
      if (query == _searchQuery) return;
      setState(() => _searchQuery = query);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (_searchQuery.isNotEmpty) {
      setState(() => _searchQuery = '');
    }
  }

  List<String> get _categories {
    if (_lastCategoryVersion == _productsVersion) {
      return _categoriesCache;
    }

    final cats = <String>{'Tất cả'};
    for (var p in _products) {
      final cat = p['category'] as String? ?? '';
      if (cat.isNotEmpty) cats.add(cat);
    }

    _categoriesCache = cats.toList();
    _lastCategoryVersion = _productsVersion;
    return _categoriesCache;
  }

  List<Map<String, dynamic>> get _filtered {
    if (_lastFilterVersion == _productsVersion &&
        _lastFilterCategory == _selectedCategory &&
        _lastFilterQuery == _searchQuery) {
      return _filteredCache;
    }

    var list = _products;
    if (_selectedCategory != 'Tất cả') {
      list = list.where((p) => p['category'] == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
    }

    _lastFilterVersion = _productsVersion;
    _lastFilterCategory = _selectedCategory;
    _lastFilterQuery = _searchQuery;
    _filteredCache = list;

    return _filteredCache;
  }

  void _toggleFavorite(Map<String, dynamic> product) {
    setState(() {
      final idx = _products.indexWhere((p) => p['id'] == product['id']);
      if (idx != -1) {
        final current = (_products[idx]['isFavorite'] as int?) == 1;
        _products[idx] = {..._products[idx], 'isFavorite': current ? 0 : 1};
        _productsVersion++;
      }
    });
  }

  void _openProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    ).then((result) {
      if (result != null && result is Map) {
        final idx = _products.indexWhere((p) => p['id'] == product['id']);
        if (idx != -1 && mounted) {
          setState(() {
            _products[idx] = {..._products[idx], ...result};
            _productsVersion++;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showInitialLoading = _isLoading && _products.isEmpty;
    final showError = _errorMessage.isNotEmpty && _products.isEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _green,
        elevation: 0,
        title: Text(
          'Sản Phẩm UniGreen',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
              color: Colors.white,
            ),
            tooltip: 'Tải lại',
            onPressed: (_isLoading || _isRefreshing) ? null : _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: _green,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
                  color: Colors.grey[500],
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          PhosphorIcons.x(PhosphorIconsStyle.bold),
                          color: Colors.grey[500],
                          size: 18,
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!_isLoading && _products.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _categories.length,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      if (_selectedCategory != cat) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? _green : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _green : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.plusJakartaSans(
                          color: selected ? Colors.white : Colors.grey[700],
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_isRefreshing && _products.isNotEmpty) _buildRefreshingBanner(),
          Expanded(
            child: showInitialLoading
                ? _buildLoadingView()
                : showError
                    ? _buildErrorView()
                    : _filtered.isEmpty
                        ? _buildEmptyView()
                        : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshingBanner() {
    return Container(
      width: double.infinity,
      color: _green.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadingMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _greenDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: _green.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration:
                      BoxDecoration(color: _green, shape: BoxShape.circle),
                  child: Icon(
                    PhosphorIcons.cloudArrowDown(PhosphorIconsStyle.fill),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang cào dữ liệu từ website',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: _greenDark,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _loadingMessage,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_green),
          minHeight: 3,
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => _shimmerCard(),
          ),
        ),
      ],
    );
  }

  Widget _shimmerCard() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        final stops = [
          (_shimmerController.value - 0.3).clamp(0.0, 1.0),
          _shimmerController.value.clamp(0.0, 1.0),
          (_shimmerController.value + 0.3).clamp(0.0, 1.0),
        ];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 130,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.grey[200]!,
                        Colors.grey[100]!,
                        Colors.grey[200]!
                      ],
                      stops: stops,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerLine(width: double.infinity, height: 12),
                    const SizedBox(height: 6),
                    _shimmerLine(width: 120, height: 12),
                    const SizedBox(height: 8),
                    _shimmerLine(width: 80, height: 14),
                    const SizedBox(height: 8),
                    _shimmerLine(width: 60, height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerLine({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
            stops: [
              (_shimmerController.value - 0.3).clamp(0.0, 1.0),
              _shimmerController.value.clamp(0.0, 1.0),
              (_shimmerController.value + 0.3).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.wifiX(PhosphorIconsStyle.duotone),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _loadProducts,
              icon: Icon(
                PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
                size: 18,
              ),
              label: Text(
                'Thử lại',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.shoppingBag(PhosphorIconsStyle.duotone),
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy sản phẩm',
            style: GoogleFonts.plusJakartaSans(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final filtered = _filtered;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Icon(
                PhosphorIcons.package(PhosphorIconsStyle.duotone),
                size: 14,
                color: _green,
              ),
              const SizedBox(width: 6),
              Text(
                '${filtered.length} sản phẩm',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'angelunigreen.com.vn',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => _productCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final isFav = (product['isFavorite'] as int?) == 1;
    final imageUrl = product['imageUrl'] as String? ?? '';
    final isOutOfStock = (product['isOutOfStock'] as int?) == 1;
    final originalPrice = product['originalPrice'] as String? ?? '';
    final discountPercent = product['discountPercent'] as String? ?? '';
    final soldCount = product['soldCount'] as String? ?? '';
    final location = product['location'] as String? ?? '';

    return GestureDetector(
      onTap: () => _openProduct(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _imageLoadingPlaceholder(),
                          errorWidget: (_, __, ___) => _imagePlaceholder(),
                          memCacheHeight: 300,
                          memCacheWidth: 300,
                        )
                      : _imagePlaceholder(),
                ),
                if (isOutOfStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Hết hàng',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (discountPercent.isNotEmpty && !isOutOfStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        discountPercent,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(product),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav
                            ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                            : PhosphorIcons.heart(PhosphorIconsStyle.regular),
                        size: 18,
                        color: isFav ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          product['price'] as String? ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            color: _green,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        if (originalPrice.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              originalPrice,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.grey[400],
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (soldCount.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.shoppingCart(
                              PhosphorIconsStyle.regular,
                            ),
                            size: 10,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Đã bán $soldCount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.mapPin(PhosphorIconsStyle.regular),
                            size: 10,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (product['category'] as String? ?? '').isNotEmpty
                            ? product['category'] as String
                            : 'UniGreen',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: _green,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageLoadingPlaceholder() {
    return Container(
      height: 130,
      width: double.infinity,
      color: Colors.grey[100],
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _green,
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 130,
      width: double.infinity,
      color: Colors.grey[100],
      child: Icon(
        PhosphorIcons.leaf(PhosphorIconsStyle.fill),
        size: 48,
        color: const Color(0xFF16A34A),
      ),
    );
  }
}
