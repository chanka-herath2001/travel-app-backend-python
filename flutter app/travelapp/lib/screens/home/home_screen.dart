import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../utils/contants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();

  String _selectedCategory = 'All';
  String _displayName = '';
  LatLng _currentLocation = const LatLng(6.9271, 79.8612);
  bool _locationLoaded = false;
  List<Map<String, dynamic>> _bucketListLocations = [];
  bool _loadingBucket = false;

  final List<String> _categories = ['All', 'Favourites', 'Bucket List'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLocation();
    _loadBucketList();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .single();
      setState(() => _displayName = data['display_name'] ?? 'Traveller');
    } catch (_) {
      setState(() => _displayName = 'Traveller');
    }
  }

  Future<void> _loadLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
      });
      _mapController.move(_currentLocation, 14);
    } catch (_) {}
  }

  Future<void> _loadBucketList() async {
  setState(() => _loadingBucket = true);
  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // First get bucket list location IDs
    final bucketData = await supabase
        .from('bucket_list')
        .select('location_id')
        .eq('user_id', userId);

    if (bucketData.isEmpty) {
      setState(() => _bucketListLocations = []);
      return;
    }

    final locationIds = bucketData
        .map((b) => b['location_id'] as String)
        .toList();

    // Fetch locations with GeoJSON coordinates using the view
    final locData = await supabase
        .from('locations_with_coords')
        .select('id, name, coordinates')
        .inFilter('id', locationIds);

    setState(() => _bucketListLocations = 
        List<Map<String, dynamic>>.from(locData));
        debugPrint('Bucket locations raw: $locData');
  } catch (e) {
    debugPrint('Bucket list error: $e');
  } finally {
    setState(() => _loadingBucket = false);
  }
}

  // Parse PostGIS point to LatLng
  LatLng? _parseCoordinates(dynamic coordinates) {
  try {
    if (coordinates == null) return null;

    Map<String, dynamic>? geoJson;

    // Handle if it comes back as a String
    if (coordinates is String) {
      geoJson = Map<String, dynamic>.from(
        jsonDecode(coordinates),
      );
    } else if (coordinates is Map) {
      geoJson = Map<String, dynamic>.from(coordinates);
    }

    if (geoJson == null) return null;

    final coords = geoJson['coordinates'];
    if (coords != null && coords.length >= 2) {
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();

      // Validate coordinates are reasonable
      if (lat.abs() <= 90 && lng.abs() <= 180) {
        return LatLng(lat, lng);
      }
    }
    return null;
  } catch (e) {
    debugPrint('Coordinate parse error: $e');
    return null;
  }
}

  List<Map<String, dynamic>> get _filteredLocations {
    // Both 'All' and 'Bucket List' show bucket list items
    // 'Favourites' shows empty for now
    if (_selectedCategory == 'Favourites') return [];
    return _bucketListLocations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Welcome text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back${_displayName.isNotEmpty ? ' $_displayName' : ''}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Browse all your saved locations',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Category tabs
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? AppColors.bg : Colors.white,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Map
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.travel.travelapp',
                        ),

                        // Bucket list markers
                        MarkerLayer(
                          markers: [
                            // Current location
                            if (_locationLoaded)
                              Marker(
                                point: _currentLocation,
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppColors.accent.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_pin,
                                    color: Color(0xFF0D3B6E),
                                    size: 22,
                                  ),
                                ),
                              ),

                            // Bucket list location markers
                            ..._filteredLocations.map((loc) {
                              final coords =
                                  _parseCoordinates(loc['coordinates']);
                              if (coords == null) return null;
                              return Marker(
                                point: coords,
                                width: 44,
                                height: 44,
                                child: GestureDetector(
                                  onTap: () =>
                                      _showLocationPopup(context, loc),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.accent, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.bookmark,
                                      color: AppColors.accent,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              );
                            }).whereType<Marker>().toList(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bucket list count badge
                  if (_filteredLocations.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: AppColors.accent, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bookmark,
                                color: AppColors.accent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${_filteredLocations.length} saved',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Empty state for Favourites tab
                  if (_selectedCategory == 'Favourites')
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite_border,
                                    color: AppColors.accent, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'Favourites coming soon',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'This feature is being worked on',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showLocationPopup(BuildContext context, Map<String, dynamic> loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc['name'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Saved to your bucket list',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}