import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:hisotech/services/scraper_service.dart';
import 'package:shimmer/shimmer.dart';

class MemberRanksWidget extends StatefulWidget {
  final List<MemberRank> ranks;
  final bool isLoading;

  const MemberRanksWidget({
    Key? key,
    required this.ranks,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<MemberRanksWidget> createState() => _MemberRanksWidgetState();
}

class _MemberRanksWidgetState extends State<MemberRanksWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  static const List<_RankTheme> _rankThemes = [
    _RankTheme(
      bg: Color(0xFFB0BEC5),
      gradientStart: Color(0xFFCFD8DC),
      gradientEnd: Color(0xFF546E7A),
      accent: Color(0xFF78909C),
      badgeBg: Color(0xFFECEFF1),
      badgeText: Color(0xFF546E7A),
      label: 'BẠC 2 SAO',
      icon: PhosphorIconsFill.star,
    ),
    _RankTheme(
      bg: Color(0xFFFFCC80),
      gradientStart: Color(0xFFFFE0B2),
      gradientEnd: Color(0xFFE65100),
      accent: Color(0xFFFF8F00),
      badgeBg: Color(0xFFFFF3E0),
      badgeText: Color(0xFFE65100),
      label: 'BẠC 1 SAO',
      icon: PhosphorIconsFill.starHalf,
    ),
    _RankTheme(
      bg: Color(0xFFFF8A65),
      gradientStart: Color(0xFFFFCCBC),
      gradientEnd: Color(0xFFBF360C),
      accent: Color(0xFFFF5722),
      badgeBg: Color(0xFFFBE9E7),
      badgeText: Color(0xFFBF360C),
      label: 'ĐỒNG',
      icon: PhosphorIconsFill.trophy,
    ),
    _RankTheme(
      bg: Color(0xFFFFD700),
      gradientStart: Color(0xFFFFF9C4),
      gradientEnd: Color(0xFFF57F17),
      accent: Color(0xFFFFA000),
      badgeBg: Color(0xFFFFFDE7),
      badgeText: Color(0xFFF57F17),
      label: 'VÀNG',
      icon: PhosphorIconsFill.crown,
    ),
    _RankTheme(
      bg: Color(0xFF80DEEA),
      gradientStart: Color(0xFFE0F7FA),
      gradientEnd: Color(0xFF006064),
      accent: Color(0xFF00ACC1),
      badgeBg: Color(0xFFE0F7FA),
      badgeText: Color(0xFF006064),
      label: 'KIM CƯƠNG',
      icon: PhosphorIconsFill.diamond,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<MemberRank> get _effectiveRanks =>
      widget.ranks.isNotEmpty ? widget.ranks : _defaultRanks();

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const MemberRanksSkeleton();
    }

    if (widget.ranks.isEmpty) {
      return const SizedBox.shrink();
    }

    final ranks = widget.ranks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: ranks.length,
            itemBuilder: (ctx, i) {
              final rank = ranks[i];
              final theme = _rankThemes[i % _rankThemes.length];
              final isActive = i == _currentPage;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                margin: EdgeInsets.only(
                  right: 12,
                  top: isActive ? 0 : 10,
                  bottom: isActive ? 0 : 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [theme.gradientStart, theme.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.gradientEnd.withOpacity(isActive ? 0.35 : 0.15),
                      blurRadius: isActive ? 18 : 8,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -28,
                      right: -28,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -18,
                      left: -18,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'HẠNG THÀNH VIÊN',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.75),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  theme.label,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.1,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ưu đãi độc quyền dành cho\nthành viên ${theme.label.toLowerCase()}',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.82),
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.45),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    '${rank.memberCount} KHÁCH HÀNG',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: rank.imageUrl.isNotEmpty
                                  ? ClipOval(
                                child: Image.network(
                                  rank.imageUrl,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Icon(
                                theme.icon,
                                size: 34,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _effectiveRanks.length,
                (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentPage ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? _rankThemes[i % _rankThemes.length].gradientEnd
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<MemberRank> _defaultRanks() => [
    MemberRank(
        name: 'HẠNG BẠC\n2 SAO',
        memberCount: 45,
        imageUrl: '',
        gradientColors: [const Color(0xFFB0BEC5), const Color(0xFF78909C)]),
    MemberRank(
        name: 'HẠNG BẠC\n1 SAO',
        memberCount: 117,
        imageUrl: '',
        gradientColors: [const Color(0xFFCFD8DC), const Color(0xFF90A4AE)]),
    MemberRank(
        name: 'HẠNG ĐỒNG',
        memberCount: 187,
        imageUrl: '',
        gradientColors: [const Color(0xFFFFCC80), const Color(0xFFFF8F00)]),
    MemberRank(
        name: 'HẠNG VÀNG',
        memberCount: 62,
        imageUrl: '',
        gradientColors: [const Color(0xFFFFD700), const Color(0xFFFFA000)]),
    MemberRank(
        name: 'HẠNG KIM\nCƯƠNG',
        memberCount: 28,
        imageUrl: '',
        gradientColors: [const Color(0xFF80DEEA), const Color(0xFF00ACC1)]),
  ];
}

class _RankTheme {
  final Color bg;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accent;
  final Color badgeBg;
  final Color badgeText;
  final String label;
  final IconData icon;

  const _RankTheme({
    required this.bg,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accent,
    required this.badgeBg,
    required this.badgeText,
    required this.label,
    required this.icon,
  });
}

class MemberRanksSkeleton extends StatelessWidget {
  const MemberRanksSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 20),
              itemCount: 2,
              itemBuilder: (context, index) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.82,
                  margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 60, height: 8, color: Colors.white),
                            const SizedBox(height: 8),
                            Container(width: 120, height: 24, color: Colors.white),
                            const SizedBox(height: 8),
                            Container(width: 150, height: 10, color: Colors.white),
                            const SizedBox(height: 4),
                            Container(width: 100, height: 10, color: Colors.white),
                            const SizedBox(height: 16),
                            Container(
                              width: 90,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == 0 ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ],
      ),
    );
  }
}