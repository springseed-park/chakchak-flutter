# 착착 (CHAKCHAK) Flutter

내 옷장, 오늘의 날씨와 일정을 바탕으로 코디를 추천하는 착착의 Flutter 앱입니다.

## 목표 플랫폼

- Android: Google Play 배포용 App Bundle
- Web: 포트폴리오 및 기능 시연

Android 패키지명은 현재 `com.springseed.chakchak`입니다. Google Play에 최초 등록하기 전 최종 확정해야 합니다.

## 실행

```bash
flutter pub get
flutter run -d chrome
```

## 빌드

```bash
flutter build web --release
flutter build appbundle --release
```

## 현재 상태

- 반응형 Flutter 랜딩 화면
- 온보딩, 홈, 옷장, 코디 메이트, 마이페이지 프로토타입 구조
- Paperlogy 폰트 및 착착 캐릭터·의류 에셋
- Android·Web 플랫폼 기본 프로젝트

Firebase Authentication, 실제 날씨 API와 AI 서버리스 API는 다음 단계에서 Flutter 패키지와 플랫폼 설정으로 연결합니다. API 키는 앱 번들에 포함하지 않습니다.
