import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

type ChatMessage = {
  role: 'system' | 'user' | 'assistant';
  content: string;
};

@Injectable()
export class AiGatewayService {
  private readonly logger = new Logger(AiGatewayService.name);

  constructor(private readonly configService: ConfigService) {}

  async generateJson<T>(
    messages: ChatMessage[],
  ): Promise<T | null> {
    const enabled = this.configService.get<boolean>('ai.enabled') ?? true;
    if (!enabled) {
      return null;
    }

    const provider = this.configService.get<string>('ai.provider') ?? 'ollama';
    const baseUrl = this.configService.get<string>('ai.baseUrl') ?? 'http://127.0.0.1:11434';
    const model = this.configService.get<string>('ai.model') ?? 'llama3.2:latest';
    const apiKey = this.configService.get<string>('ai.apiKey') ?? '';
    const timeoutMs = this.configService.get<number>('ai.timeoutMs') ?? 25_000;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };
    if (apiKey.length > 0) {
      headers.Authorization = `Bearer ${apiKey}`;
    }

    try {
      const response =
        provider === 'openai-compatible'
        ? await fetch(this.joinUrl(baseUrl, '/v1/chat/completions'), {
            method: 'POST',
            headers,
            body: JSON.stringify({
              model,
              temperature: 0.2,
              response_format: { type: 'json_object' },
              messages,
            }),
            signal: controller.signal,
          })
        : await fetch(this.joinUrl(baseUrl, '/api/chat'), {
            method: 'POST',
            headers,
            body: JSON.stringify({
              model,
              stream: false,
              format: 'json',
              messages,
            }),
            signal: controller.signal,
          });

      if (!response.ok) {
        const message = await response.text();
        this.logger.warn(`Model request failed with ${response.status}: ${message}`);
        return null;
      }

      const data = await response.json();
      const content = provider === 'openai-compatible'
        ? data?.choices?.[0]?.message?.content
        : data?.message?.content;

      if (typeof content !== 'string' || content.trim().length === 0) {
        return null;
      }

      return JSON.parse(this.stripMarkdownFences(content)) as T;
    } catch (error) {
      this.logger.warn(
        `Model request failed: ${error instanceof Error ? error.message : String(error)}`,
      );
      return null;
    } finally {
      clearTimeout(timeout);
    }
  }

  private joinUrl(baseUrl: string, pathname: string): string {
    return `${baseUrl.replace(/\/+$/, '')}${pathname}`;
  }

  private stripMarkdownFences(content: string): string {
    const trimmed = content.trim();
    if (!trimmed.startsWith('```')) {
      return trimmed;
    }

    return trimmed
      .replace(/^```[a-zA-Z0-9_-]*\s*/, '')
      .replace(/\s*```$/, '')
      .trim();
  }
}
