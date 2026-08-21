const GEMINI_API_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';
const GEMINI_VISION_MODEL = 'gemini-3.6-flash';
const GEMINI_FALLBACK_VISION_MODEL = 'gemini-3.5-flash-lite';
const GEMINI_IMAGE_MODEL = 'gemini-3.1-flash-image';

const MAX_REQUEST_BYTES = 12 * 1024 * 1024;
const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
const MAX_UPSTREAM_RESPONSE_BYTES = 12 * 1024 * 1024;
const UPSTREAM_TIMEOUT_MS = 60_000;

const ALLOWED_ORIGINS = new Set([
  'http://127.0.0.1:4180',
  'http://localhost:4180',
  'https://chakchak-flutter.pages.dev',
]);

const ALLOWED_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
]);

const CATEGORY_DETAILS = Object.freeze({
  '상의': [
    '반팔티',
    '크롭 반팔티',
    '긴팔티',
    '민소매',
    '크롭 민소매',
    '셔츠',
    '데님 셔츠',
    '후드티',
    '후드 집업',
    '가디건',
  ],
  '하의': [
    '반바지',
    '버뮤다 팬츠',
    '스트레이트 팬츠',
    '카고 팬츠',
    '조거 팬츠',
    '와이드 슬랙스',
    '스트레이트 데님',
    'H라인 미디 스커트',
    'H라인 미니 스커트',
    'A라인 미니 스커트',
    '플레어 미디 스커트',
  ],
  '아우터': [
    '롱 코트',
    '숏 코트',
    '패딩 베스트',
    '롱 패딩',
    '숏 패딩',
    '크롭 데님 재킷',
    '트렌치코트',
    '봄버 재킷',
    '윈드브레이커',
    '블레이저',
  ],
  '원피스': ['미디 원피스', '미니 원피스', '롱 원피스'],
  '신발': [
    '로퍼',
    '러닝화',
    '하이탑 스니커즈',
    '로우탑 스니커즈',
    '부츠',
    '샌들',
  ],
  '가방': ['토트백', '숄더백', '크로스백', '백팩', '기타 가방'],
  '액세서리': ['모자', '벨트', '목도리', '주얼리', '기타 액세서리'],
});

const CATEGORY_ALIASES = Object.freeze({
  top: '상의',
  tops: '상의',
  upper: '상의',
  shirt: '상의',
  bottom: '하의',
  bottoms: '하의',
  pants: '하의',
  outer: '아우터',
  outerwear: '아우터',
  jacket: '아우터',
  dress: '원피스',
  shoes: '신발',
  footwear: '신발',
  bag: '가방',
  accessory: '액세서리',
  accessories: '액세서리',
});

const DETAIL_ALIASES = Object.freeze({
  '티셔츠': '반팔티',
  '반팔 티셔츠': '반팔티',
  '크롭 티셔츠': '크롭 반팔티',
  '크롭 반팔 티셔츠': '크롭 반팔티',
  '긴팔 티셔츠': '긴팔티',
  '탱크톱': '민소매',
  '탱크탑': '민소매',
  '크롭 탱크톱': '크롭 민소매',
  '크롭 탱크탑': '크롭 민소매',
  '후드': '후드티',
  '집업 후드': '후드 집업',
  '후드집업': '후드 집업',
  '청셔츠': '데님 셔츠',
  '슬랙스': '와이드 슬랙스',
  '청바지': '스트레이트 데님',
  '데님 팬츠': '스트레이트 데님',
  '스커트': 'H라인 미디 스커트',
  'H라인 스커트': 'H라인 미디 스커트',
  'A라인 스커트': 'A라인 미니 스커트',
  '플레어 스커트': '플레어 미디 스커트',
  '운동화': '러닝화',
  '스니커즈': '로우탑 스니커즈',
  '트렌치 코트': '트렌치코트',
  '바람막이': '윈드브레이커',
  '항공 점퍼': '봄버 재킷',
});

const ALLOWED_FITS = new Set(['슬림', '기본', '루즈']);
const ALLOWED_COLORS = new Set([
  '화이트', '아이보리', '베이지', '브라운', '그레이', '블랙',
  '레드', '핑크', '그린', '블루', '네이비', '기타',
]);

class HttpError extends Error {
  constructor(status, code, message) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
    this.code = code;
  }
}

export default {
  async fetch(request, env) {
    const requestId = crypto.randomUUID();
    const origin = request.headers.get('Origin');
    const corsHeaders = corsHeadersFor(origin);

    if (request.method === 'OPTIONS') {
      if (!origin || !ALLOWED_ORIGINS.has(origin)) {
        return jsonResponse(
          { ok: false, error: { code: 'origin_not_allowed', message: '허용되지 않은 요청 출처입니다.' } },
          403,
          requestId,
        );
      }

      return new Response(null, {
        status: 204,
        headers: corsHeaders,
      });
    }

    const url = new URL(request.url);
    if (request.method === 'GET' && url.pathname === '/health') {
      return jsonResponse(
        {
          ok: true,
          service: 'chakchak-ai-api',
          visionModel: env.GEMINI_MODEL || GEMINI_VISION_MODEL,
          fallbackVisionModel: env.GEMINI_FALLBACK_MODEL || GEMINI_FALLBACK_VISION_MODEL,
          imageModel: env.GEMINI_IMAGE_MODEL || GEMINI_IMAGE_MODEL,
        },
        200,
        requestId,
        corsHeaders,
      );
    }

    const isAnalysis = request.method === 'POST' && url.pathname === '/api/outfit-analysis';
    const isGeneration = request.method === 'POST' && url.pathname === '/api/outfit-generation';
    if (!isAnalysis && !isGeneration) {
      return jsonResponse(
        { ok: false, error: { code: 'not_found', message: '요청한 경로를 찾을 수 없습니다.' } },
        404,
        requestId,
        corsHeaders,
      );
    }

    if (!origin || !ALLOWED_ORIGINS.has(origin)) {
      return jsonResponse(
        { ok: false, error: { code: 'origin_not_allowed', message: '허용되지 않은 요청 출처입니다.' } },
        403,
        requestId,
        corsHeaders,
      );
    }

    if (!env.GEMINI_API_KEY) {
      console.error(JSON.stringify({ event: 'missing_secret', requestId }));
      return jsonResponse(
        { ok: false, error: { code: 'service_not_configured', message: 'AI 분석 서비스 설정이 필요합니다.' } },
        503,
        requestId,
        corsHeaders,
      );
    }

    try {
      const body = await readJsonWithLimit(request, MAX_REQUEST_BYTES);
      if (isGeneration) {
        const input = validateGenerationInput(body);
        const imageModel = env.GEMINI_IMAGE_MODEL || GEMINI_IMAGE_MODEL;
        const generatedImage = await requestGeminiProductImage(
          input,
          env.GEMINI_API_KEY,
          requestId,
          imageModel,
        );
        return jsonResponse(
          { ok: true, requestId, model: imageModel, generatedImage },
          200,
          requestId,
          corsHeaders,
        );
      }

      const input = validateAnalysisInput(body);
      const model = env.GEMINI_MODEL || GEMINI_VISION_MODEL;
      const fallbackModel = env.GEMINI_FALLBACK_MODEL || GEMINI_FALLBACK_VISION_MODEL;
      const imageModel = env.GEMINI_IMAGE_MODEL || GEMINI_IMAGE_MODEL;
      const analysisResult = await requestGeminiAnalysisWithFallback(
        input,
        env.GEMINI_API_KEY,
        requestId,
        model,
        fallbackModel,
      );
      const analysis = analysisResult.analysis;
      // 분석 요청에서는 Vision만 사용한다. 이미지 생성은 무료 할당량과
      // 응답 시간을 크게 소모하므로 사용자가 명시적으로 재생성을 요청하는
      // /api/outfit-generation 경로에서만 실행한다.
      const items = analysis.items.map((item) => ({
        ...item,
        generationPrompt: buildProductImagePrompt(item),
      }));
      const completedAnalysis = { ...analysis, items };

      console.log(JSON.stringify({
        event: 'outfit_analysis_succeeded',
        requestId,
        itemCount: completedAnalysis.items.length,
      }));

      return jsonResponse(
        {
          ok: true,
          requestId,
          model: analysisResult.model,
          imageModel,
          analysis: completedAnalysis,
        },
        200,
        requestId,
        corsHeaders,
      );
    } catch (error) {
      if (error instanceof HttpError) {
        console.warn(JSON.stringify({
          event: 'outfit_analysis_rejected',
          requestId,
          code: error.code,
          status: error.status,
        }));
        return jsonResponse(
          { ok: false, error: { code: error.code, message: error.message } },
          error.status,
          requestId,
          corsHeaders,
        );
      }

      console.error(JSON.stringify({
        event: 'outfit_analysis_failed',
        requestId,
        errorName: error instanceof Error ? error.name : 'UnknownError',
      }));
      return jsonResponse(
        { ok: false, error: { code: 'internal_error', message: '옷을 분석하는 중 문제가 생겼습니다. 잠시 후 다시 시도해주세요.' } },
        500,
        requestId,
        corsHeaders,
      );
    }
  },
};

function corsHeadersFor(origin) {
  const headers = new Headers({
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  });

  if (origin && ALLOWED_ORIGINS.has(origin)) {
    headers.set('Access-Control-Allow-Origin', origin);
  }
  return headers;
}

function jsonResponse(payload, status, requestId, extraHeaders = undefined) {
  const headers = new Headers(extraHeaders);
  headers.set('Content-Type', 'application/json; charset=utf-8');
  headers.set('Cache-Control', 'no-store');
  headers.set('X-Content-Type-Options', 'nosniff');
  headers.set('X-Request-Id', requestId);
  return new Response(JSON.stringify(payload), { status, headers });
}

async function readJsonWithLimit(request, maxBytes) {
  const contentType = request.headers.get('Content-Type') ?? '';
  if (!contentType.toLowerCase().startsWith('application/json')) {
    throw new HttpError(415, 'unsupported_content_type', 'application/json 형식만 지원합니다.');
  }

  const declaredLength = Number.parseInt(request.headers.get('Content-Length') ?? '', 10);
  if (Number.isFinite(declaredLength) && declaredLength > maxBytes) {
    throw new HttpError(413, 'request_too_large', '사진 데이터가 너무 큽니다. 더 작은 사진을 선택해주세요.');
  }

  if (!request.body) {
    throw new HttpError(400, 'empty_body', '분석할 사진 데이터가 없습니다.');
  }

  const text = await readStreamAsTextWithLimit(request.body, maxBytes, 'request_too_large');
  try {
    return JSON.parse(text);
  } catch {
    throw new HttpError(400, 'invalid_json', '요청 데이터 형식이 올바르지 않습니다.');
  }
}

async function readStreamAsTextWithLimit(
  stream,
  maxBytes,
  tooLargeCode,
  tooLargeStatus = 413,
  tooLargeMessage = '전송된 데이터가 허용 크기를 초과했습니다.',
) {
  const reader = stream.getReader();
  const chunks = [];
  let totalBytes = 0;

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      totalBytes += value.byteLength;
      if (totalBytes > maxBytes) {
        await reader.cancel('body_limit_exceeded');
        throw new HttpError(
          tooLargeStatus,
          tooLargeCode,
          tooLargeMessage,
        );
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }

  const merged = new Uint8Array(totalBytes);
  let offset = 0;
  for (const chunk of chunks) {
    merged.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return new TextDecoder().decode(merged);
}

export function validateAnalysisInput(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new HttpError(400, 'invalid_body', '요청 데이터 형식이 올바르지 않습니다.');
  }

  const imageBase64 = typeof body.imageBase64 === 'string'
    ? body.imageBase64.trim()
    : '';
  let mimeType = typeof body.mimeType === 'string'
    ? normalizeMimeType(body.mimeType)
    : '';
  let encodedImage = imageBase64;

  const dataUrlMatch = imageBase64.match(/^data:(image\/[a-z0-9.+-]+);base64,(.+)$/is);
  if (dataUrlMatch) {
    const dataUrlMimeType = normalizeMimeType(dataUrlMatch[1]);
    if (mimeType && dataUrlMimeType !== mimeType) {
      throw new HttpError(400, 'mime_type_mismatch', '사진 형식 정보가 일치하지 않습니다.');
    }
    mimeType = dataUrlMimeType;
    encodedImage = dataUrlMatch[2].replace(/\s+/g, '');
  }

  if (!ALLOWED_MIME_TYPES.has(mimeType)) {
    throw new HttpError(415, 'unsupported_image_type', 'JPG, PNG, WebP 사진만 지원합니다.');
  }
  if (!encodedImage) {
    throw new HttpError(400, 'missing_image', '분석할 사진을 선택해주세요.');
  }
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(encodedImage) || encodedImage.length % 4 !== 0) {
    throw new HttpError(400, 'invalid_image_data', '사진 데이터 형식이 올바르지 않습니다.');
  }

  const padding = encodedImage.endsWith('==') ? 2 : encodedImage.endsWith('=') ? 1 : 0;
  const decodedSize = (encodedImage.length * 3) / 4 - padding;
  if (decodedSize > MAX_IMAGE_BYTES) {
    throw new HttpError(413, 'image_too_large', '사진은 최대 8MB까지 분석할 수 있습니다.');
  }

  return { imageBase64: encodedImage, mimeType };
}

export function validateGenerationInput(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new HttpError(400, 'invalid_body', '상품컷 생성 정보가 올바르지 않습니다.');
  }
  const raw = body.item && typeof body.item === 'object' && !Array.isArray(body.item)
    ? body.item
    : body;
  const category = normalizeCategory(raw.category) || cleanText(raw.category, 24);
  const englishPrompt = cleanText(raw.englishPrompt ?? raw.english_prompt, 900);
  if (!category || !englishPrompt) {
    throw new HttpError(400, 'missing_generation_fields', '카테고리와 영문 상품컷 설명이 필요합니다.');
  }
  return {
    id: cleanText(raw.id, 80) || 'garment',
    name: cleanText(raw.name, 80) || '새 옷',
    category,
    detailCategory: cleanText(raw.detailCategory, 40),
    color: cleanText(raw.color, 100),
    colorHex: normalizeHexColor(raw.colorHex ?? raw.color_hex),
    materialTexture: cleanText(raw.materialTexture ?? raw.material_texture, 160),
    fitDescription: cleanText(raw.fitDescription ?? raw.fit_description ?? raw.fit, 160),
    necklineOrWaist: cleanText(raw.necklineOrWaist ?? raw.neckline_or_waist, 180),
    englishPrompt,
  };
}

async function requestGeminiAnalysis(input, apiKey, requestId, model) {
  const prompt = buildAnalysisPrompt();
  const upstreamResponse = await fetch(
    `${GEMINI_API_BASE}/${encodeURIComponent(model)}:generateContent`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: JSON.stringify({
        contents: [{
          role: 'user',
          parts: [
            { text: prompt },
            {
              inlineData: {
                mimeType: input.mimeType,
                data: input.imageBase64,
              },
            },
          ],
        }],
        generationConfig: {
          maxOutputTokens: 2600,
          responseMimeType: 'application/json',
          responseJsonSchema: geminiAnalysisSchema(),
        },
      }),
      signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
    },
  );

  const contentLength = Number.parseInt(upstreamResponse.headers.get('Content-Length') ?? '', 10);
  if (Number.isFinite(contentLength) && contentLength > MAX_UPSTREAM_RESPONSE_BYTES) {
    throw new HttpError(502, 'ai_response_too_large', 'AI 분석 결과가 너무 큽니다. 다시 시도해주세요.');
  }

  if (!upstreamResponse.body) {
    throw new HttpError(502, 'empty_ai_response', 'AI 분석 결과를 받지 못했습니다.');
  }
  const responseText = await readStreamAsTextWithLimit(
    upstreamResponse.body,
    MAX_UPSTREAM_RESPONSE_BYTES,
    'ai_response_too_large',
    502,
    'AI 분석 결과가 너무 큽니다. 다시 시도해주세요.',
  );

  let responsePayload;
  try {
    responsePayload = JSON.parse(responseText);
  } catch {
    throw new HttpError(502, 'invalid_ai_response', 'AI 분석 결과 형식이 올바르지 않습니다.');
  }

  if (!upstreamResponse.ok) {
    console.warn(JSON.stringify({
      event: 'gemini_request_failed',
      requestId,
      upstreamStatus: upstreamResponse.status,
      upstreamCode: cleanText(responsePayload?.error?.code, 80) || null,
      upstreamMessage: cleanText(responsePayload?.error?.message, 220) || null,
    }));
    if (upstreamResponse.status === 429) {
      throw new HttpError(429, 'ai_rate_limited', 'AI 요청 한도를 잠시 넘었어요. 1분 후 다시 시도해주세요.');
    }
    if (upstreamResponse.status === 401 || upstreamResponse.status === 403) {
      throw new HttpError(503, 'ai_auth_failed', 'AI 서비스 키를 다시 설정해주세요.');
    }
    if ([500, 502, 503, 504].includes(upstreamResponse.status)) {
      throw new HttpError(503, 'ai_capacity_busy', 'AI가 잠시 혼잡해요. 자동으로 다른 분석 모델을 시도할게요.');
    }
    throw new HttpError(502, 'ai_service_error', 'AI 분석 서비스가 응답하지 않습니다. 잠시 후 다시 시도해주세요.');
  }

  const rawContent = extractGeminiOutputText(responsePayload);
  if (typeof rawContent !== 'string' || !rawContent.trim()) {
    throw new HttpError(502, 'empty_ai_result', '사진에서 옷 분석 결과를 찾지 못했습니다.');
  }

  let rawAnalysis;
  try {
    rawAnalysis = JSON.parse(stripMarkdownFence(rawContent));
  } catch {
    throw new HttpError(502, 'invalid_ai_result', 'AI 분석 결과를 정리하지 못했습니다. 다시 시도해주세요.');
  }
  return normalizeAnalysisPayload(rawAnalysis);
}

async function requestGeminiAnalysisWithFallback(
  input,
  apiKey,
  requestId,
  primaryModel,
  fallbackModel,
) {
  const models = [...new Set([primaryModel, fallbackModel].filter(Boolean))];
  let lastCapacityError;

  for (const [modelIndex, model] of models.entries()) {
    const maxAttempts = modelIndex === 0 ? 2 : 1;
    for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
      try {
        const analysis = await requestGeminiAnalysis(input, apiKey, requestId, model);
        if (modelIndex > 0) {
          console.info(JSON.stringify({
            event: 'gemini_fallback_succeeded',
            requestId,
            model,
          }));
        }
        return { analysis, model };
      } catch (error) {
        if (!(error instanceof HttpError) || error.code !== 'ai_capacity_busy') {
          throw error;
        }
        lastCapacityError = error;
        console.warn(JSON.stringify({
          event: 'gemini_capacity_retry',
          requestId,
          model,
          attempt,
          willFallback: attempt === maxAttempts && modelIndex < models.length - 1,
        }));
        if (attempt < maxAttempts) {
          await wait(300);
        }
      }
    }
  }

  throw lastCapacityError
    ?? new HttpError(503, 'ai_capacity_busy', 'AI가 잠시 혼잡해요. 잠시 후 다시 시도해주세요.');
}

function wait(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function geminiAnalysisSchema() {
  return {
    type: 'object',
    properties: {
      summary: { type: 'string' },
      items: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            name: { type: 'string' },
            category: { type: 'string' },
            detailCategory: { type: 'string' },
            precise_color: { type: 'string' },
            color_hex: { type: 'string' },
            paletteColor: { type: 'string' },
            material_texture: { type: 'string' },
            fit_description: { type: 'string' },
            appFit: { type: 'string' },
            neckline_or_waist: { type: 'string' },
            english_prompt: { type: 'string' },
            confidence: { type: 'number' },
            box_2d: { type: 'array', items: { type: 'number' } },
          },
          required: [
            'name',
            'category',
            'detailCategory',
            'precise_color',
            'color_hex',
            'paletteColor',
            'material_texture',
            'fit_description',
            'appFit',
            'neckline_or_waist',
            'english_prompt',
            'confidence',
            'box_2d',
          ],
        },
      },
    },
    required: ['summary', 'items'],
  };
}

function extractGeminiOutputText(payload) {
  if (typeof payload?.output_text === 'string') return payload.output_text;
  const outputs = Array.isArray(payload?.outputs) ? payload.outputs : [];
  for (const output of outputs) {
    if (typeof output?.text === 'string') return output.text;
    const content = Array.isArray(output?.content) ? output.content : [];
    for (const part of content) {
      if (typeof part?.text === 'string') return part.text;
    }
  }
  const legacyText = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
  return typeof legacyText === 'string' ? legacyText : null;
}

export function buildAnalysisPrompt() {
  const allowedDetails = Object.entries(CATEGORY_DETAILS)
    .map(([category, details]) => `${category}: ${details.join(', ')}`)
    .join('\n');
  return `제공된 사용자 사진 하나만을 근거로, 주요 인물이 실제로 착용한 의류를 각각 식별하세요.
기존 옷장, 샘플 이미지, 일반적인 추측은 절대 참조하지 마세요.
거울의 반사상, 휴대폰, 배경 속 사람, 프린트에 그려진 옷은 제외하세요.
상의·하의·아우터·원피스·신발·가방·액세서리를 개별 아이템으로 분리하세요.

결과를 쓰기 전에 다음을 내부적으로 순서대로 확인하세요.
1. 인체와 배경을 분리하고 상의·하의·아우터·원피스·신발·가방·액세서리의 실제 경계를 찾습니다.
2. 각 옷의 실루엣, 길이, 품, 소매, 소재 단서를 함께 보고 세부 카테고리와 핏을 결정합니다.
3. 조명, 강한 하이라이트, 그림자, 거울 색편향, 얼룩, 지문, 왜곡을 제거하고 옷 자체의 중간톤을 비교합니다.
4. 원본 옷의 색, 소재, 질감, 핏, 넥라인/허리 디테일만 문자로 정밀하게 전환합니다.

색상 판단 규칙:
- 주름 안쪽의 가장 어두운 그림자, 강한 하이라이트, 거울의 색 편향, 피부와 배경색은 기준에서 제외합니다.
- 빛을 받은 부분과 중간톤에 따뜻한 빨강·노랑 기운이 지속되면 블랙이 아니라 브라운으로 판단합니다.
- 블랙은 빛을 받은 부분에서도 채도가 낮은 중성 검정으로 보일 때만 선택합니다.
- 어두운 색에 파란 기운이 지속되면 블랙이 아니라 네이비입니다.
- 노란빛이 도는 밝은 색은 화이트보다 아이보리나 베이지를 우선 검토합니다.
- 패턴 의류는 가장 넓은 면적의 바탕색 하나를 선택합니다.

허용 카테고리와 세부 카테고리:
${allowedDetails}

precise_color은 영문 구체적 색상명(예: Dark Chocolate Brown), color_hex는 #RRGGBB 형식의 추정 원본색입니다.
paletteColor는 화이트, 아이보리, 베이지, 브라운, 그레이, 블랙, 레드, 핑크, 그린, 블루, 네이비, 기타 중 하나입니다.
material_texture는 소재와 표면 질감, fit_description은 실루엣과 길이까지 포함한 구체적 영문 표현입니다.
appFit은 슬림, 기본, 루즈 중 하나입니다.
neckline_or_waist는 상의는 넥라인/소매/여밈, 하의는 허리/플리츠/통 디테일을 영문으로 적으세요.
english_prompt는 해당 옷 하나만의 상품컷 생성에 필요한 순수 옷 특징을 영문으로 작성하세요. 사람, 배경, 조명, 브랜드는 포함하지 마세요.
box_2d는 원본 사진 전체 기준 [ymin, xmin, ymax, xmax] 순서이며 모든 값은 0~1000 정규화 좌표입니다.
박스는 옷 전체가 잘리지 않도록 약간의 여유를 두되, 다른 옷은 가능한 한 포함하지 마세요.

다음 JSON 스키마만 반환하세요:
{
  "summary": "사진 분석 한 줄 요약",
  "items": [
    {
      "name": "사용자가 알아보기 쉬운 옷 이름",
      "category": "허용 카테고리",
      "detailCategory": "해당 카테고리의 허용 세부 카테고리",
      "precise_color": "Dark Chocolate Brown",
      "color_hex": "#3A241B",
      "paletteColor": "브라운",
      "material_texture": "Smooth cotton jersey",
      "fit_description": "Slim fit, hip length, short sleeves",
      "appFit": "슬림|기본|루즈",
      "neckline_or_waist": "Crew neck with clean rib binding",
      "english_prompt": "A dark chocolate brown slim-fit short-sleeve t-shirt, crew neck, smooth cotton fabric",
      "confidence": 0.0,
      "box_2d": [0, 0, 1000, 1000]
    }
  ]
}`;
}

export function normalizeAnalysisPayload(value) {
  const root = value && typeof value === 'object' && !Array.isArray(value) ? value : {};
  const rawItems = Array.isArray(root.items)
    ? root.items
    : Array.isArray(root.garments)
      ? root.garments
      : [];

  const items = rawItems.slice(0, 12).flatMap((item, index) => {
    const normalized = normalizeGarment(item, index);
    return normalized ? [normalized] : [];
  });

  return {
    summary: cleanText(root.summary, 160)
      || (items.length > 0 ? `사진에서 옷 ${items.length}건을 찾았어요.` : '사진에서 등록할 옷을 찾지 못했어요.'),
    items,
  };
}

function normalizeGarment(item, index) {
  if (!item || typeof item !== 'object' || Array.isArray(item)) return null;
  const category = normalizeCategory(item.category ?? item.type);
  if (!category) return null;
  const detailCategory = normalizeDetailCategory(category, item.detailCategory ?? item.detail ?? item.subcategory);
  const box = normalizeBox(item.box ?? item.boundingBox ?? item.bbox ?? item.box_2d);
  if (!box) return null;

  const confidence = clampNumber(item.confidence ?? item.score, 0, 1, 0.5);
  if (confidence < 0.35) return null;

  const appFitCandidate = cleanText(item.appFit ?? item.app_fit ?? item.fit, 12);
  const appFit = ALLOWED_FITS.has(appFitCandidate) ? appFitCandidate : '기본';
  const preciseColor = cleanText(item.precise_color ?? item.preciseColor ?? item.color, 100)
    || 'Unknown';
  const colorHex = normalizeHexColor(item.color_hex ?? item.colorHex);
  const paletteColor = normalizeColor(item.paletteColor ?? item.palette_color ?? preciseColor);
  const materialTexture = cleanText(item.material_texture ?? item.materialTexture, 160)
    || 'Material not clearly visible';
  const fitDescription = cleanText(item.fit_description ?? item.fitDescription, 160)
    || appFit;
  const necklineOrWaist = cleanText(item.neckline_or_waist ?? item.necklineOrWaist, 180)
    || 'Detail not clearly visible';
  const englishPrompt = cleanText(item.english_prompt ?? item.englishPrompt, 900)
    || `A ${preciseColor} ${fitDescription} ${detailCategory}, ${materialTexture}`;
  const name = cleanText(item.name, 80) || `${paletteColor} ${detailCategory}`;

  const mask = normalizeMask(item.mask ?? item.polygon ?? item.segmentation);
  return {
    id: `detected-${index + 1}`,
    name,
    category,
    detailCategory,
    color: paletteColor,
    fit: appFit,
    preciseColor,
    colorHex,
    materialTexture,
    fitDescription,
    necklineOrWaist,
    englishPrompt,
    confidence: roundNumber(confidence, 3),
    box,
    ...(mask.length >= 3 ? { mask } : {}),
  };
}

function normalizeCategory(value) {
  const raw = cleanText(value, 24);
  if (!raw) return null;
  if (Object.hasOwn(CATEGORY_DETAILS, raw)) return raw;
  return CATEGORY_ALIASES[raw.toLowerCase()] ?? null;
}

function normalizeDetailCategory(category, value) {
  const details = CATEGORY_DETAILS[category];
  const raw = cleanText(value, 40);
  if (details.includes(raw)) return raw;
  const aliased = DETAIL_ALIASES[raw];
  if (aliased && details.includes(aliased)) return aliased;
  return details[0];
}

function normalizeColor(value) {
  const raw = cleanText(value, 100);
  if (!raw) return '기타';
  if (ALLOWED_COLORS.has(raw)) return raw;
  const compact = raw.replace(/\s+/g, '').toLowerCase();
  if (/(navy|네이비)/.test(compact)) return '네이비';
  if (/(brown|브라운|갈색)/.test(compact)) return '브라운';
  if (/(ivory|cream|아이보리|크림)/.test(compact)) return '아이보리';
  if (/(beige|베이지)/.test(compact)) return '베이지';
  if (/(black|블랙|검정|검은)/.test(compact)) return '블랙';
  if (/(white|화이트|흰색)/.test(compact)) return '화이트';
  if (/(gray|grey|그레이|회색)/.test(compact)) return '그레이';
  if (/(blue|블루|청색|파랑|데님)/.test(compact)) return '블루';
  if (/(pink|핑크)/.test(compact)) return '핑크';
  if (/(red|레드|빨간)/.test(compact)) return '레드';
  if (/(green|khaki|그린|초록|카키)/.test(compact)) return '그린';
  return '기타';
}

function normalizeHexColor(value) {
  const raw = cleanText(value, 16).toUpperCase();
  const match = raw.match(/^#?([0-9A-F]{6})$/);
  return match ? `#${match[1]}` : '';
}

export function buildProductImagePrompt(item) {
  const sourcePrompt = cleanText(item.englishPrompt ?? item.english_prompt, 900);
  const details = [
    sourcePrompt,
    cleanText(item.preciseColor ?? item.precise_color ?? item.color, 100),
    normalizeHexColor(item.colorHex ?? item.color_hex),
    cleanText(item.materialTexture ?? item.material_texture, 160),
    cleanText(item.fitDescription ?? item.fit_description ?? item.fit, 160),
    cleanText(item.necklineOrWaist ?? item.neckline_or_waist, 180),
  ].filter(Boolean).join(', ');
  return `${details}, studio product shot, clean off-white background, front view, flat lay style, professional lighting, high-end e-commerce product catalog, 8k resolution, no human model. Show exactly one garment only. Preserve the exact color, silhouette, material texture, sleeve and neckline or waistband details described above. No person, mannequin, body parts, hanger, text, logo, watermark, extra garment, accessory or collage.`;
}

async function requestGeminiProductImage(item, apiKey, requestId, model) {
  const prompt = buildProductImagePrompt(item);
  const upstreamResponse = await fetch(
    `${GEMINI_API_BASE}/${encodeURIComponent(model)}:generateContent`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: { responseModalities: ['IMAGE'] },
      }),
      signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
    },
  );

  if (!upstreamResponse.body) {
    throw new HttpError(502, 'empty_image_response', '상품컷 이미지를 받지 못했습니다.');
  }
  const responseText = await readStreamAsTextWithLimit(
    upstreamResponse.body,
    MAX_UPSTREAM_RESPONSE_BYTES,
    'image_response_too_large',
    502,
    '상품컷 이미지가 너무 큽니다.',
  );
  let payload;
  try {
    payload = JSON.parse(responseText);
  } catch {
    throw new HttpError(502, 'invalid_image_response', '상품컷 응답 형식이 올바르지 않습니다.');
  }
  if (!upstreamResponse.ok) {
    console.warn(JSON.stringify({
      event: 'gemini_image_request_failed',
      requestId,
      upstreamStatus: upstreamResponse.status,
      upstreamMessage: cleanText(payload?.error?.message, 220) || null,
    }));
    if (upstreamResponse.status === 429) {
      throw new HttpError(429, 'image_rate_limited', '상품컷 생성 한도를 잠시 넘었어요. 1분 후 다시 시도해주세요.');
    }
    if (upstreamResponse.status === 401 || upstreamResponse.status === 403) {
      throw new HttpError(503, 'image_auth_failed', '이미지 생성 서비스 키를 다시 설정해주세요.');
    }
    throw new HttpError(502, 'image_service_error', '상품컷 생성 서비스가 응답하지 않습니다.');
  }

  const parts = payload?.candidates?.[0]?.content?.parts;
  const imagePart = Array.isArray(parts)
    ? parts.find((part) => part?.inlineData?.data || part?.inline_data?.data)
    : null;
  const inlineData = imagePart?.inlineData ?? imagePart?.inline_data;
  const imageBase64 = typeof inlineData?.data === 'string' ? inlineData.data.trim() : '';
  const mimeType = normalizeMimeType(inlineData?.mimeType ?? inlineData?.mime_type ?? '');
  if (!imageBase64 || !ALLOWED_MIME_TYPES.has(mimeType)) {
    throw new HttpError(502, 'missing_generated_image', '생성된 상품컷을 찾지 못했습니다.');
  }
  return { imageBase64, mimeType, prompt };
}

function normalizeBox(value) {
  if (Array.isArray(value) && value.length >= 4) {
    const [ymin, xmin, ymax, xmax] = value.map(finiteNumber);
    if ([ymin, xmin, ymax, xmax].some((number) => number === null)) return null;
    const scale = Math.max(ymin, xmin, ymax, xmax) > 1 ? 1000 : 1;
    return normalizeBox({
      x: xmin / scale,
      y: ymin / scale,
      width: (xmax - xmin) / scale,
      height: (ymax - ymin) / scale,
    });
  }
  if (!value || typeof value !== 'object') return null;
  let x = finiteNumber(value.x ?? value.left ?? value.xmin ?? value.x1);
  let y = finiteNumber(value.y ?? value.top ?? value.ymin ?? value.y1);
  let width = finiteNumber(value.width ?? value.w);
  let height = finiteNumber(value.height ?? value.h);

  if (width === null) {
    const right = finiteNumber(value.right ?? value.xmax ?? value.x2);
    if (x !== null && right !== null) width = right - x;
  }
  if (height === null) {
    const bottom = finiteNumber(value.bottom ?? value.ymax ?? value.y2);
    if (y !== null && bottom !== null) height = bottom - y;
  }
  if ([x, y, width, height].some((number) => number === null)) return null;

  const largest = Math.max(x, y, width, height);
  if (largest > 1 && largest <= 100) {
    x /= 100;
    y /= 100;
    width /= 100;
    height /= 100;
  }
  if (Math.max(x, y, width, height) > 1.25) return null;

  x = clampNumber(x, 0, 1, 0);
  y = clampNumber(y, 0, 1, 0);
  width = clampNumber(width, 0, 1 - x, 0);
  height = clampNumber(height, 0, 1 - y, 0);
  if (width < 0.025 || height < 0.025) return null;

  return {
    x: roundNumber(x, 4),
    y: roundNumber(y, 4),
    width: roundNumber(width, 4),
    height: roundNumber(height, 4),
  };
}

function normalizeMask(value) {
  if (!Array.isArray(value)) return [];
  const rawPoints = value.slice(0, 96).flatMap((point) => {
    if (Array.isArray(point) && point.length >= 2) {
      const x = finiteNumber(point[0]);
      const y = finiteNumber(point[1]);
      return x === null || y === null ? [] : [[x, y]];
    }
    if (point && typeof point === 'object') {
      const x = finiteNumber(point.x);
      const y = finiteNumber(point.y);
      return x === null || y === null ? [] : [[x, y]];
    }
    return [];
  });
  if (rawPoints.length < 3) return [];
  const scale = rawPoints.some(([x, y]) => x > 1 || y > 1) ? 1000 : 1;
  return rawPoints.map(([x, y]) => [
    roundNumber(clampNumber(x / scale, 0, 1, 0), 4),
    roundNumber(clampNumber(y / scale, 0, 1, 0), 4),
  ]);
}

function cleanText(value, maxLength) {
  if (typeof value !== 'string') return '';
  return value.replace(/[\u0000-\u001F\u007F]/g, '').trim().slice(0, maxLength);
}

function normalizeMimeType(value) {
  const mimeType = typeof value === 'string' ? value.trim().toLowerCase() : '';
  return mimeType === 'image/jpg' ? 'image/jpeg' : mimeType;
}

function finiteNumber(value) {
  const number = typeof value === 'number' ? value : Number.parseFloat(value);
  return Number.isFinite(number) ? number : null;
}

function clampNumber(value, min, max, fallback) {
  const number = finiteNumber(value);
  if (number === null) return fallback;
  return Math.min(max, Math.max(min, number));
}

function roundNumber(value, precision) {
  const factor = 10 ** precision;
  return Math.round(value * factor) / factor;
}

function stripMarkdownFence(value) {
  return value
    .trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/, '')
    .trim();
}
