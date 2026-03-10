import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;
import 'package:flutter/foundation.dart';

class StoreScraperService {
  static const String websiteUrl = 'https://angelunigreen.com.vn';
  static const String storeUrl = '$websiteUrl/cua-hang';

  static final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'vi-VN,vi;q=0.9,en;q=0.8',
  };

  // Bùa hộ mệnh: Chấp nhận mọi chứng chỉ SSL để không bị lỗi Handshake trên mobile
  http.Client _getSafeClient() {
    final ioc = HttpClient();
    ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  Future<List<Map<String, dynamic>>> scrapeAllStores() async {
    final allStores = <Map<String, dynamic>>[];
    final client = _getSafeClient();

    try {
      // 1. Lấy trang đầu tiên
      final response = await client.get(Uri.parse(storeUrl), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return _fallbackStores();

      final document = htmlParser.parse(response.body);

      // Lấy tổng số trang từ pagination
      int totalPages = 1;
      final lastPageElem = document.querySelector('.pagination .page-item:nth-last-child(2) a') ??
          document.querySelector('a[rel="next"]')?.parent?.previousElementSibling?.querySelector('a');

      if (lastPageElem != null) {
        totalPages = int.tryParse(lastPageElem.text.trim()) ?? 1;
      }

      // 2. Cào dữ liệu trang 1
      allStores.addAll(_parseStoreItems(document));

      // 3. Cào các trang còn lại (nếu có)
      if (totalPages > 1) {
        for (int p = 2; p <= totalPages; p++) {
          final pRes = await client.get(Uri.parse('$storeUrl?page=$p'), headers: _headers);
          if (pRes.statusCode == 200) {
            allStores.addAll(_parseStoreItems(htmlParser.parse(pRes.body)));
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi cào Store: $e');
      return _fallbackStores();
    } finally {
      client.close();
    }

    return allStores.isNotEmpty ? allStores : _fallbackStores();
  }

  List<Map<String, dynamic>> _parseStoreItems(dom.Document document) {
    final stores = <Map<String, dynamic>>[];

    var items = document.querySelectorAll('.bb-store-item');
    if (items.isEmpty) items = document.querySelectorAll('.tp-shop-item');

    for (var item in items) {
      try {
        // ✅ Tên cửa hàng - lấy từ h4 bên trong content
        final name = item.querySelector('.bb-store-item-content h4')?.text.trim() ??
            item.querySelector('h4')?.text.trim() ?? '';
        if (name.isEmpty) continue;

        // ✅ Địa chỉ - lấy attribute title của p.text-truncate
        final address = item
            .querySelector('p.bb-store-item-info.text-truncate')
            ?.attributes['title']
            ?.trim() ??
            item.querySelector('p.bb-store-item-info.text-truncate')?.text.trim() ?? '';

        // ✅ Phone - lấy text của thẻ <a href="tel:...">
        final phone = item.querySelector('a[href^="tel:"]')?.text.trim() ?? '';

        // ✅ Email - lấy text của thẻ <a href="mailto:...">
        final email = item.querySelector('a[href^="mailto:"]')?.text.trim() ?? '';

        // ✅ Rating - a.small nằm trong .bb-store-item-rating
        final rating = item
            .querySelector('.bb-store-item-rating a.small')
            ?.text
            .trim() ??
            '(0 đánh giá)';

        // ✅ Image - ưu tiên data-bb-lazy (lazy load), fallback sang src
        final imgElem = item.querySelector('.bb-store-item-logo img');
        final imageUrl = imgElem?.attributes['src'] ?? '';
        // Bỏ qua ảnh placeholder
        final finalImageUrl = imageUrl.contains('placeholder') ? '' : imageUrl;

        // ✅ Store URL - lấy href từ link đầu tiên trong content (bao quanh h4)
        final storeUrlPath = item
            .querySelector('.bb-store-item-content > a')
            ?.attributes['href'] ??
            item.querySelector('.bb-store-item-action a')?.attributes['href'] ?? '';

        stores.add({
          'name': name,
          'address': address,
          'phone': phone,
          'email': email,
          'imageUrl': _normalizeUrl(finalImageUrl),
          'storeUrl': storeUrlPath.startsWith('http')
              ? storeUrlPath
              : _normalizeUrl(storeUrlPath),
          'rating': rating,
        });
      } catch (e) {
        debugPrint('⚠️ Lỗi parse item: $e');
        continue;
      }
    }

    debugPrint('✅ Đã parse được ${stores.length} cửa hàng');
    return stores;
  }

  String _normalizeUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return websiteUrl + (url.startsWith('/') ? url : '/$url');
  }

  List<Map<String, dynamic>> _fallbackStores() {
    return [
      {
        'name': 'Angel UniGreen - Trụ sở',
        'address': 'Tổ 1 khu phố Yết Kiêu 5, Hạ Long, Quảng Ninh',
        'phone': '+84986300280',
        'email': 'phuonghoai@gmail.com',
        'imageUrl': '',
        'storeUrl': '',
        'rating': '0 đánh giá',
      }
    ];
  }
}