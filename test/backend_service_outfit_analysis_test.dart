import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:chakchak/services/backend_service.dart';

void main() {
  test('Cloudflare의 nested analysis 응답에서 옷과 좌표를 읽는다', () async {
    final client = MockClient((request) async => http.Response(
          jsonEncode({
            'ok': true,
            'analysis': {
              'summary': '상의와 하의를 찾았어요.',
              'items': [
                {
                  'name': '블랙 반팔티',
                  'category': '상의',
                  'detailCategory': '반팔티',
                  'color': '블랙',
                  'fit': '기본',
                  'preciseColor': 'Dark Chocolate Brown',
                  'colorHex': '#3B2416',
                  'materialTexture': 'Smooth Cotton',
                  'fitDescription': 'Slim fit',
                  'necklineOrWaist': 'Crew neck',
                  'englishPrompt':
                      'A dark chocolate brown slim-fit short-sleeve t-shirt',
                  'confidence': 0.94,
                  'matchedGarmentId': 'garment-black-tee',
                  'box': {
                    'x': 0.1,
                    'y': 0.2,
                    'width': 0.5,
                    'height': 0.3,
                  },
                  'mask': [
                    [0.1, 0.2],
                    [0.6, 0.2],
                    [0.6, 0.5],
                  ],
                },
              ],
            },
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ));
    final service = BackendService(
      httpClient: client,
      outfitAnalysisApiUrl: 'https://example.com/api/outfit-analysis',
    );

    final result = await service.analyzeOutfitPhoto(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/png',
    );

    expect(result.summary, '상의와 하의를 찾았어요.');
    expect(result.items, hasLength(1));
    expect(result.items.single.name, '블랙 반팔티');
    expect(result.items.single.matchedGarmentId, 'garment-black-tee');
    expect(result.items.single.box.width, 0.5);
    expect(result.items.single.mask, hasLength(3));
    expect(result.items.single.mask.first.x, 0.1);
    expect(result.items.single.preciseColor, 'Dark Chocolate Brown');
    expect(result.items.single.colorHex, '#3B2416');
    expect(result.items.single.materialTexture, 'Smooth Cotton');
    expect(result.items.single.fitDescription, 'Slim fit');
    expect(result.items.single.necklineOrWaist, 'Crew neck');
  });

  test('객체 형태의 error 응답에서 사용자 메시지를 안전하게 읽는다', () async {
    final client = MockClient((request) async => http.Response(
          jsonEncode({
            'ok': false,
            'error': {
              'code': 'ai_rate_limited',
              'message': 'AI 요청 한도를 잠시 넘었어요.',
            },
          }),
          429,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ));
    final service = BackendService(
      httpClient: client,
      outfitAnalysisApiUrl: 'https://example.com/api/outfit-analysis',
    );

    expect(
      service.analyzeOutfitPhoto(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/jpeg',
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'AI 요청 한도를 잠시 넘었어요.',
        ),
      ),
    );
  });

  test('수정한 옷 속성으로 스튜디오 상품컷을 재생성한다', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/outfit-generation');
      final payload = Map<String, dynamic>.from(
        jsonDecode(request.body) as Map,
      );
      final item = Map<String, dynamic>.from(payload['item'] as Map);
      expect(item['colorHex'], '#3B2416');
      expect(item['englishPrompt'], contains('dark chocolate brown'));
      return http.Response(
        jsonEncode({
          'ok': true,
          'generatedImage': {
            'imageBase64': base64Encode([1, 2, 3, 4]),
            'mimeType': 'image/png',
            'prompt': 'studio product shot',
          },
        }),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = BackendService(
      httpClient: client,
      outfitAnalysisApiUrl: 'https://example.com/api/outfit-analysis',
    );

    final generated = await service.generateGarmentStudioImage(
      garment: const DetectedGarment(
        name: '브라운 반팔티',
        category: '상의',
        detailCategory: '반팔티',
        color: '브라운',
        fit: '슬림',
        preciseColor: 'Dark Chocolate Brown',
        colorHex: '#3B2416',
        materialTexture: 'Smooth Cotton',
        fitDescription: 'Slim fit',
        necklineOrWaist: 'Crew neck',
        englishPrompt: 'A dark chocolate brown slim-fit short-sleeve t-shirt',
        confidence: 0.95,
        box: NormalizedImageBox(x: 0, y: 0, width: 1, height: 1),
      ),
    );

    expect(base64Decode(generated.imageBase64), [1, 2, 3, 4]);
    expect(generated.mimeType, 'image/png');
    expect(generated.prompt, 'studio product shot');
  });
}
