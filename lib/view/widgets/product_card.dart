import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hisotech/services/scraper_service.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Color themeColor;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.product,
    required this.themeColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _buildImageSection()),
            Expanded(flex: 4, child: _buildInfoSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: product.imageUrl.isNotEmpty
              ? Image.network(
            product.imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : _imagePlaceholder(),
            errorBuilder: (_, __, ___) => _imagePlaceholder(),
          )
              : _imagePlaceholder(),
        ),
        if (product.discountPercent.isNotEmpty)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                product.discountPercent,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        if (product.isOutOfStock)
          Positioned.fill(
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                color: Colors.black.withOpacity(0.45),
                alignment: Alignment.center,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Hết hàng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
              height: 1.35,
            ),
          ),
          const Spacer(),
          _buildPriceRow(),
          if (product.soldCount.isNotEmpty || product.location.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildMetaRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.originalPrice.isNotEmpty) ...[
                Text(
                  product.originalPrice,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    color: Colors.grey[400],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 1),
              ],
              Text(
                product.price,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: themeColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow() {
    return Row(
      children: [
        if (product.soldCount.isNotEmpty) ...[
          Icon(Icons.shopping_bag_outlined, size: 10, color: Colors.grey[400]),
          const SizedBox(width: 3),
          Text(
            'Đã bán ${product.soldCount}',
            style: GoogleFonts.beVietnamPro(fontSize: 9, color: Colors.grey[400]),
          ),
        ],
        const Spacer(),
        if (product.location.isNotEmpty)
          Flexible(
            child: Text(
              product.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(fontSize: 9, color: Colors.grey[400]),
            ),
          ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF0F4F0),
      child: Center(
        child: Icon(
          Icons.eco_outlined,
          size: 36,
          color: themeColor.withOpacity(0.3),
        ),
      ),
    );
  }
}