import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:rentals/models/home_banner.dart';
import 'package:rentals/views/product/product_page.dart';
import 'package:rentals/views/profile/like_page.dart';
import 'package:rentals/views/search/search_page.dart';
import 'package:rentals/category_page.dart';
import 'package:rentals/services/home_banner_service.dart';
import 'package:rentals/services/rental_service.dart';
import 'package:rentals/widgets/animated_like_button.dart';
import 'package:rentals/widgets/animated_search_bar.dart';

// Kept for backward compatibility if any unedited file imports it.
List<Map<String, dynamic>> globalLikedItems = [];

class HomePage extends StatefulWidget {
  final VoidCallback onMapTap;
  final VoidCallback onNearMeTap;
  final Function(String) onCategorySelected;

  const HomePage({
    super.key,
    required this.onMapTap,
    required this.onNearMeTap,
    required this.onCategorySelected,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _offerController = PageController();
  int _currentOfferIndex = 0;
  Timer? _offerTimer;
  StreamSubscription<List<HomeBanner>>? _bannerSubscription;
  late final Stream<List<Map<String, dynamic>>> _rentalsStream;
  List<HomeBanner> _dynamicBanners = const [];
  bool _bannerLoadFailed = false;

  final List<String> _fallbackOfferImages = const [
    'assets/images/offer1.png',
    'assets/images/offer2.png',
    'assets/images/offer3.png',
  ];

  @override
  void initState() {
    super.initState();
    _rentalsStream = RentalService.getAllRentalsWithOwnerNames();
    _listenToHomeBanners();
    _startOfferTimer();
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    _bannerSubscription?.cancel();
    _offerController.dispose();
    super.dispose();
  }

  bool get _showDynamicBanners =>
      !_bannerLoadFailed && _dynamicBanners.isNotEmpty;

  int get _bannerCount => _showDynamicBanners
      ? _dynamicBanners.length
      : _fallbackOfferImages.length;

  void _listenToHomeBanners() {
    _bannerSubscription = HomeBannerService.watchActiveBanners().listen(
      (banners) {
        if (!mounted) {
          return;
        }

        setState(() {
          _bannerLoadFailed = false;
          _dynamicBanners = banners;
          _syncBannerIndex();
        });
      },
      onError: (error, stackTrace) {
        if (!mounted) {
          return;
        }

        setState(() {
          _bannerLoadFailed = true;
          _dynamicBanners = const [];
          _syncBannerIndex();
        });
      },
    );
  }

  void _startOfferTimer() {
    _offerTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      final bannerCount = _bannerCount;
      if (bannerCount <= 1) return;

      final nextIndex = _currentOfferIndex < bannerCount - 1
          ? _currentOfferIndex + 1
          : 0;

      if (_offerController.hasClients) {
        _offerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else if (mounted) {
        setState(() {
          _currentOfferIndex = nextIndex;
        });
      }
    });
  }

  void _syncBannerIndex() {
    final bannerCount = _bannerCount;
    if (bannerCount == 0) {
      _currentOfferIndex = 0;
      return;
    }

    if (_currentOfferIndex >= bannerCount) {
      _currentOfferIndex = 0;

      if (_offerController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _offerController.hasClients) {
            _offerController.jumpToPage(0);
          }
        });
      }
    }
  }

  void _openSearchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  void _openFavoritesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LikePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 5),
            child: Column(
              children: [
                _buildTopHeader(),
                const SizedBox(height: 12),
                AnimatedSearchBar(
                  onTap: _openSearchScreen,
                  onActionTap: _openFavoritesScreen,
                  actionIcon: Image.asset(
                    'assets/icons/like_icon.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategoryList(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Your Rent.., Your Way..."),

                    _buildBannerSection(),

                    _buildSectionTitle("Top Deals"),

                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _rentalsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF113F67),
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                "No items available yet",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }

                        final items = snapshot.data!;
                        if (items.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                "No items available yet",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          cacheExtent: 800,
                          itemCount: items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                              ),
                          itemBuilder: (context, index) {
                            return _buildDealCard(context, items[index]);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/rentals_rlogo.png',
            height: 42,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Rentals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    height: 1,
                  ),
                ),
                SizedBox(height: 4),
                _TypingBrandSubtitle(text: 'Just Rent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 77,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryItem("Fashion", "assets/icons/fashion_icon.png"),
          _categoryItem("Jewellery", "assets/icons/jwellery_icon.png"),
          _categoryItem("Vehicle", "assets/icons/vehicle_icon.png"),
          _categoryItem("House", "assets/icons/house_icon.png"),
          _categoryItem("Electronics", "assets/icons/electronic_icon.png"),
          _categoryItem("Books", "assets/icons/books_icon.png"),
          _categoryItem("Game", "assets/icons/game_icon.png"),
          _categoryItem("GYM", "assets/icons/gym_icon.png"),
          _categoryItem("Travel", "assets/icons/travel_icon.png"),
          _categoryItem("Decore", "assets/icons/decore_icon.png"),
          _categoryItem("Furniture", "assets/icons/furniture_icon.png"),
          _categoryItem("Subscription", "assets/icons/subscription_icon.png"),
          _categoryItem("Other", "assets/icons/other_icon.png"),
        ],
      ),
    );
  }

  Widget _categoryItem(String label, String assetPath) {
    return GestureDetector(
      onTap: () {
        widget.onCategorySelected(label);
        if (label != 'All') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryPage(categoryName: label),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A2FF), Color(0xFF16BCE6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: Image.asset(
                  assetPath,
                  height: 28,
                  width: 28,
                  color: Colors.white,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.category, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearMeBanner() {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(15),
        image: const DecorationImage(
          image: AssetImage('assets/images/nearme_googlemap.png'),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onNearMeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF113F67),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/icons/nearme_icon.png",
                          height: 18,
                          width: 18,
                          color: const Color(0xFF113F67),
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.near_me,
                            color: Color(0xFF113F67),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Near Me",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF113F67),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: widget.onMapTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF217DCD), Color(0xFF113F67)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text(
                      "View On Maps",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Image.asset(
                      "assets/icons/map_icon.png",
                      height: 14,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.map, color: Colors.white, size: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    if (_bannerCount == 0) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF113F67).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 16 / 7,
          child: PageView.builder(
            controller: _offerController,
            itemCount: _bannerCount,
            onPageChanged: (index) {
              if (!mounted) {
                return;
              }

              setState(() {
                _currentOfferIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _showDynamicBanners
                  ? _buildNetworkOfferImage(
                      imageSource: _dynamicBanners[index].preferredImageSource,
                      fallbackAsset:
                          _fallbackOfferImages[index %
                              _fallbackOfferImages.length],
                    )
                  : _buildAssetOfferImage(_fallbackOfferImages[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    if (_bannerCount <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_bannerCount, _buildAnimatedIndicator),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        children: [
          _buildNearMeBanner(),
          const SizedBox(height: 16),
          _buildPromoBanner(),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildAssetOfferImage(String assetPath) {
    return Container(
      color: const Color(0xFFF3F8FD),
      alignment: Alignment.center,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.local_offer, color: Colors.grey, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkOfferImage({
    required String imageSource,
    required String fallbackAsset,
  }) {
    return _ResolvedHomeBannerImage(
      source: imageSource,
      fallback: _buildAssetOfferImage(fallbackAsset),
    );
  }

  Widget _buildAnimatedIndicator(int index) {
    final isSelected = index == _currentOfferIndex;

    return AnimatedScale(
      scale: isSelected ? 1 : 0.94,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: isSelected ? 1 : 0.72,
        duration: const Duration(milliseconds: 220),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 20 : 6,
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isSelected
                ? const Color(0xFF113F67)
                : const Color(0xFF16BCE6),
          ),
        ),
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, Map<String, dynamic> deal) {
    String imageUrl = '';

    if (deal['imageUrls'] != null) {
      if (deal['imageUrls'] is List) {
        final list = (deal['imageUrls'] as List)
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .toList();
        if (list.isNotEmpty) {
          imageUrl = list[0].toString();
        }
      } else if (deal['imageUrls'] is String &&
          deal['imageUrls'].toString().trim().isNotEmpty) {
        imageUrl = deal['imageUrls'].toString().trim();
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(productData: deal),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF113F67).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              height: 100,
                              width: double.infinity,
                              placeholder: (context, url) => Container(
                                height: 100,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF16BCE6),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              height: 100,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF113F67,
                          ).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: AnimatedLikeButton(deal: deal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal['title']?.toString() ?? 'Unknown Item',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Color(0xFF113F67),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                deal['ownerName']?.toString() ??
                                    'Unknown Owner',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Rs. ${deal['price'] ?? '0'}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Color(0xFF113F67),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          width: 38,
                          height: 26,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF113F67),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Image.asset(
                              "assets/icons/rent_icon.png",
                              height: 12,
                              width: 12,
                              color: const Color(0xFF113F67),
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF113F67),
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, bottom: 12, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF113F67),
        ),
      ),
    );
  }
}

class _ResolvedHomeBannerImage extends StatelessWidget {
  const _ResolvedHomeBannerImage({
    required this.source,
    required this.fallback,
  });

  final String source;
  final Widget fallback;

  static final Map<String, String> _resolvedUrlCache = <String, String>{};
  static final Map<String, Future<String?>> _pendingResolutions =
      <String, Future<String?>>{};

  @override
  Widget build(BuildContext context) {
    final trimmedSource = source.trim();
    if (trimmedSource.isEmpty) {
      return fallback;
    }

    final normalizedNetworkUrl = _normalizeBannerNetworkUrl(trimmedSource);
    if (normalizedNetworkUrl != null) {
      return _buildNetworkImage(normalizedNetworkUrl);
    }

    return FutureBuilder<String?>(
      future: _resolveImageUrl(trimmedSource),
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data?.trim() ?? '';
        if (resolvedUrl.isEmpty) {
          return fallback;
        }

        return _buildNetworkImage(resolvedUrl);
      },
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return Container(
      color: const Color(0xFFF3F8FD),
      alignment: Alignment.center,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          color: const Color(0xFFF3F8FD),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF16BCE6),
            ),
          ),
        ),
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }

  static Future<String?> _resolveImageUrl(String source) {
    final cachedResolvedUrl = _resolvedUrlCache[source];
    if (cachedResolvedUrl != null && cachedResolvedUrl.isNotEmpty) {
      return Future<String?>.value(cachedResolvedUrl);
    }

    return _pendingResolutions.putIfAbsent(source, () async {
      try {
        final normalizedNetworkUrl = _normalizeBannerNetworkUrl(source);
        if (normalizedNetworkUrl != null) {
          _resolvedUrlCache[source] = normalizedNetworkUrl;
          return normalizedNetworkUrl;
        }

        final Reference reference;
        if (source.startsWith('gs://')) {
          reference = FirebaseStorage.instance.refFromURL(source);
        } else {
          final normalizedPath = source.startsWith('/')
              ? source.substring(1)
              : source;
          if (normalizedPath.isEmpty) {
            return null;
          }
          reference = FirebaseStorage.instance.ref().child(normalizedPath);
        }

        final resolvedUrl = (await reference.getDownloadURL()).trim();
        if (resolvedUrl.isEmpty) {
          return null;
        }

        _resolvedUrlCache[source] = resolvedUrl;
        return resolvedUrl;
      } catch (_) {
        return null;
      } finally {
        _pendingResolutions.remove(source);
      }
    });
  }
}

String? _normalizeBannerNetworkUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  if (_isBannerNetworkUrl(trimmed)) {
    return trimmed;
  }

  if (trimmed.startsWith('//')) {
    final protocolRelativeUrl = 'https:$trimmed';
    return _isBannerNetworkUrl(protocolRelativeUrl)
        ? protocolRelativeUrl
        : null;
  }

  if (!_looksLikeBannerHostPath(trimmed)) {
    return null;
  }

  final schemelessUrl = 'https://$trimmed';
  return _isBannerNetworkUrl(schemelessUrl) ? schemelessUrl : null;
}

bool _isBannerNetworkUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme.toLowerCase() == 'http' ||
          uri.scheme.toLowerCase() == 'https');
}

bool _looksLikeBannerHostPath(String value) {
  if (value.startsWith('/') || value.startsWith(r'\')) {
    return false;
  }

  final hostCandidate = value.split(RegExp(r'[/?#]')).first.trim();
  if (hostCandidate.isEmpty ||
      hostCandidate.contains(' ') ||
      !hostCandidate.contains('.')) {
    return false;
  }

  final lastDotIndex = hostCandidate.lastIndexOf('.');
  if (lastDotIndex <= 0 || lastDotIndex == hostCandidate.length - 1) {
    return false;
  }

  final topLevelSegment = hostCandidate.substring(lastDotIndex + 1);
  return RegExp(r'^[a-zA-Z]{2,24}$').hasMatch(topLevelSegment);
}

class _TypingBrandSubtitle extends StatefulWidget {
  const _TypingBrandSubtitle({required this.text});

  final String text;

  @override
  State<_TypingBrandSubtitle> createState() => _TypingBrandSubtitleState();
}

class _TypingBrandSubtitleState extends State<_TypingBrandSubtitle> {
  Timer? _typingTimer;
  Timer? _caretTimer;
  late int _visibleLength;
  bool _showCaret = true;

  @override
  void initState() {
    super.initState();
    _visibleLength = widget.text.isEmpty ? 0 : 1;
    _startTyping();
    _startCaretBlink();
  }

  void _startTyping() {
    if (widget.text.length <= 1) {
      return;
    }

    _typingTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_visibleLength >= widget.text.length) {
        timer.cancel();
        return;
      }

      setState(() {
        _visibleLength += 1;
      });
    });
  }

  void _startCaretBlink() {
    _caretTimer = Timer.periodic(const Duration(milliseconds: 520), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _showCaret = !_showCaret;
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _caretTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.text.substring(0, _visibleLength);

    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            visibleText,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
          const SizedBox(width: 2),
          AnimatedOpacity(
            opacity: _showCaret ? 1 : 0.18,
            duration: const Duration(milliseconds: 180),
            child: Container(
              width: 1.6,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFFBFEFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
