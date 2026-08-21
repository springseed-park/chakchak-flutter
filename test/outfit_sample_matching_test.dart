import 'package:chakchak/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI 세부 스타일을 가장 가까운 옷 샘플로 연결한다', () {
    expect(
      garmentSampleForDetectedStyle(
        category: '상의',
        detailCategory: '반팔 티셔츠',
        fit: '슬림',
      )?.detailCategory,
      '반팔티',
    );
    expect(
      garmentSampleForDetectedStyle(
        category: '상의',
        detailCategory: '반팔 티셔츠',
        fit: '슬림',
      )?.assetPath,
      'assets/garment_samples/female_tshirt_slim_shortsleeve.png',
    );
    expect(
      garmentSampleForDetectedStyle(
        category: '상의',
        detailCategory: '반팔 티셔츠',
        fit: '루즈',
      )?.assetPath,
      'assets/garment_samples/unisex_tshirt_oversized_shortsleeve.png',
    );
    expect(
      garmentSampleForDetectedStyle(
        category: '상의',
        detailCategory: '크롭 티셔츠',
        fit: '루즈',
      )?.assetPath,
      'assets/garment_samples/female_tshirt_boxy_cropped_shortsleeve.png',
    );
    expect(
      garmentSampleForDetectedStyle(
        category: '아우터',
        detailCategory: '윈드브레이커',
      )?.detailCategory,
      '바람막이',
    );
    expect(
      garmentSampleForDetectedStyle(
        category: '하의',
        detailCategory: '스커트',
      )?.assetPath,
      'assets/garment_samples/female_skirt_hline_midi.png',
    );
    expect(
      garmentSampleForDetectedStyle(
        category: '하의',
        detailCategory: '플레어 미디 스커트',
      )?.assetPath,
      'assets/garment_samples/female_skirt_flared_midi.png',
    );
  });

  test('AI 색상명을 샘플 컬러라이징 색으로 변환한다', () {
    expect(garmentTintForAnalysisColor('다크 브라운'), const Color(0xFF8B6247));
    expect(garmentTintForAnalysisColor('라이트 데님'), const Color(0xFF739BC2));
    expect(garmentTintForAnalysisColor('검정'), const Color(0xFF25292C));
  });

  test('세부 종류와 핏이 같은 샘플이 없으면 사진 크롭을 사용한다', () {
    expect(
      garmentSampleForDetectedStyle(
        category: '상의',
        detailCategory: '긴팔티',
        fit: '루즈',
      ),
      isNull,
    );
    expect(
      garmentSampleForDetectedStyle(
        category: '상의',
        detailCategory: '니트',
        fit: '기본',
      ),
      isNull,
    );
  });
}
