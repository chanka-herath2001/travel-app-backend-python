import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlacesService {
  final Dio _dio = Dio();
  final _supabase = Supabase.instance.client;
  
  // Replace with your actual API key
  static const String _apiKey = 'AIzaSyDEwYEwLGvlfFAfxb572PFnUf-vEblNKYc';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Search places by text query
  Future<List<PlaceResult>> searchPlaces({
    required String query,
    double? lat,
    double? lng,
  }) async {
    try {
      String url = '$_baseUrl/textsearch/json?query=$query&key=$_apiKey';
      
      if (lat != null && lng != null) {
        url += '&location=$lat,$lng&radius=10000';
      }

      final response = await _dio.get(url);
      final data = response.data;

      if (data['status'] == 'OK') {
        final results = data['results'] as List;
        return results.map((r) => PlaceResult.fromJson(r)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get place details by place_id
  Future<PlaceDetail?> getPlaceDetails(String placeId) async {
    try {
      final url = '$_baseUrl/details/json?place_id=$placeId'
          '&fields=name,formatted_address,geometry,photos,rating,'
          'user_ratings_total,reviews,formatted_phone_number,website,opening_hours'
          '&key=$_apiKey';

      final response = await _dio.get(url);
      final data = response.data;

      if (data['status'] == 'OK') {
        return PlaceDetail.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get photo URL from photo reference
  String getPhotoUrl(String photoReference, {int maxWidth = 800}) {
    return '$_baseUrl/photo?maxwidth=$maxWidth'
        '&photo_reference=$photoReference&key=$_apiKey';
  }

  // Save or get location from Supabase
  Future<String> saveLocationToSupabase({
    required PlaceDetail place,
    required String googlePlaceId,
  }) async {
    try {
      // Check if already exists
      final existing = await _supabase
          .from('locations')
          .select('id')
          .eq('google_place_id', googlePlaceId)
          .maybeSingle();

      if (existing != null) return existing['id'];

      // Insert new location
      final result = await _supabase.from('locations').insert({
        'name': place.name,
        'category': place.types?.isNotEmpty == true ? place.types!.first : 'other',
        'google_place_id': googlePlaceId,
        'coordinates': 'POINT(${place.lng} ${place.lat})',
      }).select('id').single();

      final locationId = result['id'];

      // Save photos
      if (place.photos != null) {
        for (int i = 0; i < place.photos!.length && i < 5; i++) {
          await _supabase.from('location_photos').insert({
            'location_id': locationId,
            'url': getPhotoUrl(place.photos![i]),
            'source': 'google',
            'sort_order': i,
          });
        }
      }

      return locationId;
    } catch (e) {
      rethrow;
    }
  }

  // Get reviews for a location
  Future<List<Map<String, dynamic>>> getReviews(String locationId) async {
  try {
    final data = await _supabase
        .from('reviews')
        .select('id, rating, content, created_at, user_id')
        .eq('location_id', locationId)
        .order('created_at', ascending: false);

    // For each review, fetch the profile separately
    final List<Map<String, dynamic>> enriched = [];
    for (final review in data) {
      Map<String, dynamic> profile = {};
      try {
        final p = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', review['user_id'])
            .maybeSingle();
        profile = p ?? {};
      } catch (_) {}

      enriched.add({...review, 'profiles': profile});
    }
    return enriched;
    } catch (e) {
      return [];
    }
  }

  // Add review
  Future<void> addReview({
    required String locationId,
    required int rating,
    required String content,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('reviews').insert({
      'user_id': userId,
      'location_id': locationId,
      'rating': rating,
      'content': content,
    });
  }

  // Toggle bucket list
  Future<bool> toggleBucketList(String locationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final existing = await _supabase
          .from('bucket_list')
          .select()
          .eq('user_id', userId)
          .eq('location_id', locationId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('bucket_list')
            .delete()
            .eq('user_id', userId)
            .eq('location_id', locationId);
        return false;
      } else {
        await _supabase.from('bucket_list').insert({
          'user_id': userId,
          'location_id': locationId,
        });
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  // Check if in bucket list
  Future<bool> isInBucketList(String locationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final result = await _supabase
        .from('bucket_list')
        .select()
        .eq('user_id', userId)
        .eq('location_id', locationId)
        .maybeSingle();

    return result != null;
  }
}

// Models
class PlaceResult {
  final String placeId;
  final String name;
  final String? address;
  final double? rating;
  final int? userRatingsTotal;
  final String? photoReference;
  final double? lat;
  final double? lng;
  final List<String>? types;

  PlaceResult({
    required this.placeId,
    required this.name,
    this.address,
    this.rating,
    this.userRatingsTotal,
    this.photoReference,
    this.lat,
    this.lng,
    this.types,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? json['vicinity'],
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      photoReference: json['photos'] != null
          ? json['photos'][0]['photo_reference']
          : null,
      lat: json['geometry']?['location']?['lat']?.toDouble(),
      lng: json['geometry']?['location']?['lng']?.toDouble(),
      types: json['types'] != null
          ? List<String>.from(json['types'])
          : null,
    );
  }
}

class PlaceDetail {
  final String name;
  final String? address;
  final double? rating;
  final int? userRatingsTotal;
  final List<String>? photos;
  final double? lat;
  final double? lng;
  final List<String>? types;
  final String? phoneNumber;
  final String? website;

  PlaceDetail({
    required this.name,
    this.address,
    this.rating,
    this.userRatingsTotal,
    this.photos,
    this.lat,
    this.lng,
    this.types,
    this.phoneNumber,
    this.website,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    List<String>? photoRefs;
    if (json['photos'] != null) {
      photoRefs = (json['photos'] as List)
          .map((p) => p['photo_reference'] as String)
          .toList();
    }

    return PlaceDetail(
      name: json['name'] ?? '',
      address: json['formatted_address'],
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      photos: photoRefs,
      lat: json['geometry']?['location']?['lat']?.toDouble(),
      lng: json['geometry']?['location']?['lng']?.toDouble(),
      types: json['types'] != null ? List<String>.from(json['types']) : null,
      phoneNumber: json['formatted_phone_number'],
      website: json['website'],
    );
  }
}