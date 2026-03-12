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
  bool _isInjected = false;
  bool _isFavorite = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Color _green = const Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();

    debugPrint('🚀 [System] Khởi tạo màn hình chi tiết sản phẩm...');

    _isFavorite = (widget.product['isFavorite'] as int?) == 1;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    final productUrl = widget.product['productUrl'] as String? ?? '';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
    // Hứng log từ trình duyệt Web
      ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
        debugPrint('🌐 JS_LOG: ${message.message}');
      })
    // Kênh giao tiếp giữa Web và Flutter
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('📡 [Bridge] Nhận tin nhắn từ JS: ${message.message}');
          if (message.message == 'injected' && mounted) {
            setState(() {
              _isLoading = false;
              _isInjected = true;
            });
            _fadeController.forward();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('⏳ [WebView] Bắt đầu tải URL: $url');
            setState(() {
              _isLoading = true;
              _isInjected = false;
            });
          },
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageFinished: (url) {
            debugPrint('🏁 [WebView] Tải xong HTML. Đang đợi 500ms để inject...');
            if (!mounted) return;
            // Delay nhẹ để đảm bảo DOM của website Angel UniGreen đã render ổn định
            Future.delayed(const Duration(milliseconds: 500), () {
              _injectCleanScript();
            });
          },
          onWebResourceError: (error) {
            debugPrint('❌ [WebView] Lỗi tài nguyên: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(
        productUrl.isNotEmpty ? productUrl : 'https://angelunigreen.com.vn',
      ));
  }

  void _injectCleanScript() {
    debugPrint('💉 [Flutter] Đang thực thi runJavaScript...');

    const script = """
(function(){
  console.log('🚀 [JS] Script bắt đầu thực thi...');

  // 1. Inject CSS ngay lập tức để ẩn rác
  var css = 'header, footer, nav, .header-area, .footer-area, .breadcrumb, .breadcrumb__area, .site-footer, .related-products { display: none !important; }';
  var style = document.createElement('style');
  style.textContent = css;
  document.head.appendChild(style);
  console.log('✅ [JS] Đã chèn CSS ẩn Header/Footer');

  function clean(){
    console.log('🔍 [JS] Đang quét tìm class .tp-product-details-area...');
    var product = document.querySelector('.tp-product-details-area');
    
    if (!product) {
      console.log('⏳ [JS] Không tìm thấy vùng sản phẩm, thử lại sau 500ms...');
      setTimeout(clean, 500);
      return;
    }

    console.log('🎯 [JS] Đã tìm thấy nội dung! Đang tối ưu UI...');
    
    // Tối ưu body
    document.body.style.margin = '0';
    document.body.style.padding = '0';
    document.body.style.background = 'white';

    // Tạo Sticky Bar Mua Hàng
    var btn = document.querySelector('.single_add_to_cart_button');
    if (btn) {
      console.log('🛒 [JS] Đã tìm thấy nút Add to Cart gốc');
      var bar = document.createElement('div');
      bar.style = 'position:fixed;bottom:0;left:0;right:0;background:white;padding:12px;box-shadow:0 -3px 10px rgba(0,0,0,0.1);z-index:9999;display:flex;gap:10px;';
      
      var buy = btn.cloneNode(true);
      buy.style = 'flex:1;height:50px;border-radius:8px;font-weight:700;background:#00B894;color:white;border:none;';
      buy.onclick = function(){ btn.click(); };
      
      bar.appendChild(buy);
      document.body.appendChild(bar);
      product.style.paddingBottom = '90px';
    }

    // Gửi tín hiệu hoàn tất về Flutter
    if (window.FlutterBridge) {
      console.log('📡 [JS] Đang gửi tín hiệu "injected" về Flutter...');
      window.FlutterBridge.postMessage('injected');
    } else {
      console.error('❌ [JS] FlutterBridge không tồn tại!');
    }
  }

  clean();
})();
""";

    _webViewController.runJavaScript(script).catchError((e) {
      debugPrint('❌ [Flutter] Lỗi thực thi JS: $e');
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    debugPrint('🔄 [Flutter] Đang tải lại trang...');
    setState(() {
      _isInjected = false;
      _isLoading = true;
    });
    _fadeController.reset();
    await _webViewController.reload();
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.product['name'] as String? ?? 'Chi tiết sản phẩm';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(productName),
            if (_isLoading)
              LinearProgressIndicator(
                value: _loadingProgress / 100,
                minHeight: 3,
                backgroundColor: Colors.grey[100],
                valueColor: AlwaysStoppedAnimation<Color>(_green),
              ),
            Expanded(
              child: Stack(
                children: [
                  Opacity(
                    opacity: _isInjected ? 1.0 : 0.0,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: WebViewWidget(controller: _webViewController),
                    ),
                  ),
                  if (!_isInjected)
                    const Center(child: CircularProgressIndicator(color: Color(0xFF00B894))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String productName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          _iconBtn(icon: PhosphorIconsBold.arrowLeft, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              productName,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _iconBtn(
            icon: _isFavorite ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
            color: _isFavorite ? Colors.red : Colors.grey[600],
            onTap: () => setState(() => _isFavorite = !_isFavorite),
          ),
          _iconBtn(icon: PhosphorIconsBold.arrowClockwise, onTap: _reload),
        ],
      ),
    );
  }

  Widget _iconBtn({required IconData icon, Color? color, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(icon, size: 22, color: color ?? Colors.grey[700]),
      onPressed: onTap,
    );
  }
}