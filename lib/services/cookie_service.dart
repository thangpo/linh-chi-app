import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CookieService {
  static WebViewController? _controller;

  static void registerController(WebViewController controller) {
    _controller = controller;
    debugPrint('✅ WebViewController đã đăng ký');
  }

  /// Lấy cookie non-HttpOnly qua JS (XSRF-TOKEN, v.v.)
  static Future<String> getWebViewCookies() async {
    if (_controller == null) return '';
    try {
      final result = await _controller!.runJavaScriptReturningResult('document.cookie');
      return result.toString().replaceAll('"', '').trim();
    } catch (e) {
      debugPrint('❌ JS cookie lỗi: $e');
      return '';
    }
  }

  /// Kiểm tra login bằng cách lấy HTML trang account rồi xem có tên user không
  /// Đây là cách đáng tin cậy nhất với Laravel session
  static Future<bool> isLoggedIn() async {
    if (_controller == null) return false;
    try {
      // Inject JS để đọc DOM của trang hiện tại nếu đang ở angelunigreen
      final result = await _controller!.runJavaScriptReturningResult('''
        (function() {
          var nameEl = document.querySelector('.hero-name');
          if (nameEl) return nameEl.innerText.trim();
          return '';
        })()
      ''');
      final name = result.toString().replaceAll('"', '').trim();
      debugPrint('👤 User từ DOM: $name');
      return name.isNotEmpty;
    } catch (e) {
      debugPrint('❌ isLoggedIn lỗi: $e');
      return false;
    }
  }

  /// Lấy toàn bộ HTML của trang hiện tại trong WebView
  static Future<String> getCurrentPageHtml() async {
    if (_controller == null) return '';
    try {
      final result = await _controller!.runJavaScriptReturningResult(
          'document.documentElement.outerHTML'
      );
      // outerHTML trả về JSON string có escape — cần decode
      String html = result.toString();
      if (html.startsWith('"') && html.endsWith('"')) {
        html = html.substring(1, html.length - 1);
        html = html.replaceAll(r'\"', '"').replaceAll(r'\n', '\n').replaceAll(r'\t', '\t');
      }
      return html;
    } catch (e) {
      debugPrint('❌ getHtml lỗi: $e');
      return '';
    }
  }

  static Future<void> clearCookies() async {
    await WebViewCookieManager().clearCookies();
    _controller = null;
  }
}