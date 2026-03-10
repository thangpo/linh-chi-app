import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late final WebViewController _webViewController;

  bool _isLoading = true;
  int _loadingProgress = 0;
  bool _isFavorite = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Color _green = const Color(0xFF00B894);

  @override
  void initState() {
    super.initState();

    _isFavorite = (widget.product['isFavorite'] as int?) == 1;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    final productUrl = widget.product['productUrl'] as String? ?? '';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _loadingProgress = 0;
              });
            }
          },
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageFinished: (url) {
            if (!mounted) return;

            setState(() => _isLoading = false);

            _fadeController.forward();
          },
          onWebResourceError: (error) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(
        productUrl.isNotEmpty ? productUrl : 'https://angelunigreen.com.vn',
      ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _fadeController.reset();
    await _webViewController.reload();
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.product['name'] as String? ?? 'Sản phẩm';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(productName),

            if (_isLoading)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _loadingProgress / 100),
                duration: const Duration(milliseconds: 200),
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value == 0 ? null : value,
                  minHeight: 3,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(_green),
                ),
              ),

            Expanded(
              child: Stack(
                children: [
                  FadeTransition(
                    opacity: _isLoading
                        ? const AlwaysStoppedAnimation(0.0)
                        : _fadeAnimation,
                    child: WebViewWidget(controller: _webViewController),
                  ),
                  if (_isLoading && _loadingProgress < 30)
                    _buildLoadingOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // APPBAR

  Widget _buildAppBar(String productName) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            _iconBtn(
              icon: PhosphorIconsBold.arrowLeft,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    productName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2E1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'angelunigreen.com.vn',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            _iconBtn(
              icon: _isFavorite
                  ? PhosphorIconsFill.heart
                  : PhosphorIconsRegular.heart,
              color: _isFavorite ? Colors.red : Colors.grey[600],
              onTap: () => setState(() => _isFavorite = !_isFavorite),
            ),
            _iconBtn(
              icon: PhosphorIconsBold.arrowClockwise,
              onTap: _reload,
            ),
          ],
        ),
      ),
    );
  }

  // LOADING

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsFill.leaf,
                color: Color(0xFF00B894),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Đang tải sản phẩm...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2E1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vui lòng đợi trong giây lát',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[100],
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF00B894)),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ICON BUTTON

  Widget _iconBtn({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 22, color: color ?? Colors.grey[700]),
      ),
    );
  }
}