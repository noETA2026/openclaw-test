#!/usr/bin/env node
// Bad Apple ASCII Animation → Discord Player
// Usage: node badapple-play.js <frames.txt> [bot_token] [channel_id]
//
// Frames file: SPLIT-separated ASCII art frames ($ = background)
// Rate limit: 4 messages / 5 seconds (1250ms apart)

const fs = require('fs');
const https = require('https');

const FILE = process.argv[2];
const TOKEN = process.argv[3] || process.env.DISCORD_TOKEN;
const CHANNEL = process.argv[4] || process.env.DISCORD_CHANNEL;
const DELAY_MS = 1250; // 4 msgs / 5s

if (!FILE) {
  console.error('Usage: node badapple-play.js <frames.txt> [bot_token] [channel_id]');
  process.exit(1);
}
if (!TOKEN || !CHANNEL) {
  console.error('Error: Provide bot_token and channel_id, or set DISCORD_TOKEN and DISCORD_CHANNEL');
  process.exit(1);
}

async function postMessage(content) {
  const body = JSON.stringify({ content });
  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'discord.com',
      path: `/api/v10/channels/${CHANNEL}/messages`,
      method: 'POST',
      headers: {
        'Authorization': `Bot ${TOKEN}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
    }, res => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        if (res.statusCode === 429) {
          const retry = JSON.parse(data).retry_after || 2;
          console.log(`⏳ Rate limited, waiting ${retry}s...`);
          resolve({ retry: true, retryAfter: retry });
        } else if (res.statusCode >= 400) {
          console.error(`❌ ${res.statusCode}: ${data.slice(0, 200)}`);
          resolve({ error: true });
        } else {
          resolve({ ok: true });
        }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function main() {
  const raw = fs.readFileSync(FILE, 'utf8');
  const frames = raw.split('SPLIT').map(f => f.trimEnd()).filter(f => f.length > 0);

  console.log(`Frames: ${frames.length}, Delay: ${DELAY_MS}ms`);
  console.log('Starting in 3s...');
  await sleep(3000);

  let sent = 0, skipped = 0, errors = 0;
  const start = Date.now();
  let prev = '';

  for (let i = 0; i < frames.length; i++) {
    if (frames[i] === prev) { skipped++; continue; }
    prev = frames[i];

    const art = frames[i].replace(/\$/g, ' ');
    const msg = '```\n' + art + '\n```';

    if (msg.length > 2000) {
      console.warn(`⚠ Frame ${i + 1} too long (${msg.length} chars), skipping`);
      errors++;
      continue;
    }

    const result = await postMessage(msg);
    if (result.retry) {
      await sleep(result.retryAfter * 1000);
      const retry = await postMessage(msg);
      if (retry.error || retry.retry) errors++;
      else sent++;
    } else if (result.error) {
      errors++;
    } else {
      sent++;
    }

    if ((sent + skipped + errors) % 50 === 0) {
      const elapsed = ((Date.now() - start) / 1000).toFixed(1);
      console.log(`[${elapsed}s] sent:${sent} skip:${skipped} err:${errors}`);
    }
    await sleep(DELAY_MS);
  }

  const total = ((Date.now() - start) / 1000).toFixed(1);
  console.log(`\n✅ Done! ${total}s | sent:${sent} skip:${skipped} err:${errors}`);
}

main().catch(e => { console.error(e); process.exit(1); });
