/**
 * The Vault — "Legends" feature generator.
 *
 * Reads a SOURCED fact-sheet brief (seed_data/legend_briefs/<id>.json) and drafts a
 * narrative history feature with Claude, grounded STRICTLY in the brief's facts (never
 * invents). Writes a draft into seed_data/vault_legends.json (+ Flutter asset) for Chris
 * to edit and publish in the admin portal.
 *
 * Usage:  npm run generate-legend            # all briefs
 *         npm run generate-legend -- rupp    # one brief by id
 * Needs ANTHROPIC_API_KEY (.env.local). Falls back to a templated draft if no key.
 */
import { existsSync, readFileSync, writeFileSync, readdirSync, mkdirSync } from "node:fs";
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

const MODEL = process.env.ANTHROPIC_MODEL ?? "claude-opus-4-8";
const BRIEFS_DIR = resolve(__dirname, "../seed_data/legend_briefs");
const OUT = resolve(__dirname, "../seed_data/vault_legends.json");
const ASSET = resolve(__dirname, "../apps/mobile_flutter/assets/vault/vault_legends.json");

const SYSTEM_PROMPT = `You are an elite Kentucky basketball/football historian writing a feature for an independent fan app.

HARD RULES — these override everything:
1. Use ONLY the facts in the brief. Never invent, embellish, estimate, or add a stat, date, score, name, or claim that is not in the brief. If you're unsure, leave it out.
2. Independent fan voice — NOT an official University of Kentucky publication.
3. No betting language (odds, wager, spread, line, parlay, over/under).
4. No official University of Kentucky trademarks/marks.
5. Handle sensitive history (scandals, the integration of the sport) factually, soberly, and respectfully.
6. Write rich, magazine-quality narrative prose for passionate fans. 3-5 sections, each with a heading and 1-2 tight paragraphs.
7. byTheNumbers: pull 4-6 of the most striking figures STRAIGHT from the brief's facts, verbatim where possible.`;

interface Brief { id: string; subject: string; sport: string; era: string; facts: string[]; sources: string[]; }
interface Editorial {
  title: string; subtitle: string;
  sections: { heading: string; body: string }[];
  byTheNumbers: string[]; pullQuote: string; closingLine: string;
}

function templateDraft(b: Brief): Editorial {
  return {
    title: `${b.subject}: ${b.era}`,
    subtitle: `A look back at the ${b.era} era. (Template draft — set ANTHROPIC_API_KEY for the AI version.)`,
    sections: [{ heading: "The Record", body: b.facts.slice(0, 4).join(" ") }, { heading: "The Legacy", body: b.facts.slice(4).join(" ") }],
    byTheNumbers: b.facts.filter((f) => /\d/.test(f)).slice(0, 6),
    pullQuote: b.facts[0] ?? "",
    closingLine: `${b.subject} — ${b.era}.`,
  };
}

async function draftWithLLM(b: Brief): Promise<Editorial> {
  const { default: Anthropic } = await import("@anthropic-ai/sdk");
  const { zodOutputFormat } = await import("@anthropic-ai/sdk/helpers/zod");
  const { z } = await import("zod/v4");
  const Schema = z.object({
    title: z.string(), subtitle: z.string(),
    sections: z.array(z.object({ heading: z.string(), body: z.string() })),
    byTheNumbers: z.array(z.string()), pullQuote: z.string(), closingLine: z.string(),
  });
  const client = new Anthropic();
  const res = await client.messages.parse({
    model: MODEL, max_tokens: 4096,
    thinking: { type: "adaptive" },
    output_config: { effort: "medium", format: zodOutputFormat(Schema, "legend") },
    system: [{ type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
    messages: [{ role: "user", content: `Write the feature on ${b.subject} (${b.sport}, ${b.era}). Facts:\n- ${b.facts.join("\n- ")}` }],
  });
  const e = res.parsed_output;
  if (!e) throw new Error(`null parsed_output (stop_reason=${(res as { stop_reason?: string }).stop_reason ?? "?"})`);
  return e as Editorial;
}

(async () => {
  const only = process.argv[2];
  const files = readdirSync(BRIEFS_DIR).filter((f) => f.endsWith(".json") && (!only || f === `${only}.json`));
  if (files.length === 0) { console.error(`No briefs found${only ? ` for "${only}"` : ""}.`); process.exit(1); }

  const existing: Record<string, unknown>[] = existsSync(OUT)
    ? (JSON.parse(readFileSync(OUT, "utf8")).vault_legends ?? []) : [];
  const byId = new Map(existing.map((a) => [a.id as string, a]));
  const hasKey = Boolean(process.env.ANTHROPIC_API_KEY);
  const now = new Date().toISOString();

  for (const f of files) {
    const brief = JSON.parse(readFileSync(resolve(BRIEFS_DIR, f), "utf8")) as Brief;
    console.log(`\nLegend: ${brief.subject} ${hasKey ? `— Claude (${MODEL})` : "— template (no key)"}`);
    const editorial = hasKey ? await draftWithLLM(brief) : templateDraft(brief);
    byId.set(brief.id, {
      id: brief.id, type: "legend", subject: brief.subject, sport: brief.sport, era: brief.era,
      ...editorial,
      sources: brief.sources, model: hasKey ? MODEL : "template",
      status: "draft", confidence: "researched", generatedAt: now,
    });
    console.log(`  ${editorial.title}`);
  }

  const payload = { _meta: { description: "The Vault — Legends features (AI-drafted from sourced briefs; status:draft until Chris publishes)." }, vault_legends: [...byId.values()] };
  writeFileSync(OUT, JSON.stringify(payload, null, 2) + "\n");
  mkdirSync(dirname(ASSET), { recursive: true });
  writeFileSync(ASSET, JSON.stringify(payload, null, 2) + "\n");
  console.log(`\nWrote ${byId.size} legend(s) -> seed_data/vault_legends.json (+ asset)`);
})();
