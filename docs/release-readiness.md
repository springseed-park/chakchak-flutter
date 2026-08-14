# 착착 Android 출시 준비 체크리스트

현재는 앱을 Play Store에 공개하지 않고 출시 가능한 구조만 준비한다.

## 완료된 준비

- [x] Flutter 3.47.0 / Dart 3.13 프로젝트 분리
- [x] Android 패키지명 `com.springseed.chakchak`
- [x] Android Studio 및 Android 명령줄 도구 설치
- [x] Firebase Android·Web 앱 등록 및 `google-services.json` 생성
- [x] Firebase Google 로그인 코드 연결
- [x] 신규 가입 약관 동의, 기존 사용자 세션 복원, 로그아웃·탈퇴 흐름
- [x] Groq AI·기상청 API를 앱 밖에서 호출하는 Firebase Functions 코드
- [x] 위치 권한·역지오코딩·기상청 날씨 UI 연결
- [x] API 키가 소스와 앱 번들에 들어가지 않는 Secret Manager 구조
- [x] Android 업로드 키 서명 Gradle 구조 및 생성 스크립트
- [x] 개인정보 처리방침·이용약관 초안과 별도 Hosting 사이트 확보
- [x] Flutter 테스트, 릴리스 웹 빌드, Functions lint 통과

## 기능 완성 후 실행할 작업

1. Android Studio에서 Android SDK License를 본인 명의로 동의한다.
2. SDK Platform 36, Build-tools 36.0.0, Platform-tools를 설치한다.
3. Firebase를 Blaze 요금제로 전환할지 비용 알림·예산과 함께 결정한다.
4. Groq/KMA 값을 Firebase Secret Manager에 등록하고 Functions를 배포한다.
5. Firestore 리전을 `asia-northeast3`으로 확정해 데이터베이스와 보안 규칙을 만든다.
6. 공개 문의 이메일을 방침 문서의 `REPLACE_WITH_PUBLIC_SUPPORT_EMAIL`에 입력하고 Hosting에 배포한다.
7. `scripts/create_upload_keystore.sh`를 실행해 업로드 키를 만들고 별도 안전한 장소에 백업한다.
8. `flutter build appbundle --release`로 서명된 AAB를 생성한다.
9. Play Console 개발자 계정 유형(개인/조직)을 결정하고 등록비 결제를 완료한다.
10. 앱 콘텐츠, 데이터 보안, 광고, 연령, 타깃층, 접근 권한과 스토어 등록정보를 작성한다.
11. 내부 테스트 트랙에 AAB를 올리고 실제 Android 기기에서 로그인·위치·사진·AI·탈퇴를 검증한다.
12. 비공개/공개 테스트 요건을 충족한 뒤 프로덕션 출시를 신청한다.

## 현재 외부 상태

- Firebase 프로젝트: `chakchakchakchak`
- 개인정보 처리방침용 Hosting 사이트: `https://chakchak-privacy.web.app` (사이트만 생성, 콘텐츠 미배포)
- Play Console: 개발자 계정 생성 전 단계(변경 없음)
- Functions: 코드만 준비, 비밀키·함수 미배포
- Firestore: 미생성

## 중요 보안 원칙

- `.env.local`, `android/key.properties`, `*.jks`는 절대 Git에 커밋하지 않는다.
- 클라이언트에서 Groq/KMA REST API를 직접 호출하지 않는다.
- Firebase Functions에는 인증 검증, 입력 길이 제한과 향후 App Check를 적용한다.
- 업로드 키와 비밀번호는 서로 분리해 백업한다.
