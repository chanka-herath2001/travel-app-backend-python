import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/places_service.dart';
import '../../utils/contants.dart';
import '../location/location_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _placesService = PlacesService();
  Timer? _debounce;

  List<PlaceResult> _results = [];
  List<PlaceResult> _nearbyResults = [];
  bool _isLoading = false;
  bool _isLoadingNearby = false;
  bool _hasSearched = false;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _loadUserLocationAndNearby();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUserLocationAndNearby() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      _userLat = pos.latitude;
      _userLng = pos.longitude;
      _loadNearbyPlaces();
    } catch (_) {}
  }

  Future<void> _loadNearbyPlaces() async {
    if (_userLat == null || _userLng == null) return;
    setState(() => _isLoadingNearby = true);
    try {
      // Search for top rated nearby places
      final results = await _placesService.searchPlaces(
        query: 'top rated places',
        lat: _userLat,
        lng: _userLng,
      );
      if (mounted) {
        setState(() {
          // Only show places within 5km and with rating >= 4
          _nearbyResults = results.where((p) {
            if (p.lat == null) return false;
            final dist = Geolocator.distanceBetween(
              _userLat!, _userLng!, p.lat!, p.lng!,
            );
            return dist <= 10000 && (p.rating ?? 0) >= 3.0;
          }).take(10).toList();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingNearby = false);
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (value.trim().length >= 2) {
        _search(value);
      }
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final results = await _placesService.searchPlaces(
      query: query,
      lat: _userLat,
      lng: _userLng,
    );

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    setState(() {
      _results = [];
      _hasSearched = false;
      _isLoading = false;
    });
  }

  String _getDistance(PlaceResult place) {
    if (_userLat == null || place.lat == null) return '';
    final dist = Geolocator.distanceBetween(
      _userLat!, _userLng!, place.lat!, place.lng!,
    );
    if (dist < 1000) return '${dist.toStringAsFixed(0)} m';
    return '${(dist / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? AppColors.accent.withOpacity(0.5)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white),
                  onChanged: _onSearchChanged,
                  onSubmitted: _search,
                  onTap: () => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search places, restaurants...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(13),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
                          )
                        : const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results count
            if (_hasSearched && !_isLoading && _results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${_results.length} places found',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      'near you',
                      style: TextStyle(
                        color: AppColors.accent.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // Body
            Expanded(
              child: !_hasSearched
                  ? _buildDiscoverView()
                  : _isLoading
                      ? _buildLoadingShimmer()
                      : _results.isEmpty
                          ? _buildNoResults()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _results.length,
                              itemBuilder: (context, i) =>
                                  _buildPlaceCard(_results[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Discover View (before search) ───────────────────────────────────────

  Widget _buildDiscoverView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick filter chips
          _buildQuickFilters(),

          const SizedBox(height: 28),

          // Nearby section
          _buildNearbySection(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    final filters = [
      {'label': 'Nearby', 'icon': Icons.near_me, 'isNearby': true},
      {'label': 'Restaurants', 'icon': Icons.restaurant, 'isNearby': false},
      {'label': 'Cafes', 'icon': Icons.coffee, 'isNearby': false},
      {'label': 'Parks', 'icon': Icons.park, 'isNearby': false},
      {'label': 'Hotels', 'icon': Icons.hotel, 'isNearby': false},
      {'label': 'Malls', 'icon': Icons.shopping_bag, 'isNearby': false},
      {'label': 'Museums', 'icon': Icons.museum, 'isNearby': false},
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final f = filters[i];
          final isNearby = f['isNearby'] as bool;
          final label = f['label'] as String;
          final icon = f['icon'] as IconData;

          return GestureDetector(
            onTap: () {
              if (isNearby) {
                // Scroll to nearby section — already visible, just clear search
                _clearSearch();
              } else {
                _searchController.text = label;
                _search(label);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                // Nearby chip is more prominent
                color: isNearby ? AppColors.accent : AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: isNearby
                    ? null
                    : Border.all(
                        color: AppColors.accent.withOpacity(0.25),
                        width: 1,
                      ),
                boxShadow: isNearby
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isNearby ? AppColors.bg : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isNearby ? AppColors.bg : Colors.white70,
                      fontSize: 13,
                      fontWeight: isNearby ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.near_me,
                color: AppColors.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Nearby Places',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_userLat != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Within 10km',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 4),

        const Text(
          'Top rated spots around you',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),

        const SizedBox(height: 16),

        // Nearby content
        if (_isLoadingNearby)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (_, __) => _buildNearbyShimmerCard(),
            ),
          )
        else if (_userLat == null)
          _buildLocationPermissionCard()
        else if (_nearbyResults.isEmpty)
          _buildNoNearbyCard()
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyResults.length,
              itemBuilder: (context, i) =>
                  _buildNearbyCard(_nearbyResults[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildNearbyCard(PlaceResult place) {
    final distance = _getDistance(place);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationDetailScreen(place: place),
        ),
      ),
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: place.photoReference != null
                    ? Image.network(
                        _placesService.getPhotoUrl(place.photoReference!),
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: AppColors.input,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.input,
                          child: const Icon(Icons.image,
                              color: Colors.white24, size: 32),
                        ),
                      )
                    : Container(
                        color: AppColors.input,
                        child: const Icon(Icons.image,
                            color: Colors.white24, size: 32),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Rating + distance row
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${place.rating ?? 0}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (distance.isNotEmpty) ...[
                        const Icon(Icons.near_me,
                            color: AppColors.accent, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          distance,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyShimmerCard() {
    return Container(
      width: 175,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 120, height: 12),
                const SizedBox(height: 8),
                _shimmerBox(width: 80, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off,
                color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location needed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enable location to see nearby places',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoNearbyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'No highly rated places found nearby.\nTry searching manually above.',
          style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ─── Search Results ───────────────────────────────────────────────────────

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 110,
              decoration: const BoxDecoration(
                color: AppColors.input,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _shimmerBox(width: 140, height: 14),
                    const SizedBox(height: 10),
                    _shimmerBox(width: 100, height: 10),
                    const SizedBox(height: 10),
                    _shimmerBox(width: 60, height: 10),
                    const SizedBox(height: 14),
                    _shimmerBox(width: double.infinity, height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.input.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off,
                color: Colors.white24, size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'No places found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for "${_searchController.text}"\nwith different keywords',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(PlaceResult place) {
    final distance = _getDistance(place);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationDetailScreen(place: place),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 110,
                height: 130,
                child: place.photoReference != null
                    ? Image.network(
                        _placesService.getPhotoUrl(place.photoReference!),
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: AppColors.input,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final rating = place.rating ?? 0;
                          return Icon(
                            i < rating.floor()
                                ? Icons.star
                                : i < rating
                                    ? Icons.star_half
                                    : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '(${place.userRatingsTotal ?? 0})',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_outline,
                            color: AppColors.accent, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (distance.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white54, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            distance,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationDetailScreen(place: place),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Add Review',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
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

  Widget _placeholderImage() {
    return Container(
      color: AppColors.input,
      child: const Icon(Icons.image, color: Colors.white24, size: 40),
    );
  }
}