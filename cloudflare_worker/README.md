# 착착 의류 사진 분석 Worker

사용자가 올린 착장 사진을 Gemini 비전 모델로 분석해 상의·하의·아우터·신발 등을 찾고, 앱이 각 옷을 잘라 저장할 수 있도록 정규화된 좌표를 반환하는 Cloudflare Worker입니다.

사진 원본과 API 키는 저장하지 않습니다. Gemini API 키는 소스나 `wrangler.jsonc`에 넣지 않고 Cloudflare Secret으로만 관리합니다.

## 제공 경로

- `GET /health`: 서비스 상태 확인
- `POST /api/outfit-analysis`: 착장 사진 분석

브라우저 요청은 다음 출처만 허용합니다.

- `http://127.0.0.1:4180`
- `http://localhost:4180`
- `https://chakchak-flutter.pages.dev`

## 최초 준비

```bash
cd cloudflare_worker
npm install
npm run check
npm test
npm run types
```

## 로컬 실행

`.dev.vars.example`을 `.dev.vars`로 복사하고 로컬 개발용 Gemini 키를 입력한 뒤 실행합니다. `.dev.vars`는 Git에서 제외됩니다.

```bash
cp .dev.vars.example .dev.vars
npm run dev
```

로컬 주소는 `http://127.0.0.1:8787`입니다.

## Cloudflare 비밀키 등록

Worker를 처음 배포하기 전 또는 키를 교체할 때 아래 명령을 실행하고, 프롬프트가 뜨면 Gemini 키 값만 붙여 넣습니다.

```bash
npx wrangler secret put GEMINI_API_KEY
```

이 명령은 키를 암호화된 Secret으로 저장하며 저장 후 실제 값은 다시 표시되지 않습니다.

## 검증 및 배포

```bash
npm run deploy:dry
npm run deploy
```

배포 후 출력되는 Worker 주소에 `/health`를 붙여 상태를 확인합니다. Flutter 빌드에는 이 Worker 기본 주소만 전달하고 Gemini 키는 절대 전달하지 않습니다.

## 요청 형식

```json
{
  "imageBase64": "...",
  "mimeType": "image/jpeg",
  "wardrobe": [
    {
      "id": "garment-1",
      "name": "화이트 반팔티",
      "category": "상의",
      "detailCategory": "반팔티",
      "color": "화이트"
    }
  ]
}
```

- 지원 사진: JPG, PNG, WebP
- 사진 최대 크기: 디코딩 기준 8MB
- 옷장 비교 데이터: 최대 120개

응답의 `box`는 원본 사진을 기준으로 `x`, `y`, `width`, `height`가 각각 `0~1`인 좌표입니다. Flutter는 이 좌표로 옷별 이미지를 잘라낼 수 있습니다.
