import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hisotech/models/account_model.dart';
import 'package:hisotech/services/cookie_service.dart';

class AccountController {

  Future<AccountData> fetchFullAccountData() async {
    // Cách 1: Lấy HTML trực tiếp từ WebView đang mở (chính xác nhất)
    final htmlFromWebView = await CookieService.getCurrentPageHtml();
    if (htmlFromWebView.contains('hero-name') || htmlFromWebView.contains('hero-profile')) {
      debugPrint('✅ Dùng HTML trực tiếp từ WebView');
      return parseAccountFromHtml(htmlFromWebView, iconForLabel, defaultMenuItems());
    }

    // Cách 2: Fallback — dùng cookie JS để gọi HTTP request
    final cookieString = await CookieService.getWebViewCookies();
    if (cookieString.isEmpty) {
      debugPrint('⚠️ Cookie rỗng — chưa đăng nhập');
      return fallbackAccountData();
    }

    const url = 'https://angelunigreen.com.vn/khach-hang/tai-khoan';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
        'Cookie': cookieString,
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'vi-VN,vi;q=0.9',
        'Referer': 'https://angelunigreen.com.vn/',
      }).timeout(const Duration(seconds: 15));

      debugPrint('📡 Status: ${response.statusCode}');
      debugPrint('📍 URL sau redirect: ${response.request?.url}');

      if (response.statusCode == 200) {
        final body = response.body;
        if (body.contains('hero-name') || body.contains('hero-profile')) {
          debugPrint('✅ Dùng HTML từ HTTP request');
          return parseAccountFromHtml(body, iconForLabel, defaultMenuItems());
        } else {
          debugPrint('⚠️ HTML không chứa profile — bị redirect về login');
          return fallbackAccountData();
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi fetch: $e');
    }

    return fallbackAccountData();
  }

  AccountData fallbackAccountData() => AccountData(
    name: 'Khách hàng',
    phone: '',
    menuItems: defaultMenuItems(),
    isLoggedIn: false,
  );

  IconData iconForLabel(String label, bool isLogout) {
    if (isLogout) return Icons.logout;
    final l = label.toLowerCase();
    if (l.contains('bảng điều')) return Icons.dashboard_outlined;
    if (l.contains('giới thiệu')) return Icons.share_outlined;
    if (l.contains('quản lý') || l.contains('quản lí')) return Icons.people_outline;
    if (l.contains('chuyển tiền')) return Icons.swap_horiz;
    if (l.contains('báo cáo')) return Icons.bar_chart_outlined;
    if (l.contains('ngân hàng')) return Icons.account_balance_outlined;
    if (l.contains('rút tiền')) return Icons.payments_outlined;
    if (l.contains('xác thực')) return Icons.badge_outlined;
    if (l.contains('cài đặt')) return Icons.settings_outlined;
    return Icons.chevron_right;
  }

  List<AccountMenuItem> defaultMenuItems() => const [
    AccountMenuItem(
        label: 'Bảng điều khiển',
        url: '/marketing/dashboard',
        icon: Icons.dashboard_outlined),
    AccountMenuItem(
        label: 'Giới thiệu của tôi',
        url: '/marketing/referral',
        icon: Icons.share_outlined),
    AccountMenuItem(
        label: 'Đăng xuất',
        url: '/logout',
        icon: Icons.logout,
        isLogout: true),
  ];
}