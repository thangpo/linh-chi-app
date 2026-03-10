import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hisotech/services/scraper_service.dart';

class CategoryBannersWidget extends StatelessWidget {
  final List<CategoryBanner> banners;
  final bool isLoading;
  final void Function(String url, String title)? onTap;
  final EdgeInsets padding;

  const CategoryBannersWidget({
    Key? key,
    required this.banners,
    this.isLoading = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  }) : super(key: key);

  static List<CategoryBanner> get defaultBanners => [
    CategoryBanner(
      title: 'HÓA - MỸ PHẨM\nUNIGREEN',
      imageUrl: '',
      color: const Color(0xFF2E7D32),
      link: '',
    ),
    CategoryBanner(
      title: 'SPA\nLÀM ĐẸP',
      imageUrl: '',
      color: const Color(0xFF00695C),
      link: '',
    ),
    CategoryBanner(
      title: 'LINH CHI\nCAO CẤP',
      imageUrl: '',
      color: const Color(0xFF1B5E20),
      link: '',
    ),
    CategoryBanner(
      title: 'THỰC PHẨM\nSẠCH',
      imageUrl: '',
      color: const Color(0xFF33691E),
      link: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();

    final displayBanners = banners.isNotEmpty ? banners : defaultBanners;
    final rows = <List<CategoryBanner>>[];
    for (var i = 0; i < displayBanners.length; i += 2) {
      rows.add([
        displayBanners[i],
        if (i + 1 < displayBanners.length) displayBanners[i + 1],
      ]);
    }

    return Padding(
      padding: padding,
      child: Column(
        children: rows.map((pair) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: _BannerCard(banner: pair[0], onTap: onTap),
                ),
                const SizedBox(width: 12),
                if (pair.length > 1)
                  Expanded(
                    child: _BannerCard(banner: pair[1], onTap: onTap),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(2, (_) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: List.generate(2, (j) {
                return Expanded(
                  child: Container(
                    height: 160,
                    margin: EdgeInsets.only(
                      left: j == 0 ? 0 : 6,
                      right: j == 0 ? 6 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final CategoryBanner banner;
  final void Function(String url, String title)? onTap;

  const _BannerCard({required this.banner, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap?.call(banner.link, banner.title),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Background(banner: banner),
              _FullOverlay(color: banner.color),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    _ExploreButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  final CategoryBanner banner;
  const _Background({required this.banner});

  @override
  Widget build(BuildContext context) {
    if (banner.imageUrl.isNotEmpty) {
      return Image.network(
        banner.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _ColorGradient(color: banner.color);
        },
        errorBuilder: (_, __, ___) => _ColorGradient(color: banner.color),
      );
    }
    return _ColorGradient(color: banner.color);
  }
}

class _ColorGradient extends StatelessWidget {
  final Color color;
  const _ColorGradient({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _FullOverlay extends StatelessWidget {
  final Color color;
  const _FullOverlay({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.50),
            Colors.black.withOpacity(0.20),
            Colors.black.withOpacity(0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _ExploreButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Khám phá ngay',
            style: GoogleFonts.beVietnamPro(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 12,
            color: Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }
}