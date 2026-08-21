import assert from 'node:assert/strict';
import test from 'node:test';

import {
  buildAnalysisPrompt,
  buildProductImagePrompt,
  normalizeAnalysisPayload,
  validateAnalysisInput,
  validateGenerationInput,
} from '../src/index.js';

const ONE_PIXEL_PNG_BASE64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6nS8AAAAASUVORK5CYII=';

test('validates a supported base64 image without accepting wardrobe context', () => {
  const result = validateAnalysisInput({
    imageBase64: ONE_PIXEL_PNG_BASE64,
    mimeType: 'image/png',
    wardrobe: [
      { id: 'garment-1', name: '화이트 반팔티', category: '상의', detailCategory: '반팔티', color: '화이트' },
      null,
    ],
  });

  assert.equal(result.mimeType, 'image/png');
  assert.equal('wardrobe' in result, false);
});

test('normalizes the common image/jpg MIME alias', () => {
  const result = validateAnalysisInput({
    imageBase64: ONE_PIXEL_PNG_BASE64,
    mimeType: 'image/jpg',
  });

  assert.equal(result.mimeType, 'image/jpeg');
});

test('normalizes aliases, percentage boxes, and filters low-confidence items', () => {
  const result = normalizeAnalysisPayload({
    summary: '상의와 신발을 찾음',
    items: [
      {
        name: '블랙 티셔츠',
        category: 'top',
        detailCategory: '반팔 티셔츠',
        precise_color: 'Dark Chocolate Brown',
        color_hex: '#3A241B',
        paletteColor: '브라운',
        material_texture: 'Smooth cotton jersey',
        fit_description: 'Slim fit, hip length, short sleeves',
        appFit: '슬림',
        neckline_or_waist: 'Crew neck with clean rib binding',
        english_prompt: 'A dark chocolate brown slim-fit short-sleeve t-shirt',
        confidence: 0.93,
        box: { x: 10, y: 8, width: 55, height: 32 },
      },
      {
        name: '불확실한 액세서리',
        category: 'accessory',
        confidence: 0.1,
        box: { x: 0.1, y: 0.1, width: 0.2, height: 0.2 },
      },
    ],
  });

  assert.equal(result.items.length, 1);
  assert.equal(result.items[0].category, '상의');
  assert.equal(result.items[0].detailCategory, '반팔티');
  assert.equal(result.items[0].preciseColor, 'Dark Chocolate Brown');
  assert.equal(result.items[0].colorHex, '#3A241B');
  assert.equal(result.items[0].color, '브라운');
  assert.equal(result.items[0].materialTexture, 'Smooth cotton jersey');
  assert.equal(result.items[0].fitDescription, 'Slim fit, hip length, short sleeves');
  assert.equal(result.items[0].necklineOrWaist, 'Crew neck with clean rib binding');
  assert.equal(result.items[0].englishPrompt, 'A dark chocolate brown slim-fit short-sleeve t-shirt');
  assert.deepEqual(result.items[0].box, {
    x: 0.1,
    y: 0.08,
    width: 0.55,
    height: 0.32,
  });
});

test('rejects an unsupported image MIME type', () => {
  assert.throws(
    () => validateAnalysisInput({
      imageBase64: ONE_PIXEL_PNG_BASE64,
      mimeType: 'image/gif',
    }),
    (error) => error.code === 'unsupported_image_type' && error.status === 415,
  );
});

test('normalizes Gemini 0-1000 boxes and segmentation polygons', () => {
  const result = normalizeAnalysisPayload({
    summary: '상의 한 건',
    items: [
      {
        name: '블랙 반팔티',
        category: '상의',
        detailCategory: '반팔티',
        color: '블랙',
        fit: '기본',
        confidence: 0.97,
        box_2d: [120, 210, 610, 790],
        mask: [[210, 120], [790, 120], [760, 610], [230, 610]],
      },
    ],
  });

  assert.deepEqual(result.items[0].box, {
    x: 0.21,
    y: 0.12,
    width: 0.58,
    height: 0.49,
  });
  assert.deepEqual(result.items[0].mask[0], [0.21, 0.12]);
});

test('normalizes common Korean color aliases to the app palette', () => {
  const result = normalizeAnalysisPayload({
    items: [{
      category: '상의',
      detailCategory: '반팔티',
      color: '다크 갈색',
      confidence: 0.9,
      box: { x: 0.1, y: 0.1, width: 0.5, height: 0.4 },
    }],
  });

  assert.equal(result.items[0].color, '브라운');
});

test('prompt distinguishes garment midtones from shadows', () => {
  const prompt = buildAnalysisPrompt();

  assert.match(prompt, /중간톤/);
  assert.match(prompt, /그림자/);
  assert.match(prompt, /브라운/);
  assert.match(prompt, /블랙/);
  assert.match(prompt, /사용자 사진 하나만/);
  assert.match(prompt, /샘플 이미지.*절대 참조하지 마세요/);
});

test('validates the nested garment generation request used by Flutter', () => {
  const result = validateGenerationInput({
    item: {
      id: 'detected-1',
      name: '브라운 반팔티',
      category: '상의',
      detailCategory: '반팔티',
      color: 'Dark Chocolate Brown',
      colorHex: '#3A241B',
      materialTexture: 'Smooth cotton jersey',
      fitDescription: 'Slim fit, hip length',
      necklineOrWaist: 'Crew neck',
      englishPrompt: 'A dark chocolate brown slim-fit short-sleeve t-shirt',
    },
  });

  assert.equal(result.category, '상의');
  assert.equal(result.colorHex, '#3A241B');
  assert.equal(result.englishPrompt, 'A dark chocolate brown slim-fit short-sleeve t-shirt');
});

test('builds a studio product prompt without sample or reference imagery', () => {
  const prompt = buildProductImagePrompt({
    category: '상의',
    englishPrompt: 'A dark chocolate brown slim-fit short-sleeve t-shirt, crew neck, smooth cotton fabric',
    color: 'Dark Chocolate Brown',
    materialTexture: 'Smooth cotton fabric',
    fitDescription: 'Slim fit',
    necklineOrWaist: 'Crew neck',
  });

  assert.match(prompt, /studio product shot/i);
  assert.match(prompt, /clean off-white background/i);
  assert.match(prompt, /flat lay style/i);
  assert.match(prompt, /no human model/i);
  assert.doesNotMatch(prompt, /sample image|reference image/i);
});
