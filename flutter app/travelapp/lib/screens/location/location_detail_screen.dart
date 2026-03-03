import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:latlong2/latlong.dart';
import '../../services/places_service.dart';
import '../../utils/contants.dart';

class LocationDetailScreen extends StatefulWidget {
  final PlaceResult place;

  const LocationDetailScreen({super.key, required this.place});

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  final _placesService = PlacesService();
  final _reviewController = TextEditingController();

  PlaceDetail? _detail;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _isInBucketList = false;
  bool _showReviewForm = false;
  double _reviewRating = 4;
  String? _supabaseLocationId;
  bool _submittingReview = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    final detail = await _placesService.getPlaceDetails(widget.place.placeId);

    if (detail != null) {
      // Save to Supabase and get location ID
      try {
        final locationId = await _placesService.saveLocationToSupabase(
          place: detail,
          googlePlaceId: widget.place.placeId,
        );
        _supabaseLocationId = locationId;

        final [reviews, inBucket] = await Future.wait([
          _placesService.getReviews(locationId),
          _placesService.isInBucketList(locationId),
        ]);

        setState(() {
          _detail = detail;
          _reviews = reviews as List<Map<String, dynamic>>;
          _isInBucketList = inBucket as bool;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBucketList() async {
    if (_supabaseLocationId == null) return;
    final result = await _placesService.toggleBucketList(_supabaseLocationId!);
    setState(() => _isInBucketList = result);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result ? 'Added to Bucket List! 🌟' : 'Removed from Bucket List',
        ),
        backgroundColor: result ? Colors.green : Colors.grey,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty || _supabaseLocationId == null) return;

    setState(() => _submittingReview = true);
    try {
      await _placesService.addReview(
        locationId: _supabaseLocationId!,
        rating: _reviewRating.round(),
        content: _reviewController.text.trim(),
      );

      final reviews = await _placesService.getReviews(_supabaseLocationId!);
      setState(() {
        _reviews = reviews;
        _showReviewForm = false;
        _reviewController.clear();
        _reviewRating = 4;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted! ✅'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit review'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _submittingReview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final detail = _detail;
    final lat = widget.place.lat ?? 6.9271;
    final lng = widget.place.lng ?? 79.8612;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo carousel
            Stack(
              children: [
                _buildPhotoCarousel(detail),

                // Back button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    widget.place.name,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Address & Rating
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white54, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          detail?.address ?? widget.place.address ?? '',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.place.rating ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' (${widget.place.userRatingsTotal ?? 0})',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Mini Map
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 180,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(lat, lng),
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.travel.travelapp',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(lat, lng),
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Start Journey
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: open maps navigation
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text(
                              'Start Journey',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.bg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Bucket List toggle
                      GestureDetector(
                        onTap: _toggleBucketList,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _isInBucketList
                                ? AppColors.accent
                                : AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _isInBucketList
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: _isInBucketList ? AppColors.bg : AppColors.accent,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _showReviewForm = !_showReviewForm),
                        icon: Icon(
                          _showReviewForm ? Icons.close : Icons.add,
                          color: AppColors.accent,
                          size: 18,
                        ),
                        label: Text(
                          _showReviewForm ? 'Cancel' : 'Add Review',
                          style: const TextStyle(color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),

                  // Review Form
                  if (_showReviewForm) _buildReviewForm(),

                  const SizedBox(height: 12),

                  // Reviews List
                  if (_reviews.isEmpty && !_showReviewForm)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No reviews yet. Be the first!',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    )
                  else
                    ..._reviews.map((r) => _buildReviewCard(r)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel(PlaceDetail? detail) {
    final photos = detail?.photos;

    if (photos == null || photos.isEmpty) {
      return Container(
        height: 280,
        color: AppColors.card,
        child: const Center(
          child: Icon(Icons.image, color: Colors.white24, size: 64),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 280,
        viewportFraction: 1.0,
        enableInfiniteScroll: photos.length > 1,
        autoPlay: photos.length > 1,
        autoPlayInterval: const Duration(seconds: 4),
      ),
      items: photos.take(5).map((ref) {
        return Image.network(
          _placesService.getPhotoUrl(ref),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.card,
            child: const Icon(Icons.image, color: Colors.white24, size: 64),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewForm() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Rating',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          RatingBar.builder(
            initialRating: _reviewRating,
            minRating: 1,
            maxRating: 5,
            allowHalfRating: false,
            itemSize: 32,
            itemBuilder: (_, __) =>
                const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (r) => setState(() => _reviewRating = r),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _reviewController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _submittingReview ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submittingReview
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.bg,
                      ),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
  final profile = review['profiles'];
  final username = profile?['display_name'] ?? 'Anonymous';
  final rating = review['rating'] ?? 0;
  final content = review['content'] ?? '';
  final createdAt = review['created_at'] != null
      ? DateTime.parse(review['created_at'])
      : null;

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.input,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
}