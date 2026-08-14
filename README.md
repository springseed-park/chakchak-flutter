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

실제 Google 로그인은 `http://` 또는 `https://`에서만 동작합니다. `file://`로 HTML을 직접 열지 마세요.

## 빌드

```bash
flutter build web --release
flutter build appbundle --release
```

Android 릴리스 서명은 [android/key.properties.example](android/key.properties.example)을 참고합니다. 실제 키스토어와 비밀번호 파일은 Git에서 제외됩니다.

## 현재 상태

- 반응형 Flutter 랜딩 화면
- 온보딩, 홈, 옷장, 코디 메이트, 마이페이지 프로토타입 구조
- Paperlogy 폰트 및 착착 캐릭터·의류 에셋
- Android·Web 플랫폼 기본 프로젝트
- Firebase 프로젝트 `chakchakchakchak`의 Android·Web 앱 설정
- Firebase Authentication 기반 실제 Google 로그인과 세션 복원
- Firebase callable Functions 기반 Groq AI·기상청 API 프록시
- 위치 권한 요청, 시·동 역지오코딩, 기상청 예보 UI 연결
- 업로드 키 서명 구조와 개인정보 처리방침·이용약관 초안

API 키는 앱 번들에 포함하지 않습니다. Functions 코드는 준비됐지만 실제 Secret Manager와 Functions 배포에는 Firebase Blaze 요금제가 필요하므로 현재 배포하지 않았습니다.

## Firebase 서버 준비

```bash
cd functions
npm install
npm run lint
cd ..
firebase functions:secrets:set GROQ_API_KEY
firebase functions:secrets:set KMA_API_KEY
firebase deploy --only functions
```

Firestore는 서울 리전(`asia-northeast3`) 생성 여부를 최종 확정한 뒤 활성화하고 `users/{uid}` 사용자별 규칙을 배포합니다.

## 출시 전 문서

- [출시 준비 체크리스트](docs/release-readiness.md)
- [Play Console 데이터 보안 작성 기준](docs/play-data-safety.md)
- [개인정보 처리방침 초안](legal/public/index.html)
- [서비스 이용약관 초안](legal/public/terms.html)
