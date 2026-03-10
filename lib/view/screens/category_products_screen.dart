import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:hisotech/services/scraper_service.dart';
import 'package:hisotech/view/screens/web_view_screen.dart';
import 'package:hisotech/view/widgets/skeleton_card.dart';
import 'package:hisotech/view/widgets/pagination_bar.dart';
import 'package:hisotech/view/widgets/product_card.dart';
import 'package:hisotech/view/widgets/product_states.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryUrl;
  final String categoryTitle;
  final Color? themeColor;

  const CategoryProductsScreen({
    Key? key,
    required this.categoryUrl,
    required this.categoryTitle,
    this.themeColor,
  }) : super(key: key);

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final List<Product> _products = [];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  bool _isLoadingFirst = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _paginationMode = true;

  Color get _color => widget.themeColor ?? const Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    _loadPage(1);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_paginationMode) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadNextPageInfinite();
    }
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      if (page == 1 || _paginationMode) {
        _isLoadingFirst = true;
        _hasError = false;
        _products.clear();
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final result = await WebScraperService.scrapeProductsByUrl(
        url: widget.categoryUrl,
        page: page,
      );

      if (mounted) {
        setState(() {
          _products.addAll(result.products);
          _currentPage = result.currentPage;
          _totalPages = result.totalPages;
          _totalItems = result.totalItems;
          _isLoadingFirst = false;
          _isLoadingMore = false;
        });

        if (_paginationMode && _scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi load trang $page: $e');
      if (mounted) {
        setState(() {
          _isLoadingFirst = false;
          _isLoadingMore = false;
          if (page == 1) _hasError = true;
        });
      }
    }
  }

  void _loadNextPageInfinite() {
    if (!_isLoadingMore && _currentPage < _totalPages) {
      _loadPage(_currentPage + 1);
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _loadPage(page);
  }

  void _openProduct(Product product) {
    if (product.productUrl.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewScreen(
          url: product.productUrl,
          title: product.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _color,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Column(
        children: [
          Text(
            widget.categoryTitle,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_totalItems > 0)
            Text(
              '$_totalItems sản phẩm',
              style: GoogleFonts.beVietnamPro(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: _paginationMode ? 'Chuyển cuộn vô hạn' : 'Chuyển phân trang',
          icon: Icon(
            _paginationMode ? Icons.view_stream_outlined : Icons.grid_view,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => setState(() => _paginationMode = !_paginationMode),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => _loadPage(1),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoadingFirst) return _buildSkeletonGrid();
    if (_hasError) return ProductErrorState(color: _color, onRetry: () => _loadPage(1));
    if (_products.isEmpty) return const ProductEmptyState();

    return RefreshIndicator(
      color: _color,
      onRefresh: () => _loadPage(1),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildSummaryBar()),
          _buildProductGrid(),
          SliverToBoxAdapter(child: _buildFooter()),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: _gridDelegate,
        itemCount: 6,
        itemBuilder: (_, __) => const SkeletonCard(),
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.shoppingBag(), size: 15, color: _color),
          const SizedBox(width: 8),
          Text(
            _paginationMode
                ? 'Trang $_currentPage / $_totalPages  •  ${_products.length} sản phẩm'
                : 'Hiển thị ${_products.length}${_totalItems > 0 ? ' / $_totalItems' : ''} sản phẩm',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }

  SliverPadding _buildProductGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
              (ctx, i) => ProductCard(
            product: _products[i],
            themeColor: _color,
            onTap: () => _openProduct(_products[i]),
          ),
          childCount: _products.length,
        ),
        gridDelegate: _gridDelegate,
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: _paginationMode
          ? (_totalPages > 1
          ? PaginationBar(
        currentPage: _currentPage,
        totalPages: _totalPages,
        color: _color,
        onPageTap: _goToPage,
      )
          : const SizedBox.shrink())
          : (_isLoadingMore
          ? Center(
        child: CircularProgressIndicator(
          color: _color,
          strokeWidth: 2.5,
        ),
      )
          : _currentPage >= _totalPages
          ? Center(
        child: Text(
          'Đã hiển thị tất cả sản phẩm',
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      )
          : const SizedBox.shrink()),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount get _gridDelegate =>
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      );
}