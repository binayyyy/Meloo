import { registerAs } from '@nestjs/config';

function parseBoolean(value: string | undefined, fallback: boolean): boolean {
  if (value == null) {
    return fallback;
  }

  const normalized = value.trim().toLowerCase();
  if (['1', 'true', 'yes', 'on'].includes(normalized)) {
    return true;
  }
  if (['0', 'false', 'no', 'off'].includes(normalized)) {
    return false;
  }
  return fallback;
}

function parseNumber(value: string | undefined, fallback: number): number {
  const parsed = Number.parseInt(value ?? '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

export default registerAs('ai', () => ({
  enabled: parseBoolean(process.env.AI_ENABLED, true),
  provider: process.env.AI_PROVIDER ?? 'ollama',
  baseUrl: process.env.AI_BASE_URL ?? 'http://127.0.0.1:11434',
  model: process.env.AI_MODEL ?? 'llama3.2:latest',
  apiKey: process.env.AI_API_KEY ?? '',
  timeoutMs: parseNumber(process.env.AI_TIMEOUT_MS, 300_000),
  temperature: parseNumber(process.env.AI_TEMPERATURE, 2) / 10,
  retrievalLimit: parseNumber(process.env.AI_RETRIEVAL_LIMIT, 6),
  retrievalCandidateLimit: parseNumber(
    process.env.AI_RETRIEVAL_CANDIDATE_LIMIT,
    80,
  ),
}));
