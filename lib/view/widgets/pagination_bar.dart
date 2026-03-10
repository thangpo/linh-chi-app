import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final void Function(int page) onPageTap;

  const PaginationBar({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.color,
    required this.onPageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: _buildPageItems()),
      ),
    );
  }

  List<Widget> _buildPageItems() {
    final items = <Widget>[];

    items.add(PageButton(
      label: '«',
      isIcon: true,
      isActive: false,
      isDisabled: currentPage <= 1,
      color: color,
      onTap: () => onPageTap(currentPage - 1),
    ));

    for (final p in _buildPageNumbers()) {
      if (p == -1) {
        items.add(const EllipsisButton());
      } else {
        items.add(PageButton(
          label: '$p',
          isActive: p == currentPage,
          isDisabled: false,
          color: color,
          onTap: () => onPageTap(p),
        ));
      }
    }

    items.add(PageButton(
      label: '»',
      isIcon: true,
      isActive: false,
      isDisabled: currentPage >= totalPages,
      color: color,
      onTap: () => onPageTap(currentPage + 1),
    ));

    return items;
  }

  List<int> _buildPageNumbers() {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }

    const int window = 2;
    final result = <int>[1];

    final int start = (currentPage - window).clamp(2, totalPages - 1);
    final int end = (currentPage + window).clamp(2, totalPages - 1);

    if (start > 2) result.add(-1);
    for (int p = start; p <= end; p++) result.add(p);
    if (end < totalPages - 1) result.add(-1);
    result.add(totalPages);

    return result;
  }
}

class PageButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDisabled;
  final bool isIcon;
  final Color color;
  final VoidCallback onTap;

  const PageButton({
    Key? key,
    required this.label,
    required this.isActive,
    required this.isDisabled,
    required this.color,
    required this.onTap,
    this.isIcon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? color : Colors.white;
    final fg = isActive
        ? Colors.white
        : isDisabled
        ? Colors.grey[300]!
        : color;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? color
                : isDisabled
                ? Colors.grey[200]!
                : color.withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: isIcon ? 15 : 13,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class EllipsisButton extends StatelessWidget {
  const EllipsisButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 32,
      height: 36,
      alignment: Alignment.center,
      child: Text(
        '...',
        style: GoogleFonts.beVietnamPro(
          fontSize: 13,
          color: Colors.grey[400],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}