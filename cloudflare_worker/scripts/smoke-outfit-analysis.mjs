import { deflateSync } from 'node:zlib';

const width = 512;
const height = 768;

function crc32(buffer) {
  let crc = 0xffffffff;
  for (const byte of buffer) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) {
      crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const typeBuffer = Buffer.from(type, 'ascii');
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const checksum = Buffer.alloc(4);
  checksum.writeUInt32BE(crc32(Buffer.concat([typeBuffer, data])));
  return Buffer.concat([length, typeBuffer, data, checksum]);
}

const rows = [];
for (let y = 0; y < height; y += 1) {
  const row = Buffer.alloc(1 + width * 3);
  row[0] = 0;
  for (let x = 0; x < width; x += 1) {
    let color = [247, 244, 237];
    if (x >= 120 && x <= 392 && y >= 100 && y <= 340) color = [34, 38, 45];
    if (x >= 145 && x <= 250 && y >= 340 && y <= 650) color = [190, 160, 112];
    if (x >= 262 && x <= 367 && y >= 340 && y <= 650) color = [190, 160, 112];
    if (x >= 105 && x <= 255 && y >= 640 && y <= 705) color = [220, 220, 216];
    if (x >= 258 && x <= 408 && y >= 640 && y <= 705) color = [220, 220, 216];
    const offset = 1 + x * 3;
    row[offset] = color[0];
    row[offset + 1] = color[1];
    row[offset + 2] = color[2];
  }
  rows.push(row);
}

const header = Buffer.alloc(13);
header.writeUInt32BE(width, 0);
header.writeUInt32BE(height, 4);
header[8] = 8;
header[9] = 2;

const png = Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  chunk('IHDR', header),
  chunk('IDAT', deflateSync(Buffer.concat(rows))),
  chunk('IEND', Buffer.alloc(0)),
]);

const endpoint = process.env.CHAKCHAK_AI_API_URL
  ?? 'https://chakchak-ai-api.maison-elan-springseed.workers.dev/api/outfit-analysis';
const response = await fetch(endpoint, {
  method: 'POST',
  headers: {
    Origin: 'http://127.0.0.1:4180',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    imageBase64: png.toString('base64'),
    mimeType: 'image/png',
    wardrobe: [],
  }),
});

console.log(response.status);
console.log(await response.text());
