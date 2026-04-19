const provider = process.env.AI_PROVIDER ?? 'ollama';
const baseUrl = process.env.AI_BASE_URL ?? 'http://127.0.0.1:11434';
const model = process.env.AI_MODEL ?? 'llama3.2:latest';
const apiKey = process.env.AI_API_KEY ?? '';

const headers = {
  'Content-Type': 'application/json',
  ...(apiKey ? { Authorization: `Bearer ${apiKey}` } : {}),
};

const request =
  provider === 'openai-compatible'
    ? {
        url: `${baseUrl.replace(/\/+$/, '')}/v1/chat/completions`,
        body: {
          model,
          temperature: 0.2,
          response_format: { type: 'json_object' },
          messages: [
            {
              role: 'system',
              content:
                'Return strict JSON with keys status and summary. Keep summary short.',
            },
            {
              role: 'user',
              content: 'Confirm the local Smart Event AI integration is reachable.',
            },
          ],
        },
      }
    : {
        url: `${baseUrl.replace(/\/+$/, '')}/api/chat`,
        body: {
          model,
          stream: false,
          format: 'json',
          messages: [
            {
              role: 'system',
              content:
                'Return strict JSON with keys status and summary. Keep summary short.',
            },
            {
              role: 'user',
              content: 'Confirm the local Smart Event AI integration is reachable.',
            },
          ],
        },
      };

const response = await fetch(request.url, {
  method: 'POST',
  headers,
  body: JSON.stringify(request.body),
});

if (!response.ok) {
  const text = await response.text();
  console.error(`AI check failed with ${response.status}: ${text}`);
  process.exit(1);
}

const data = await response.json();
console.log(JSON.stringify(data, null, 2));
