import {initializeApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {getStorage} from 'firebase-admin/storage';
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {defineSecret} from 'firebase-functions/params';

initializeApp();

const GROQ_API_KEY = defineSecret('GROQ_API_KEY');
const KMA_API_KEY = defineSecret('KMA_API_KEY');
const region = 'asia-northeast3';
const groqModel = 'llama-3.1-8b-instant';

const systemPrompt = `너는 한국어로 대화하는 착착(CHAKCHAK)의 코디 메이트야.
사용자가 가진 옷, 오늘 날씨, 일정만으로 현실적인 코디를 추천해.
답변은 최대 2개의 짧은 문장, 70자 이내로 말해.
옷은 wardrobe에 있는 정확한 이름만 2~3개 골라.
- 원피스·드레스에는 하의를 함께 추천하지 마.
- 기본 조합은 상의 1 + 하의 1 + 신발 1이야.
- 원피스 조합은 원피스 1 + 신발 1 + 가방·액세서리·아우터 중 1개야.
- 27도 이상에는 니트·울·기모·패딩을 피하고, 10도 이하에는 린넨·민소매·샌들을 피해야 해.
- 출근·미팅은 단정하게, 데이트는 실루엣을 정돈하고 색상 포인트를 하나만 사용해.
반드시 {"answer":"짧은 대사","selected_items":["옷 이름"]} JSON 객체만 출력해.`;

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', '로그인 후 이용해주세요.');
  }
}

function safeText(value, maxLength = 500) {
  return String(value ?? '')
      .replace(/[\u0000-\u001f]/g, ' ')
      .trim()
      .slice(0, maxLength);
}

function normalizeContext(raw) {
  const wardrobe = Array.isArray(raw?.wardrobe) ? raw.wardrobe : [];
  const schedules = Array.isArray(raw?.schedules) ? raw.schedules : [];
  return {
    wardrobe: wardrobe.slice(0, 120).map((item) => ({
      name: safeText(item?.name, 60),
      category: safeText(item?.category, 30),
      color: safeText(item?.color, 30),
    })).filter((item) => item.name),
    schedules: schedules.slice(0, 20).map((item) => ({
      title: safeText(item?.title, 80),
      time: safeText(item?.time, 20),
    })),
    weather: {
      temperature: Number(raw?.weather?.temperature ?? 20),
      condition: safeText(raw?.weather?.condition, 30),
      precipitationProbability:
        Number(raw?.weather?.precipitationProbability ?? 0),
    },
  };
}

function normalizeHistory(raw) {
  if (!Array.isArray(raw)) return [];
  return raw.slice(-8).map((item) => ({
    role: item?.role === 'assistant' ? 'assistant' : 'user',
    content: safeText(item?.content, 500),
  })).filter((item) => item.content);
}

function roleOf(item) {
  const value = `${item.category} ${item.name}`;
  if (/원피스|드레스/.test(value)) return 'dress';
  if (/신발|로퍼|스니커즈|구두|샌들|부츠/.test(value)) return 'shoes';
  if (/하의|팬츠|슬랙스|데님|스커트|바지/.test(value)) return 'bottom';
  if (/아우터|재킷|자켓|코트|가디건|점퍼/.test(value)) return 'outer';
  if (/가방|백|액세서리/.test(value)) return 'accessory';
  return 'top';
}

function fallbackItems(context) {
  const first = (role) => context.wardrobe.find((item) => roleOf(item) === role);
  const dress = first('dress');
  if (dress) return [dress, first('shoes'), first('accessory') || first('outer')]
      .filter(Boolean).map((item) => item.name).slice(0, 3);
  return [first('top'), first('bottom'), first('shoes')]
      .filter(Boolean).map((item) => item.name).slice(0, 3);
}

function validateSelectedItems(names, context) {
  const byName = new Map(context.wardrobe.map((item) => [item.name, item]));
  let items = [...new Set(names)].map((name) => byName.get(name)).filter(Boolean);
  if (items.some((item) => roleOf(item) === 'dress')) {
    items = items.filter((item) => roleOf(item) !== 'bottom');
  }
  let hasShoes = false;
  items = items.filter((item) => {
    if (roleOf(item) !== 'shoes') return true;
    if (hasShoes) return false;
    hasShoes = true;
    return true;
  });
  const roles = new Set(items.map(roleOf));
  const complete = roles.has('dress')
    ? roles.has('shoes')
    : roles.has('top') && roles.has('bottom') && roles.has('shoes');
  return complete ? items.slice(0, 3).map((item) => item.name) : fallbackItems(context);
}

export const recommendOutfit = onCall({
  region,
  secrets: [GROQ_API_KEY],
  timeoutSeconds: 30,
  memory: '256MiB',
}, async (request) => {
  requireAuth(request);
  const message = safeText(request.data?.message, 500);
  if (!message) throw new HttpsError('invalid-argument', '질문을 입력해주세요.');
  const context = normalizeContext(request.data?.context);
  if (!context.wardrobe.length) {
    throw new HttpsError('failed-precondition', '옷장에 옷을 먼저 등록해주세요.');
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${GROQ_API_KEY.value()}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: groqModel,
        messages: [
          {role: 'system', content: systemPrompt},
          ...normalizeHistory(request.data?.history),
          {role: 'user', content: `현재 앱 정보: ${JSON.stringify(context)}\n질문: ${message}`},
        ],
        temperature: 0.65,
        max_completion_tokens: 180,
        response_format: {type: 'json_object'},
        stream: false,
      }),
      signal: controller.signal,
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      const code = response.status === 429 ? 'resource-exhausted' : 'unavailable';
      throw new HttpsError(code, response.status === 429
        ? '무료 AI 사용량이 잠시 제한됐어요.'
        : 'AI 메이트 연결을 확인해주세요.');
    }
    const raw = payload?.choices?.[0]?.message?.content ?? '';
    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch {
      parsed = {answer: raw, selected_items: []};
    }
    const selectedItems = validateSelectedItems(
        Array.isArray(parsed.selected_items) ? parsed.selected_items : [], context);
    return {
      answer: safeText(parsed.answer, 180) || '오늘 조건에 맞는 조합으로 골랐어요.',
      selectedItems,
      model: groqModel,
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('unavailable', error?.name === 'AbortError'
      ? '메이트 응답이 늦어지고 있어요. 다시 시도해주세요.'
      : 'AI 연결이 잠시 불안정해요.');
  } finally {
    clearTimeout(timeout);
  }
});

function kstParts(date = new Date()) {
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  return {
    year: kst.getUTCFullYear(), month: kst.getUTCMonth() + 1,
    day: kst.getUTCDate(), hour: kst.getUTCHours(), minute: kst.getUTCMinutes(),
  };
}

function compactDate(parts) {
  return `${parts.year}${String(parts.month).padStart(2, '0')}${String(parts.day).padStart(2, '0')}`;
}

function latestBase(now = new Date()) {
  const parts = kstParts(now);
  let base = new Date(Date.UTC(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute));
  if (parts.minute < 45) base = new Date(base.getTime() - 3600000);
  base.setUTCMinutes(30, 0, 0);
  const result = kstParts(new Date(base.getTime() - 9 * 3600000));
  return {date: compactDate(result), time: `${String(result.hour).padStart(2, '0')}30`};
}

function kmaGrid(latitude, longitude) {
  const degrad = Math.PI / 180;
  const re = 6371.00877 / 5;
  const slat1 = 30 * degrad;
  const slat2 = 60 * degrad;
  const olon = 126 * degrad;
  const olat = 38 * degrad;
  let sn = Math.log(Math.cos(slat1) / Math.cos(slat2)) /
      Math.log(Math.tan(Math.PI / 4 + slat2 / 2) / Math.tan(Math.PI / 4 + slat1 / 2));
  let sf = Math.tan(Math.PI / 4 + slat1 / 2);
  sf = (Math.pow(sf, sn) * Math.cos(slat1)) / sn;
  let ro = Math.tan(Math.PI / 4 + olat / 2);
  ro = (re * sf) / Math.pow(ro, sn);
  let ra = Math.tan(Math.PI / 4 + latitude * degrad / 2);
  ra = (re * sf) / Math.pow(ra, sn);
  let theta = longitude * degrad - olon;
  if (theta > Math.PI) theta -= 2 * Math.PI;
  if (theta < -Math.PI) theta += 2 * Math.PI;
  theta *= sn;
  return {nx: Math.floor(ra * Math.sin(theta) + 43.5), ny: Math.floor(ro - ra * Math.cos(theta) + 136.5)};
}

function numeric(value, fallback = 0) {
  const match = String(value ?? '').replace(',', '.').match(/-?\d+(?:\.\d+)?/);
  return match ? Number(match[0]) : fallback;
}

export const getKmaWeather = onCall({
  region,
  secrets: [KMA_API_KEY],
  timeoutSeconds: 20,
  memory: '256MiB',
}, async (request) => {
  requireAuth(request);
  const latitude = Number(request.data?.latitude);
  const longitude = Number(request.data?.longitude);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude) ||
      latitude < 32 || latitude > 39.5 || longitude < 124 || longitude > 132) {
    throw new HttpsError('invalid-argument', '대한민국 내 위치 좌표를 확인해주세요.');
  }
  const grid = kmaGrid(latitude, longitude);
  const base = latestBase();
  const query = new URLSearchParams({
    pageNo: '1', numOfRows: '1000', dataType: 'JSON',
    base_date: base.date, base_time: base.time,
    nx: String(grid.nx), ny: String(grid.ny), authKey: KMA_API_KEY.value(),
  });
  const response = await fetch(
      `https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getUltraSrtFcst?${query}`,
      {headers: {Accept: 'application/json'}});
  const payload = await response.json().catch(() => ({}));
  const root = payload?.response;
  if (!response.ok || String(root?.header?.resultCode) !== '00') {
    throw new HttpsError('unavailable', root?.header?.resultMsg ?? '기상청 예보를 불러오지 못했어요.');
  }
  const rows = Array.isArray(root?.body?.items?.item) ? root.body.items.item : [];
  const moments = [...new Set(rows.map((row) => `${row.fcstDate}${row.fcstTime}`))].sort();
  const moment = moments[0];
  const values = Object.fromEntries(rows.filter((row) =>
    `${row.fcstDate}${row.fcstTime}` === moment).map((row) => [row.category, row.fcstValue]));
  const temperature = numeric(values.T1H);
  const humidity = numeric(values.REH);
  const windSpeed = numeric(values.WSD);
  const rain = numeric(values.RN1);
  const precipitationType = Number(values.PTY ?? 0);
  const code = [3, 7].includes(precipitationType) ? 71
    : [2, 6].includes(precipitationType) ? 67
    : [1, 4].includes(precipitationType) ? 61 : Number(values.SKY) === 4 ? 3 : 0;
  return {
    temperature,
    apparentTemperature: temperature + 0.33 * ((humidity / 100) * 6.105 *
      Math.exp((17.27 * temperature) / (237.7 + temperature))) - 0.7 * windSpeed - 4,
    humidity,
    windSpeed,
    precipitation: rain,
    precipitationProbability: rain > 0 ? 100 : 0,
    code,
    observedAt: moment,
    source: 'kma',
    sourceLabel: '기상청 초단기예보',
  };
});

export const deleteMyData = onCall({region, timeoutSeconds: 60}, async (request) => {
  requireAuth(request);
  const userId = request.auth.uid;
  await Promise.all([
    getFirestore().recursiveDelete(getFirestore().collection('users').doc(userId)),
    getStorage().bucket().deleteFiles({prefix: `users/${userId}/`, force: true}),
  ]);
  return {deleted: true};
});
