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
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
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
            setState(() {
              _isLoading = true;
              _isInjected = false;
            });
          },
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageFinished: (url) {
            if (!mounted) return;
            _injectCleanScript();
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isInjected = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(
        productUrl.isNotEmpty ? productUrl : 'https://angelunigreen.com.vn',
      ));
  }

  void _injectCleanScript() {

    const script = """
(function(){

function clean(){

let product = document.querySelector('.tp-product-details-area');

if(!product){
setTimeout(clean,300);
return;
}

/* Ẩn layout website */
[
'header',
'footer',
'nav',
'.header-area',
'.footer-area',
'.breadcrumb',
'.tp-product-details-breadcrumb',
'.related-products',
'.upsell-products',
'.cross-sell',
'.bb-social-sharing',
'.comments-area',
'.woocommerce-Reviews',
'.product-reviews',
'.site-footer'
].forEach(sel=>{
document.querySelectorAll(sel).forEach(e=>{
e.style.display='none';
});
});

/* tối ưu body */
document.body.style.margin='0';
document.body.style.padding='0';
document.body.style.background='white';

/* tối ưu container */
document.querySelectorAll('.container').forEach(e=>{
e.style.maxWidth='100%';
e.style.padding='12px';
});

/* tối ưu ảnh */
document.querySelectorAll('img').forEach(img=>{
img.style.maxWidth='100%';
img.style.height='auto';
img.style.borderRadius='12px';
});

/* ===== Sticky add to cart ===== */

let btn = document.querySelector('.single_add_to_cart_button');

if(btn){

let bar = document.createElement('div');

bar.id='flutter-buy-bar';

bar.style.cssText = `
position:fixed;
bottom:0;
left:0;
right:0;
background:white;
padding:12px;
box-shadow:0 -3px 10px rgba(0,0,0,0.1);
z-index:9999;
display:flex;
gap:10px;
`;

let buy = btn.cloneNode(true);

buy.style.flex='1';
buy.style.height='50px';
buy.style.borderRadius='8px';
buy.style.fontWeight='700';

bar.appendChild(buy);

document.body.appendChild(bar);

/* click clone button => click original */

buy.onclick=function(){
btn.click();
}

}

/* padding bottom để không che content */

product.style.paddingBottom='90px';

FlutterBridge.postMessage('injected');

}

setTimeout(clean,700);

})();
""";

    _webViewController.runJavaScript(script);

  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _isInjected = false;
      _isLoading = true;
    });
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
                  Opacity(
                    opacity: _isInjected ? 1.0 : 0.0,
                    child: FadeTransition(
                      opacity: _isInjected
                          ? _fadeAnimation
                          : const AlwaysStoppedAnimation(0.0),
                      child: WebViewWidget(controller: _webViewController),
                    ),
                  ),
                  if (!_isInjected) _buildLoadingOverlay(),
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
              child: Text(
                productName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 22, color: color ?? Colors.grey),
      ),
    );
  }
}