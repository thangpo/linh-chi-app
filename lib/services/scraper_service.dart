import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;

class SliderImage {
  final String imageUrl;
  SliderImage({required this.imageUrl});
}

class MemberRank {
  final String name;
  final int memberCount;
  final String imageUrl;
  final List<Color> gradientColors;

  MemberRank({
    required this.name,
    required this.memberCount,
    required this.imageUrl,
    required this.gradientColors,
  });
}

class CategoryBanner {
  final String title;
  final String imageUrl;
  final Color color;
  final String link;

  CategoryBanner({
    required this.title,
    required this.imageUrl,
    required this.color,
    required this.link,
  });
}

class HomeData {
  final List<MemberRank> ranks;
  final List<CategoryBanner> banners;
  final List<SliderImage> sliderImages;
  final int totalPartners;
  final int totalProducts;
  final int totalStores;

  HomeData({
    required this.ranks,
    required this.banners,
    required this.sliderImages,
    required this.totalPartners,
    this.totalProducts = 0,
    this.totalStores = 0,
  });
}

class Product {
  final String id;
  final String name;
  final String price;
  final String originalPrice;
  final String discountPercent;
  final String imageUrl;
  final String productUrl;
  final String category;
  final String soldCount;
  final String location;
  final String ratingText;
  final bool isOutOfStock;
  final String sku;
  final int isFavorite;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice = '',
    this.discountPercent = '',
    required this.imageUrl,
    required this.productUrl,
    required this.category,
    this.soldCount = '',
    this.location = '',
    this.ratingText = '',
    this.isOutOfStock = false,
    this.sku = '',
    this.isFavorite = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'originalPrice': originalPrice,
    'discountPercent': discountPercent,
    'imageUrl': imageUrl,
    'productUrl': productUrl,
    'category': category,
    'soldCount': soldCount,
    'location': location,
    'ratingText': ratingText,
    'isOutOfStock': isOutOfStock ? 1 : 0,
    'sku': sku,
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  String toString() =>
      'Product(name: $name, price: $price, sold: $soldCount, outOfStock: $isOutOfStock)';
}

class ProductPageResult {
  final List<Product> products;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  ProductPageResult({
    required this.products,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });
}

class WebScraperService {
  static const String websiteUrl = 'https://angelunigreen.com.vn';
  static const String cosmeticsUrl =
      '$websiteUrl/danh-muc-san-pham/h%C3%B3a-m%E1%BB%B9-ph%E1%BA%A9m-unigreen';

  static final Map<String, String> _headers = {
    'User-Agent':
    'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15',
    'Accept':
    'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'vi-VN,vi;q=0.9,en;q=0.8',
  };

  static Future<List<Map<String, dynamic>>> scrapeProducts({
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Đang kết nối website...');
    final allProducts = <Map<String, dynamic>>[];

    try {
      onProgress?.call('Đang tải trang đầu tiên...');
      final firstResult = await scrapeCosmeticProductsPage(page: 1);
      allProducts.addAll(firstResult.products.map((p) => p.toMap()));

      final total = firstResult.totalPages;
      onProgress?.call('Trang 1/$total — ${firstResult.products.length} sản phẩm');

      for (int pageStart = 2; pageStart <= total; pageStart += 3) {
        final batch = <Future<ProductPageResult>>[];
        for (int p = pageStart; p < pageStart + 3 && p <= total; p++) {
          batch.add(scrapeCosmeticProductsPage(page: p));
        }
        final results = await Future.wait(batch);
        for (final r in results) {
          allProducts.addAll(r.products.map((p) => p.toMap()));
          onProgress?.call(
              'Trang ${r.currentPage}/$total — ${allProducts.length} sản phẩm');
        }
      }

      onProgress?.call('Hoàn tất! Tìm thấy ${allProducts.length} sản phẩm');
    } catch (e) {
      debugPrint('❌ Lỗi scrapeProducts: $e');
      onProgress?.call('Lỗi kết nối, dùng dữ liệu dự phòng');
      return _fallbackProducts().map((p) => p.toMap()).toList();
    }

    return allProducts.isNotEmpty
        ? allProducts
        : _fallbackProducts().map((p) => p.toMap()).toList();
  }

  /// Cào TẤT CẢ sản phẩm từ nhiều trang (tự động phân trang)
  static Future<List<Product>> scrapeAllCosmeticProducts() async {
    final allProducts = <Product>[];

    try {
      // Lấy trang đầu để biết tổng số trang
      final firstResult = await scrapeCosmeticProductsPage(page: 1);
      allProducts.addAll(firstResult.products);

      debugPrint(
          '✅ Trang 1/${firstResult.totalPages} — ${firstResult.products.length} sản phẩm');

      // Lấy các trang còn lại song song (nhóm 3 trang để tránh bị block)
      for (int pageStart = 2;
      pageStart <= firstResult.totalPages;
      pageStart += 3) {
        final batch = <Future<ProductPageResult>>[];
        for (int p = pageStart;
        p < pageStart + 3 && p <= firstResult.totalPages;
        p++) {
          batch.add(scrapeCosmeticProductsPage(page: p));
        }

        final results = await Future.wait(batch);
        for (final r in results) {
          allProducts.addAll(r.products);
          debugPrint(
              '✅ Trang ${r.currentPage}/${firstResult.totalPages} — ${r.products.length} sản phẩm');
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi cào toàn bộ sản phẩm: $e');
    }

    debugPrint('🎯 Tổng: ${allProducts.length} sản phẩm đã cào được');
    return allProducts.isNotEmpty ? allProducts : _fallbackProducts();
  }

  /// Cào sản phẩm từ MỘT trang cụ thể (mặc định trang 1)
  static Future<ProductPageResult> scrapeCosmeticProductsPage({
    int page = 1,
  }) async {
    try {
      final url = page == 1 ? cosmeticsUrl : '$cosmeticsUrl?page=$page';

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        debugPrint('⚠️ HTTP ${response.statusCode} trang $page');
        return ProductPageResult(
          products: page == 1 ? _fallbackProducts() : [],
          currentPage: page,
          totalPages: 1,
          totalItems: 0,
        );
      }

      final document = htmlParser.parse(response.body);
      final products = _parseProductCards(document);

      // Lấy thông tin phân trang
      final pagination = _parsePagination(document);

      return ProductPageResult(
        products: products,
        currentPage: page,
        totalPages: pagination['totalPages']!,
        totalItems: pagination['totalItems']!,
      );
    } catch (e) {
      debugPrint('❌ Lỗi cào trang $page: $e');
      return ProductPageResult(
        products: page == 1 ? _fallbackProducts() : [],
        currentPage: page,
        totalPages: 1,
        totalItems: 0,
      );
    }
  }

  /// Parse danh sách sản phẩm từ document HTML
  static List<Product> _parseProductCards(dom.Document document) {
    final products = <Product>[];

    List<dom.Element> items = document.querySelectorAll('.tp-product-item-5');
    if (items.isEmpty) items = document.querySelectorAll('.product-card');
    if (items.isEmpty) items = document.querySelectorAll('li.product');
    if (items.isEmpty) items = document.querySelectorAll('.product');

    debugPrint('🔍 Tìm thấy ${items.length} product card(s)');

    for (var i = 0; i < items.length; i++) {
      final elem = items[i];
      try {
        final name = elem.querySelector('.product-title')?.text.trim() ??
            elem.querySelector('.woocommerce-loop-product__title')?.text.trim() ??
            elem.querySelector('h3 a')?.text.trim() ??
            elem.querySelector('h2')?.text.trim() ??
            '';
        if (name.isEmpty) continue;

        final productUrl =
            elem.querySelector('a.product-title')?.attributes['href'] ??
                elem.querySelector('h3 a')?.attributes['href'] ??
                elem.querySelector('a')?.attributes['href'] ??
                '';

        final imgElem = elem.querySelector('.tp-product-thumb-5 img') ??
            elem.querySelector('img');
        final imageUrl = imgElem?.attributes['src'] ??
            imgElem?.attributes['data-src'] ??
            imgElem?.attributes['data-lazy-src'] ??
            '';

        final price =
            elem.querySelector('.tp-product-price-5.new-price')?.text.trim() ??
                elem.querySelector('.new-price')?.text.trim() ??
                elem.querySelector('.price')?.text.trim() ??
                'Liên hệ';

        final originalPrice = elem.querySelector('.old-price')?.text.trim() ?? '';

        // ✅ FIX: dùng .product-sale thay vì .product-discount
        final discountPercent =
            elem.querySelector('.tp-product-badge .product-sale')?.text.trim() ?? '';

        // ✅ FIX: kiểm tra out-of-stock
        final isOutOfStock = elem.querySelector('.product-out-stock') != null;

        // ✅ FIX: sold count clean whitespace/newline
        final soldCount = elem
            .querySelector('.sold-count span')
            ?.text
            .replaceAll('Đã bán', '')
            .replaceAll(RegExp(r'\s+'), '')
            .trim() ??
            '';

        // ✅ FIX: location lấy đúng span, loại bỏ khoảng trắng dư
        final location = elem
            .querySelector('.location > span')
            ?.text
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim() ??
            '';

        final ratingText =
            elem.querySelector('.tp-product-rating-text a span')?.text.trim() ?? '';

        final sku = elem
            .querySelector('[data-product-sku]')
            ?.attributes['data-product-sku'] ??
            '';

        final dataId = elem
            .querySelector('[data-product-id]')
            ?.attributes['data-product-id'] ??
            '';
        final id = dataId.isNotEmpty ? 'p-$dataId' : 'p-$i';

        final category = elem
            .querySelector('[data-product-category]')
            ?.attributes['data-product-category'] ??
            elem.querySelector('.product-category')?.text.trim() ??
            'HÓA - MỸ PHẨM UNIGREEN';

        products.add(Product(
          id: id,
          name: name,
          price: _cleanPrice(price),
          originalPrice: _cleanPrice(originalPrice),
          discountPercent: discountPercent,
          imageUrl: _normalizeUrl(imageUrl),
          productUrl: _normalizeUrl(productUrl),
          category: category,
          soldCount: soldCount,
          location: location,
          ratingText: ratingText,
          isOutOfStock: isOutOfStock,
          sku: sku,
          isFavorite: 0,
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('⚠️ Lỗi parse card #$i: $e');
      }
    }

    return products;
  }

  /// Parse thông tin phân trang
  static Map<String, int> _parsePagination(dom.Document document) {
    int totalPages = 1;
    int totalItems = 0;

    try {
      // Đọc tổng số sản phẩm từ text kết quả
      final resultText =
          document.querySelector('.tp-shop-top-result p')?.text ??
              document.querySelector('.woocommerce-result-count')?.text ??
              '';

      final itemMatches = RegExp(r'(\d+)').allMatches(resultText).toList();
      if (itemMatches.isNotEmpty) {
        totalItems = int.tryParse(itemMatches.last.group(0)!) ?? 0;
      }

      // Đọc trang cuối từ pagination
      final lastPageElem = document.querySelector(
          '.tp-pagination .page-numbers:not(.next):not(.prev):last-child') ??
          document.querySelector('.pagination .page-link:last-of-type');

      if (lastPageElem != null) {
        final pageNum =
        int.tryParse(lastPageElem.text.trim().replaceAll(RegExp(r'\D'), ''));
        if (pageNum != null) totalPages = pageNum;
      }

      // Fallback: tính từ tổng sản phẩm / 12 mỗi trang
      if (totalPages == 1 && totalItems > 12) {
        totalPages = (totalItems / 12).ceil();
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi parse phân trang: $e');
    }

    return {'totalPages': totalPages, 'totalItems': totalItems};
  }

  // ────────────────────────────────────────
  // SLIDER ẢNH TRANG CHỦ
  // ────────────────────────────────────────

  static Future<List<SliderImage>> scrapeSliderImages() async {
    try {
      final response = await http
          .get(Uri.parse(websiteUrl), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return _defaultSliderImages();

      final document = htmlParser.parse(response.body);
      final slides = document.querySelectorAll(
          '.slider .slide-track .slide:not(.swiper-slide-duplicate)');
      final seen = <String>{};
      final images = <SliderImage>[];

      for (final slide in slides) {
        final img = slide.querySelector('img');
        final src = img?.attributes['src'] ??
            img?.attributes['data-src'] ??
            img?.attributes['data-lazy-src'] ??
            '';

        if (src.isNotEmpty) {
          final normalized = _normalizeUrl(src);
          if (seen.add(normalized)) {
            images.add(SliderImage(imageUrl: normalized));
          }
        }
      }

      return images.isNotEmpty ? images : _defaultSliderImages();
    } catch (e) {
      debugPrint('❌ Lỗi cào slider: $e');
      return _defaultSliderImages();
    }
  }

  // ────────────────────────────────────────
  // CỬA HÀNG
  // ────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> scrapeStores() async {
    try {
      int total = await _scrapeTotalStores();
      if (total == 0) total = 32;
      final int itemsPerPage = 12;
      final int totalPages = (total / itemsPerPage).ceil();
      final List<Map<String, dynamic>> allStores = [];

      for (int page = 1; page <= totalPages; page++) {
        final url = '$websiteUrl/cua-hang?page=$page';
        final res = await http
            .get(Uri.parse(url), headers: _headers)
            .timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) continue;

        final doc = htmlParser.parse(res.body);
        final items = doc.querySelectorAll('.tp-shop-item').isNotEmpty
            ? doc.querySelectorAll('.tp-shop-item')
            : doc.querySelectorAll('.shop-item');

        for (var item in items) {
          final name = item.querySelector('.tp-shop-title')?.text.trim() ??
              item.querySelector('h3')?.text.trim() ??
              'Cửa hàng Angel';

          final address =
              item.querySelector('.tp-shop-address')?.text.trim() ??
                  item.querySelector('.address')?.text.trim() ??
                  'Đang cập nhật';

          final phone = item.querySelector('.tp-shop-phone')?.text.trim() ??
              item.querySelector('.phone')?.text.trim() ??
              '';

          allStores.add({
            'id': 'store-${allStores.length}',
            'name': name,
            'address': address,
            'phone': phone,
            'hours': '08:00 - 21:00',
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }

      return allStores.isNotEmpty ? allStores : _fallbackStores();
    } catch (e) {
      debugPrint('❌ Lỗi lấy cửa hàng: $e');
      return _fallbackStores();
    }
  }

  // ────────────────────────────────────────
  // HẠNG THÀNH VIÊN
  // ────────────────────────────────────────

  static Future<List<MemberRank>> scrapeMemberRanks() async {
    try {
      final response = await http
          .get(Uri.parse(websiteUrl), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return _defaultRanks();

      final document = htmlParser.parse(response.body);
      final ranks = <MemberRank>[];

      final allSlides = document
          .querySelectorAll('.swiper-slide:not(.swiper-slide-duplicate)');

      var cards = allSlides.isNotEmpty
          ? allSlides
          .map((s) => s.querySelector('.rank-premium-card'))
          .whereType<dom.Element>()
          .toList()
          : document.querySelectorAll('.rank-premium-card');

      if (cards.isEmpty) return _defaultRanks();

      for (var i = 0; i < cards.length; i++) {
        final card = cards[i];
        final name = card.querySelector('.rank-name-v2')?.text.trim() ?? '';
        final countText =
            card.querySelector('.rank-count-v2 .num')?.text.trim() ?? '0';
        final count =
            int.tryParse(countText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final imgTag = card.querySelector('.rank-main-img');
        final imageUrl =
            imgTag?.attributes['src'] ?? imgTag?.attributes['data-src'] ?? '';
        if (name.isEmpty) continue;

        ranks.add(MemberRank(
          name: name,
          memberCount: count,
          imageUrl: _normalizeUrl(imageUrl),
          gradientColors: _rankColors(i),
        ));
      }

      return ranks.isNotEmpty ? ranks : _defaultRanks();
    } catch (e) {
      return _defaultRanks();
    }
  }

  // ────────────────────────────────────────
  // BANNER DANH MỤC
  // ────────────────────────────────────────

  static Future<List<CategoryBanner>> scrapeCategoryBanners() async {
    try {
      final response = await http
          .get(Uri.parse(websiteUrl), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return _defaultBanners();

      final document = htmlParser.parse(response.body);
      final banners = <CategoryBanner>[];
      final elements =
      document.querySelectorAll('.ecommerce-modern-categories__item');
      final colors = [
        const Color(0xFF2E7D32),
        const Color(0xFF00695C),
        const Color(0xFF1B5E20),
        const Color(0xFF33691E),
      ];

      for (var i = 0; i < elements.length; i++) {
        final elem = elements[i];
        final title = elem
            .querySelector('.ecommerce-modern-categories__title')
            ?.text
            .trim() ??
            '';
        final imgTag =
        elem.querySelector('.ecommerce-modern-categories__thumb img');
        final imageUrl = imgTag?.attributes['src'] ??
            imgTag?.attributes['data-src'] ??
            '';
        final link = elem.querySelector('a')?.attributes['href'] ?? '';
        if (title.isEmpty) continue;
        banners.add(CategoryBanner(
          title: title,
          imageUrl: _normalizeUrl(imageUrl),
          color: colors[i % colors.length],
          link: _normalizeUrl(link),
        ));
      }

      return banners.isNotEmpty ? banners : _defaultBanners();
    } catch (e) {
      debugPrint('❌ Lỗi cào danh mục: $e');
      return _defaultBanners();
    }
  }

  // ────────────────────────────────────────
  // HOME DATA GỘP
  // ────────────────────────────────────────

  static Future<HomeData> scrapeHomeData() async {
    try {
      final results = await Future.wait([
        http
            .get(Uri.parse(websiteUrl), headers: _headers)
            .timeout(const Duration(seconds: 15)),
        _scrapeTotalProducts(),
        _scrapeTotalStores(),
      ]);

      final response = results[0] as http.Response;
      final totalProducts = results[1] as int;
      final totalStores = results[2] as int;

      if (response.statusCode != 200) {
        return HomeData(
          ranks: _defaultRanks(),
          banners: _defaultBanners(),
          sliderImages: _defaultSliderImages(),
          totalPartners: 950,
          totalProducts: totalProducts,
          totalStores: totalStores,
        );
      }

      final document = htmlParser.parse(response.body);
      final partnerElem = document.querySelector('.aff-stats-pill .value');
      final partners = int.tryParse(
          partnerElem?.text.trim().replaceAll(RegExp(r'[^0-9]'), '') ??
              '950') ??
          950;
      final ranks = <MemberRank>[];
      final allSlides = document.querySelectorAll('.swiper-slide:not(.swiper-slide-duplicate)');
      final cards = allSlides.isNotEmpty
          ? allSlides
          .map((s) => s.querySelector('.rank-premium-card'))
          .whereType<dom.Element>()
          .toList()
          : document.querySelectorAll('.rank-premium-card');

      for (var i = 0; i < cards.length; i++) {
        final card = cards[i];
        final name = card.querySelector('.rank-name-v2')?.text.trim() ?? '';
        final countText =
            card.querySelector('.rank-count-v2 .num')?.text.trim() ?? '0';
        final count =
            int.tryParse(countText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final imgTag = card.querySelector('.rank-main-img');
        final imageUrl =
            imgTag?.attributes['src'] ?? imgTag?.attributes['data-src'] ?? '';
        if (name.isNotEmpty) {
          ranks.add(MemberRank(
            name: name,
            memberCount: count,
            imageUrl: _normalizeUrl(imageUrl),
            gradientColors: _rankColors(i),
          ));
        }
      }

      final banners = <CategoryBanner>[];
      final catElements =
      document.querySelectorAll('.ecommerce-modern-categories__item');
      for (var i = 0; i < catElements.length; i++) {
        final elem = catElements[i];
        final title = elem
            .querySelector('.ecommerce-modern-categories__title')
            ?.text
            .trim() ??
            '';
        final img =
        elem.querySelector('.ecommerce-modern-categories__thumb img');
        final imageUrl =
            img?.attributes['src'] ?? img?.attributes['data-src'] ?? '';
        if (title.isNotEmpty) {
          final link = elem.querySelector('a')?.attributes['href'] ?? '';
          banners.add(CategoryBanner(
            title: title,
            imageUrl: _normalizeUrl(imageUrl),
            color: [
              const Color(0xFF2E7D32),
              const Color(0xFF00695C)
            ][i % 2],
            link: _normalizeUrl(link),
          ));
        }
      }

      final seen = <String>{};
      final sliderImages = <SliderImage>[];
      final slides = document.querySelectorAll('.slider .slide-track .slide');
      for (final slide in slides) {
        final img = slide.querySelector('img');
        final src = img?.attributes['src'] ??
            img?.attributes['data-src'] ??
            img?.attributes['data-lazy-src'] ??
            '';
        if (src.isNotEmpty) {
          final normalized = _normalizeUrl(src);
          if (seen.add(normalized)) {
            sliderImages.add(SliderImage(imageUrl: normalized));
          }
        }
      }

      return HomeData(
        ranks: ranks.isNotEmpty ? ranks : _defaultRanks(),
        banners: banners.isNotEmpty ? banners : _defaultBanners(),
        sliderImages:
        sliderImages.isNotEmpty ? sliderImages : _defaultSliderImages(),
        totalPartners: partners,
        totalProducts: totalProducts,
        totalStores: totalStores,
      );
    } catch (e) {
      debugPrint('Lỗi gộp dữ liệu: $e');
      return HomeData(
        ranks: _defaultRanks(),
        banners: _defaultBanners(),
        sliderImages: _defaultSliderImages(),
        totalPartners: 950,
      );
    }
  }

  static Future<int> _scrapeTotalProducts() async {
    try {
      final res = await http
          .get(Uri.parse(cosmeticsUrl), headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return 0;
      final doc = htmlParser.parse(res.body);
      final text = doc.querySelector('.tp-shop-top-result p')?.text ??
          doc.querySelector('.woocommerce-result-count')?.text ??
          '';
      final matches = RegExp(r'\d+').allMatches(text).toList();
      return matches.isNotEmpty
          ? int.tryParse(matches.last.group(0)!) ?? 0
          : 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> _scrapeTotalStores() async {
    try {
      final res = await http
          .get(Uri.parse('$websiteUrl/cua-hang'), headers: _headers);
      if (res.statusCode != 200) return 0;
      final doc = htmlParser.parse(res.body);
      final text = doc.querySelector('.tp-shop-top-result p')?.text ?? '';
      final match = RegExp(r'tổng số\s+(\d+)').firstMatch(text);
      if (match != null) return int.tryParse(match.group(1)!) ?? 0;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  static String _cleanPrice(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _normalizeUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return websiteUrl + (url.startsWith('/') ? url : '/$url');
  }

  static List<SliderImage> defaultSliderImages() => _defaultSliderImages();

  static List<SliderImage> _defaultSliderImages() => [
    SliderImage(
        imageUrl:
        'https://angelunigreen.com.vn/storage/sliders/480873893-122116356056709765-5851246310207208475-n.jpg'),
    SliderImage(
        imageUrl:
        'https://angelunigreen.com.vn/storage/sliders/480334131-122114486000709765-6140223806069685209-n.jpg'),
    SliderImage(
        imageUrl:
        'https://angelunigreen.com.vn/storage/sliders/482025801-122117321882709765-5570764818085822380-n.jpg'),
  ];

  static List<MemberRank> _defaultRanks() => [
    MemberRank(
        name: 'HẠNG BẠC\n2 SAO',
        memberCount: 45,
        imageUrl: '',
        gradientColors: [
          const Color(0xFFB0BEC5),
          const Color(0xFF78909C)
        ]),
    MemberRank(
        name: 'HẠNG BẠC\n1 SAO',
        memberCount: 117,
        imageUrl: '',
        gradientColors: [
          const Color(0xFFCFD8DC),
          const Color(0xFF90A4AE)
        ]),
    MemberRank(
        name: 'HẠNG ĐỒNG',
        memberCount: 187,
        imageUrl: '',
        gradientColors: [
          const Color(0xFFFFCC80),
          const Color(0xFFFF8F00)
        ]),
    MemberRank(
        name: 'HẠNG VÀNG',
        memberCount: 62,
        imageUrl: '',
        gradientColors: [
          const Color(0xFFFFD700),
          const Color(0xFFFFA000)
        ]),
  ];

  static List<CategoryBanner> _defaultBanners() => [
    CategoryBanner(
        title: 'HÓA - MỸ PHẨM UNIGREEN',
        imageUrl: '',
        color: const Color(0xFF2E7D32),
        link: ''),
    CategoryBanner(
        title: 'SPA LÀM ĐẸP',
        imageUrl: '',
        color: const Color(0xFF00695C),
        link: ''),
    CategoryBanner(
        title: 'LINH CHI CAO CẤP',
        imageUrl: '',
        color: const Color(0xFF1B5E20),
        link: ''),
    CategoryBanner(
        title: 'THỰC PHẨM SẠCH',
        imageUrl: '',
        color: const Color(0xFF33691E),
        link: ''),
  ];

  static List<Product> _fallbackProducts() {
    final items = [
      {
        'name': 'Nước giặt xả UniGreen PLUS - Hương Anh Đào Xanh (9,6 kg)',
        'price': '280,000₫',
        'originalPrice': '320,000₫',
        'sku': 'LC-005-HMP',
      },
      {
        'name': 'Linh Chi Tươi Angel',
        'price': '299,000₫',
        'originalPrice': '',
        'sku': '',
      },
      {
        'name': 'Linh Chi Khô Cao Cấp',
        'price': '850,000₫',
        'originalPrice': '',
        'sku': '',
      },
    ];

    return items.asMap().entries.map((e) {
      return Product(
        id: 'fallback-${e.key}',
        name: e.value['name']!,
        price: e.value['price']!,
        originalPrice: e.value['originalPrice']!,
        imageUrl: '',
        productUrl: '',
        category: 'HÓA - MỸ PHẨM UNIGREEN',
        sku: e.value['sku']!,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  static List<Map<String, dynamic>> _fallbackStores() => [
    {
      'id': 'st-1',
      'name': 'Angel Linh Chi - Trụ sở chính',
      'address': 'TP. Hồ Chí Minh',
      'phone': '1800 xxxx',
      'hours': '8:00 - 21:00',
      'latitude': 10.8017,
      'longitude': 106.7550,
      'createdAt': DateTime.now().toIso8601String()
    },
    {
      'id': 'st-2',
      'name': 'Angel Linh Chi - Chi nhánh Hà Nội',
      'address': 'Hà Nội',
      'phone': '1800 xxxx',
      'hours': '8:00 - 21:00',
      'latitude': 21.0285,
      'longitude': 105.8542,
      'createdAt': DateTime.now().toIso8601String()
    },
  ];

  static List<Color> _rankColors(int i) {
    final palette = [
      [const Color(0xFFB0BEC5), const Color(0xFF78909C)],
      [const Color(0xFFCFD8DC), const Color(0xFF90A4AE)],
      [const Color(0xFFFFCC80), const Color(0xFFFF8F00)],
      [const Color(0xFFFFD700), const Color(0xFFFFA000)],
      [const Color(0xFF80DEEA), const Color(0xFF00ACC1)],
    ];
    return palette[i % palette.length];
  }
}

typedef ScrapingService = WebScraperService;