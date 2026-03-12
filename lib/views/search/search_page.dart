import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:rentals/services/rental_service.dart';
import 'package:rentals/services/user_service.dart';
import 'package:rentals/views/product/product_page.dart';
import 'package:rentals/views/profile/owner_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allRentals = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _productResults = [];
  List<Map<String, dynamic>> _userResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRentals() async {
    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        RentalService.fetchAllRentalsWithOwnerNames(),
        UserService.fetchAllUsers(),
      ]);

      final rentals = results[0];
      final users = results[1];

      if (!mounted) return;

      setState(() {
        _allRentals = rentals;
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allRentals = [];
        _allUsers = [];
        _isLoading = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    setState(() {
      _productResults = RentalService.filterRentalsByQuery(_allRentals, value);
      _userResults = UserService.filterUsersByQuery(_allUsers, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      'assets/icons/arrow_back_icon.png',
                      height: 18,
                      color: Colors.white,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Search',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8FB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFF113F67,
                            ).withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: Color(0xFF113F67),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                onChanged: _onQueryChanged,
                                textInputAction: TextInputAction.search,
                                style: const TextStyle(
                                  color: Color(0xFF113F67),
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Search title, category, owner...',
                                  hintStyle: TextStyle(
                                    color: const Color(
                                      0xFF113F67,
                                    ).withValues(alpha: 0.55),
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _onQueryChanged('');
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Color(0xFF113F67),
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF113F67)),
      );
    }

    if (_allRentals.isEmpty && _allUsers.isEmpty) {
      return _SearchStateMessage(
        icon: Icons.search_off,
        title: 'No searchable data yet',
        subtitle: 'Profiles and listings will appear here once they are added.',
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return _SearchStateMessage(
        icon: Icons.search,
        title: 'Start searching',
        subtitle: 'Find rentals by title, category, subcategory, or owner.',
      );
    }

    if (_userResults.isEmpty && _productResults.isEmpty) {
      return _SearchStateMessage(
        icon: Icons.search_off,
        title: 'No results found',
        subtitle: 'Try a different keyword or browse another category.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        if (_userResults.isNotEmpty) ...[
          const _SearchSectionTitle(title: 'Users'),
          const SizedBox(height: 12),
          ..._userResults.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _UserSearchResultCard(user: user),
            ),
          ),
        ],
        if (_productResults.isNotEmpty) ...[
          if (_userResults.isNotEmpty) const SizedBox(height: 8),
          const _SearchSectionTitle(title: 'Products'),
          const SizedBox(height: 12),
          ..._productResults.map(
            (rental) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SearchResultCard(rental: rental),
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchSectionTitle extends StatelessWidget {
  final String title;

  const _SearchSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF113F67),
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> rental;

  const _SearchResultCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    final imageUrl = _extractPrimaryImageUrl(rental);
    final title = rental['title']?.toString().trim().isNotEmpty == true
        ? rental['title'].toString().trim()
        : 'Unknown Item';
    final ownerName = rental['ownerName']?.toString().trim().isNotEmpty == true
        ? rental['ownerName'].toString().trim()
        : 'Unknown Owner';
    final category = rental['category']?.toString().trim() ?? 'Uncategorized';
    final subcategory = rental['subcategory']?.toString().trim() ?? 'Other';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(productData: rental),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF113F67).withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 110,
                        height: 110,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF16BCE6),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 110,
                        height: 110,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF113F67),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$category - $subcategory',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF16BCE6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Rs. ${rental['price'] ?? '0'}',
                      style: const TextStyle(
                        color: Color(0xFF113F67),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
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

  String _extractPrimaryImageUrl(Map<String, dynamic> rental) {
    final imageUrls = rental['imageUrls'];

    if (imageUrls is List) {
      for (final image in imageUrls) {
        final url = image?.toString().trim() ?? '';
        if (url.isNotEmpty) {
          return url;
        }
      }
    }

    if (imageUrls is String && imageUrls.trim().isNotEmpty) {
      return imageUrls.trim();
    }

    return '';
  }
}

class _UserSearchResultCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserSearchResultCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final String userId = user['uid']?.toString() ?? '';
    final String name = user['name']?.toString().trim().isNotEmpty == true
        ? user['name'].toString().trim()
        : 'Unknown User';
    final String email = user['email']?.toString().trim() ?? '';
    final String imageUrl = user['profileImageUrl']?.toString().trim() ?? '';
    final String locationLabel = UserService.getLocationLabel(
      location: user['location']?.toString(),
      latitude: user['latitude'] as double?,
      longitude: user['longitude'] as double?,
    );

    return GestureDetector(
      onTap: userId.isEmpty
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OwnerProfilePage(ownerId: userId),
                ),
              );
            },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF113F67).withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey[200],
                backgroundImage: imageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(imageUrl)
                    : null,
                child: imageUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey, size: 28)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF113F67),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email.isNotEmpty ? email : 'Public owner profile',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF16BCE6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      locationLabel.isNotEmpty
                          ? locationLabel
                          : 'Location not shared',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF16BCE6).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF113F67),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SearchStateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF113F67).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF113F67)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF113F67),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
