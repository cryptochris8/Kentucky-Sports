/**
 * Validate the configured API keys WITHOUT printing their values.
 * Loads .env.local (root + functions), makes a minimal auth check per key,
 * and prints only pass/fail (+ a masked tail). Run: npm --prefix scripts run check-keys
 */
import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
for (const p of [resolve(__dirname, "../.env.local"), resolve(__dirname, "../functions/.env.local")]) {
  if (!existsSync(p)) continue;
  for (const line of readFileSync(p, "utf8").split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, "");
  }
}

const mask = (k?: string) => (k ? `set, len ${k.length}, ends …${k.slice(-4)}` : "NOT SET");

async function checkAnthropic() {
  const key = process.env.ANTHROPIC_API_KEY;
  if (!key) return console.log("ANTHROPIC_API_KEY  : NOT SET");
  try {
    const { default: Anthropic } = await import("@anthropic-ai/sdk");
    const c = new Anthropic({ apiKey: key });
    const r = await c.messages.countTokens({
      model: "claude-opus-4-8",
      messages: [{ role: "user", content: "ping" }],
    });
    console.log(`ANTHROPIC_API_KEY  : VALID (auth OK, count_tokens=${r.input_tokens})  [${mask(key)}]`);
  } catch (e: unknown) {
    const status = (e as { status?: number })?.status;
    const msg = (e as { message?: string })?.message ?? String(e);
    console.log(`ANTHROPIC_API_KEY  : INVALID (${status ?? "?"})  [${mask(key)}]  ${msg.slice(0, 80)}`);
  }
}

async function checkHttp(name: string, url: string) {
  const key = process.env[name];
  if (!key) return console.log(`${name.padEnd(19)}: NOT SET`);
  try {
    const res = await fetch(url, { headers: { Authorization: `Bearer ${key}` } });
    const verdict =
      res.status === 200 ? "VALID (auth OK)" : res.status === 401 ? "INVALID (401 bad key)" : `status ${res.status}`;
    console.log(`${name.padEnd(19)}: ${verdict}  [${mask(key)}]`);
  } catch (e: unknown) {
    console.log(`${name.padEnd(19)}: request failed (${(e as { message?: string })?.message ?? e})  [${mask(key)}]`);
  }
}

await checkAnthropic();
await checkHttp("CFBD_API_KEY", "https://api.collegefootballdata.com/teams?conference=SEC");
await checkHttp("CBBD_API_KEY", "https://api.collegebasketballdata.com/teams");
