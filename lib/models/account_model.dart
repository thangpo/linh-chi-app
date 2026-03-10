import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlParser;
import 'dart:convert';

class AccountMenuItem {
  final String label;
  final String url;
  final IconData icon;
  final bool isLogout;
  const AccountMenuItem({required this.label, required this.url, required this.icon, this.isLogout = false});
}

class AccountData {
  final String name;
  final String phone;
  final String avatarBase64;
  final String avatarUrl;
  final List<AccountMenuItem> menuItems;
  final bool isLoggedIn;

  const AccountData({
    required this.name,
    required this.phone,
    this.avatarBase64 = '',
    this.avatarUrl = '',
    required this.menuItems,
    this.isLoggedIn = true
  });

  ImageProvider? get avatarImage {
    if (avatarBase64.isNotEmpty) {
      try {
        final data = avatarBase64.contains(',') ? avatarBase64.split(',').last : avatarBase64;
        return MemoryImage(base64Decode(data.trim()));
      } catch (_) {}
    }
    return avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null;
  }
}

// Hàm Parse này sẽ nhận HTML và các dữ liệu hỗ trợ từ Controller
AccountData parseAccountFromHtml(String html, IconData Function(String, bool) iconPicker, List<AccountMenuItem> defaults) {
  final document = htmlParser.parse(html);
  final name = document.querySelector('.hero-name')?.text.trim() ?? '';
  final phone = document.querySelector('.hero-meta')?.text.trim() ?? '';
  final avatarImg = document.querySelector('.hero-avatar img');
  final avatarSrc = avatarImg?.attributes['src'] ?? '';

  String avatarBase64 = avatarSrc.startsWith('data:') ? avatarSrc : '';
  String avatarUrl = avatarSrc.startsWith('http') ? avatarSrc : '';

  final menuItems = <AccountMenuItem>[];
  final listItems = document.querySelectorAll('.list-item');

  for (final item in listItems) {
    final label = item.querySelector('.item-text')?.text.trim() ?? '';
    final rawUrl = item.attributes['href'] ?? '';
    final url = rawUrl.replaceFirst('https://angelunigreen.com.vn', '');
    if (label.isEmpty) continue;
    final isLogout = item.classes.contains('list-item--logout') || url.contains('/logout');
    menuItems.add(AccountMenuItem(label: label, url: url, icon: iconPicker(label, isLogout), isLogout: isLogout));
  }

  return AccountData(
    name: name.isNotEmpty ? name : 'Khách hàng',
    phone: phone,
    avatarBase64: avatarBase64,
    avatarUrl: avatarUrl,
    menuItems: menuItems.isNotEmpty ? menuItems : defaults,
    isLoggedIn: name.isNotEmpty,
  );
}