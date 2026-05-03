import { readFile } from 'node:fs/promises';
import path from 'node:path';

const provider = process.env.AI_PROVIDER ?? 'ollama';
const baseUrl = process.env.AI_BASE_URL ?? 'http://127.0.0.1:11434';
const model = process.env.AI_MODEL ?? 'llama3.2:latest';
const apiKey = process.env.AI_API_KEY ?? '';
const apiBaseUrl = process.env.API_BASE_URL ?? 'http://127.0.0.1:3000/api';
const manifestPath = path.resolve(process.cwd(), '.tooling/demo/demo-data.json');

async function main() {
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  const headers = {
    'Content-Type': 'application/json',
    ...(apiKey ? { Authorization: `Bearer ${apiKey}` } : {}),
  };

  const directRequest =
    provider === 'openai-compatible'
      ? {
          url: `${baseUrl.replace(/\/+$/, '')}/v1/chat/completions`,
          body: {
            model,
            temperature: 0.15,
            response_format: { type: 'json_object' },
            messages: [
              {
                role: 'system',
                content:
                  'Return strict JSON with keys status and summary. Summary must mention the configured model and local availability.',
              },
              {
                role: 'user',
                content:
                  'Confirm the local Meloo AI runtime is reachable and suitable for chat drafting, planning, and triage checks.',
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
                  'Return strict JSON with keys status and summary. Summary must mention the configured model and local availability.',
              },
              {
                role: 'user',
                content:
                  'Confirm the local Meloo AI runtime is reachable and suitable for chat drafting, planning, and triage checks.',
              },
            ],
          },
        };

  console.error('Checking local AI runtime...');
  const directResponse = await fetch(directRequest.url, {
    method: 'POST',
    headers,
    body: JSON.stringify(directRequest.body),
  });

  if (!directResponse.ok) {
    const text = await directResponse.text();
    throw new Error(`AI runtime check failed with ${directResponse.status}: ${text}`);
  }

  const directData = await directResponse.json();
  const directContent =
    provider === 'openai-compatible'
      ? directData?.choices?.[0]?.message?.content
      : directData?.message?.content;

  console.error('Logging into seeded accounts...');
  const organizer = await login('organizer@meloo.local');
  const sponsor = await login('sponsor@meloo.local');
  const attendee = await login('attendee@meloo.local');
  const admin = await login('admin@meloo.local');

  const planningEvent = manifest.events.find((item) =>
    item.title === 'Kathmandu AI & Civic Tech Summit 2026',
  );
  const seededEventTitles = new Set((manifest.events ?? []).map((item) => item.title));
  const seededOpportunityTitles = new Set(
    (manifest.opportunities ?? []).map((item) => item.title),
  );
  const organizerConversation = manifest.conversations.find((item) =>
    item.participants.includes('organizer@meloo.local') &&
    item.participants.includes('vendor@meloo.local'),
  );

  console.error('Checking deterministic recommendation paths...');
  const attendeeRecommendations = await requestJson('/ai/recommendations/events', {
    token: attendee.accessToken,
  });
  const vendorRecommendations = await requestJson(
    `/ai/recommendations/vendors?eventId=${planningEvent.id}`,
    { token: organizer.accessToken },
  );
  const sponsorRecommendations = await requestJson('/ai/recommendations/opportunities', {
    token: sponsor.accessToken,
  });

  console.error('Checking organizer planning generation...');
  const planning = await requestJson('/ai/planning/organizer', {
      method: 'POST',
      token: organizer.accessToken,
      body: {
        eventId: planningEvent.id,
        expectedAttendees: 280,
        budget: '650000',
        planningGoal:
          'lock vendor owners, ticket pacing, and sponsor activation sequencing for the Kathmandu summit',
      },
    });

  console.error('Checking chat draft generation...');
  const chatDraft = await requestJson('/ai/assistant/draft', {
      method: 'POST',
      token: organizer.accessToken,
      body: {
        intent: 'chat_reply',
        conversationId: organizerConversation.conversationId,
        eventId: planningEvent.id,
        prompt: 'Reply with the next concrete operational step.',
      },
    });

  console.error('Checking support triage generation...');
  const supportTriage = await requestJson('/ai/support/respond', {
      method: 'POST',
      token: admin.accessToken,
      body: {
        category: 'payment',
        message:
          'An attendee is worried that a paid pass checkout may not be configured correctly before launch. What should support do next?',
      },
    });

  const attendeeTopEvent =
    attendeeRecommendations.find((item) => seededEventTitles.has(item.event.title)) ??
    attendeeRecommendations[0] ??
    null;
  const organizerTopVendor = vendorRecommendations[0] ?? null;
  const sponsorTopOpportunity =
    sponsorRecommendations.find((item) =>
      seededOpportunityTitles.has(item.opportunity.title),
    ) ??
    sponsorRecommendations[0] ??
    null;

  const runtimeCheck = safeJsonParse(directContent);
  const summary = {
    provider,
    model,
    runtime: {
      status: runtimeCheck?.status ?? 'ok',
      provider,
      model,
      baseUrl,
      rawModelSummary: runtimeCheck?.summary ?? null,
    },
    attendeeTopEvent: attendeeTopEvent
      ? {
          score: attendeeTopEvent.score,
          title: attendeeTopEvent.event.title,
          reason: attendeeTopEvent.reasonSummary,
        }
      : null,
    organizerTopVendor: organizerTopVendor
      ? {
          score: organizerTopVendor.score,
          vendor: organizerTopVendor.vendor.businessName,
          reason: organizerTopVendor.reasonSummary,
        }
      : null,
    sponsorTopOpportunity: sponsorTopOpportunity
      ? {
          score: sponsorTopOpportunity.score,
          title: sponsorTopOpportunity.opportunity.title,
          reason: sponsorTopOpportunity.reasonSummary,
        }
      : null,
    planningOverview: planning.overview,
    draftPreview: chatDraft.content,
    supportSuggestion: supportTriage.suggestion,
  };

  console.log(JSON.stringify(summary, null, 2));
}

async function login(email) {
  const response = await requestJson('/auth/login', {
    method: 'POST',
    body: {
      email,
      password: 'Password123!',
    },
  });

  return response.tokens;
}

async function requestJson(pathname, options = {}) {
  const response = await fetch(`${apiBaseUrl}${pathname}`, {
    method: options.method ?? 'GET',
    headers: {
      ...(options.token ? { Authorization: `Bearer ${options.token}` } : {}),
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  const text = await response.text();
  const data = text ? JSON.parse(text) : null;
  if (!response.ok) {
    throw new Error(
      data?.message instanceof Array
        ? data.message.join(', ')
        : data?.message ?? `Request failed for ${pathname}`,
    );
  }
  return data;
}

function safeJsonParse(content) {
  if (typeof content !== 'string') {
    return content ?? null;
  }

  try {
    return JSON.parse(
      content
        .trim()
        .replace(/^```[a-zA-Z0-9_-]*\s*/, '')
        .replace(/\s*```$/, ''),
    );
  } catch {
    return { raw: content.trim() };
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
