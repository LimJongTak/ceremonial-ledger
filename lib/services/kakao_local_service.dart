import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/kakao_config.dart';

// ── 카카오 API 예외 ───────────────────────────────────────────
class KakaoApiException implements Exception {
  final int statusCode;
  final String message;
  const KakaoApiException(this.statusCode, this.message);
}

// ── 카카오 장소 검색 결과 모델 ────────────────────────────────
class KakaoPlace {
  final String placeName;
  final String addressName;
  final String roadAddressName;
  final String categoryName;

  const KakaoPlace({
    required this.placeName,
    required this.addressName,
    required this.roadAddressName,
    required this.categoryName,
  });

  /// 길찾기에 사용할 표시 주소 (도로명 우선)
  String get displayAddress =>
      roadAddressName.isNotEmpty ? roadAddressName : addressName;

  /// DB에 저장될 전체 장소명 (장소명 + 주소)
  String get fullLocation => '$placeName, $displayAddress';

  factory KakaoPlace.fromJson(Map<String, dynamic> json) {
    return KakaoPlace(
      placeName: (json['place_name'] as String?) ?? '',
      addressName: (json['address_name'] as String?) ?? '',
      roadAddressName: (json['road_address_name'] as String?) ?? '',
      categoryName: (json['category_name'] as String?) ?? '',
    );
  }
}

// ── 카카오 로컬 API 서비스 ────────────────────────────────────
class KakaoLocalService {
  KakaoLocalService._();
  static final instance = KakaoLocalService._();

  static const _baseUrl =
      'https://dapi.kakao.com/v2/local/search/keyword.json';

  /// 키워드로 장소 검색 (최대 5개)
  Future<List<KakaoPlace>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'query': query,
          'size': '5',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'KakaoAK ${KakaoConfig.restApiKey}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final documents = (data['documents'] as List<dynamic>? ?? []);
        return documents
            .map((e) => KakaoPlace.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('카카오 장소 검색 오류: ${response.statusCode} ${response.body}');
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        final msg = (body?['message'] as String?) ?? '';
        throw KakaoApiException(response.statusCode, msg);
      }
    } on KakaoApiException {
      rethrow;
    } catch (e) {
      debugPrint('카카오 장소 검색 예외: $e');
      throw KakaoApiException(0, e.toString());
    }
  }
}
