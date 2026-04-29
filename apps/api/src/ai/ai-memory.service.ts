import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { MoreThan, Repository } from 'typeorm';
import { createHash } from 'node:crypto';
import {
  AiContextDocument,
  AiContextScopeType,
  AiResponseCache,
} from './entities';

type UpsertDocumentInput = {
  scopeType: AiContextScopeType;
  scopeId: string;
  sourceType: string;
  title: string;
  body: string;
  keywords?: string[];
  metadata?: Record<string, unknown>;
};

type RetrieveDocumentsInput = {
  query: string;
  scopeIds?: string[];
  scopeTypes?: AiContextScopeType[];
  limit?: number;
};

@Injectable()
export class AiMemoryService {
  constructor(
    private readonly configService: ConfigService,
    @InjectRepository(AiContextDocument)
    private readonly aiContextDocumentsRepository: Repository<AiContextDocument>,
    @InjectRepository(AiResponseCache)
    private readonly aiResponseCacheRepository: Repository<AiResponseCache>,
  ) {}

  async upsertDocuments(inputs: UpsertDocumentInput[]): Promise<void> {
    for (const input of inputs) {
      const trimmedBody = input.body.trim();
      if (trimmedBody.length === 0) {
        continue;
      }

      const existing = await this.aiContextDocumentsRepository.findOne({
        where: {
          scopeType: input.scopeType,
          scopeId: input.scopeId,
          sourceType: input.sourceType,
        },
      });

      const entity = this.aiContextDocumentsRepository.create({
        id: existing?.id,
        scopeType: input.scopeType,
        scopeId: input.scopeId,
        sourceType: input.sourceType,
        title: input.title.trim(),
        body: trimmedBody,
        keywords: this.normalizeKeywords(input.keywords),
        metadata: input.metadata ?? null,
      });

      await this.aiContextDocumentsRepository.save(entity);
    }
  }

  async retrieveDocuments(
    input: RetrieveDocumentsInput,
  ): Promise<AiContextDocument[]> {
    const tokens = this.tokenize(input.query);
    if (tokens.length === 0) {
      return [];
    }

    const candidateLimit =
      this.configService.get<number>('ai.retrievalCandidateLimit') ?? 80;
    const docs = await this.aiContextDocumentsRepository.find({
      order: { updatedAt: 'DESC' },
      take: candidateLimit,
    });

    const filtered = docs.filter((doc) => {
      if (input.scopeIds?.length && !input.scopeIds.includes(doc.scopeId)) {
        return false;
      }
      if (input.scopeTypes?.length && !input.scopeTypes.includes(doc.scopeType)) {
        return false;
      }
      return true;
    });

    return filtered
      .map((doc) => ({
        doc,
        score: this.scoreDocument(doc, tokens),
      }))
      .filter((entry) => entry.score > 0)
      .sort((left, right) => right.score - left.score)
      .slice(0, input.limit ?? (this.configService.get<number>('ai.retrievalLimit') ?? 6))
      .map((entry) => entry.doc);
  }

  buildDigest(parts: Array<string | null | undefined>): string {
    return createHash('sha256')
      .update(parts.filter(Boolean).join('\n---\n'))
      .digest('hex');
  }

  async readCachedResponse<T>(
    cacheKey: string,
  ): Promise<{ payload: T; provider: string; model: string } | null> {
    const cached = await this.aiResponseCacheRepository.findOne({
      where: {
        cacheKey,
        expiresAt: MoreThan(new Date()),
      },
    });

    if (!cached) {
      return null;
    }

    return {
      payload: JSON.parse(cached.payloadJson) as T,
      provider: cached.provider,
      model: cached.model,
    };
  }

  async writeCachedResponse(params: {
    cacheKey: string;
    useCase: string;
    userId?: string | null;
    role?: string | null;
    provider: string;
    model: string;
    contextDigest: string;
    payload: unknown;
    ttlSeconds: number;
  }): Promise<void> {
    const existing = await this.aiResponseCacheRepository.findOne({
      where: { cacheKey: params.cacheKey },
    });

    const entity = this.aiResponseCacheRepository.create({
      id: existing?.id,
      cacheKey: params.cacheKey,
      useCase: params.useCase,
      userId: params.userId ?? null,
      role: params.role ?? null,
      provider: params.provider,
      model: params.model,
      contextDigest: params.contextDigest,
      payloadJson: JSON.stringify(params.payload),
      expiresAt: new Date(Date.now() + params.ttlSeconds * 1000),
    });

    await this.aiResponseCacheRepository.save(entity);
  }

  private scoreDocument(doc: AiContextDocument, tokens: string[]): number {
    const haystack =
      `${doc.title} ${doc.body} ${(doc.keywords ?? []).join(' ')}`.toLowerCase();
    let score = 0;
    for (const token of tokens) {
      if (haystack.includes(token)) {
        score += token.length > 6 ? 3 : 1;
      }
    }
    return score;
  }

  private tokenize(value: string): string[] {
    return Array.from(
      new Set(
        value
          .toLowerCase()
          .split(/[^a-z0-9]+/i)
          .map((token) => token.trim())
          .filter((token) => token.length >= 3),
      ),
    );
  }

  private normalizeKeywords(keywords: string[] | undefined): string[] | null {
    if (!keywords || keywords.length === 0) {
      return null;
    }
    return Array.from(
      new Set(
        keywords
          .map((keyword) => keyword.trim().toLowerCase())
          .filter((keyword) => keyword.length > 0),
      ),
    );
  }
}
