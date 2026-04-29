import { Injectable } from '@nestjs/common';
import { Role } from '../common/enums/role.enum';
import {
  AiAssistantDraftIntent,
  AiSupportResponseDto,
  PlanningAssistantResponseDto,
} from './dto';
import { AiGatewayService } from './ai-gateway.service';
import { AiContextService } from './ai-context.service';
import { AiMemoryService } from './ai-memory.service';
import { AiPolicyService } from './ai-policy.service';

type AiSection = {
  label: string;
  content: string;
};

@Injectable()
export class AiHarnessService {
  constructor(
    private readonly aiGatewayService: AiGatewayService,
    private readonly aiContextService: AiContextService,
    private readonly aiMemoryService: AiMemoryService,
    private readonly aiPolicyService: AiPolicyService,
  ) {}

  async generateChatDraft(params: {
    userId: string;
    role: Role;
    conversationId: string;
    intent: AiAssistantDraftIntent;
    prompt?: string | null;
    eventId?: string;
  }): Promise<string | null> {
    const policy = this.aiPolicyService.getDraftPolicy(params.role, params.intent);
    const context = await this.aiContextService.buildChatDraftContext(params);

    return this.generateText({
      useCase: policy.useCase,
      userId: params.userId,
      role: params.role,
      cacheTtlSeconds: policy.cacheTtlSeconds,
      temperature: policy.temperature,
      systemInstructions: policy.systemInstructions,
      prompt: params.prompt?.trim() || `Prepare the next reply for ${context.counterpartName}.`,
      sections: context.sections,
      cacheScope: context.cacheScope,
    });
  }

  async generatePlanningBrief(params: {
    userId: string;
    role: Role;
    prompt: string;
    sections: AiSection[];
    cacheScope: string;
  }): Promise<PlanningAssistantResponseDto | null> {
    const policy = this.aiPolicyService.getPlanningPolicy();
    return this.generateJson<PlanningAssistantResponseDto>({
      useCase: policy.useCase,
      userId: params.userId,
      role: params.role,
      cacheTtlSeconds: policy.cacheTtlSeconds,
      temperature: policy.temperature,
      systemInstructions: policy.systemInstructions,
      prompt: params.prompt,
      sections: params.sections,
      cacheScope: params.cacheScope,
    });
  }

  async generateSupportTriage(params: {
    requesterId?: string;
    actingRole?: Role;
    category?: string;
    subject?: string;
    message: string;
  }): Promise<AiSupportResponseDto | null> {
    const policy = this.aiPolicyService.getSupportTriagePolicy();
    const context = await this.aiContextService.buildSupportTriageContext({
      requesterId: params.requesterId,
      category: params.category,
      subject: params.subject,
      message: params.message,
    });

    return this.generateJson<AiSupportResponseDto>({
      useCase: policy.useCase,
      userId: params.requesterId,
      role: params.actingRole,
      cacheTtlSeconds: policy.cacheTtlSeconds,
      temperature: policy.temperature,
      systemInstructions: policy.systemInstructions,
      prompt: 'Review the support context and return the best triage result.',
      sections: context.sections,
      cacheScope: context.cacheScope,
    });
  }

  async buildPlanningRuntimeContext(
    userId: string,
    role: Role,
    sections: AiSection[],
    prompt: string,
    cacheScope: string,
  ): Promise<PlanningAssistantResponseDto | null> {
    return this.generatePlanningBrief({
      userId,
      role,
      sections,
      prompt,
      cacheScope,
    });
  }

  private async generateText(params: {
    useCase: string;
    userId: string;
    role: Role;
    systemInstructions: string[];
    prompt: string;
    sections: AiSection[];
    cacheScope: string;
    cacheTtlSeconds: number;
    temperature: number;
  }): Promise<string | null> {
    const contextDigest = this.aiMemoryService.buildDigest([
      params.cacheScope,
      params.prompt,
      ...params.sections.map((section) => `${section.label}\n${section.content}`),
    ]);
    const cacheKey = this.aiMemoryService.buildDigest([
      params.useCase,
      params.userId,
      params.role,
      contextDigest,
    ]);

    const cached = await this.aiMemoryService.readCachedResponse<string>(cacheKey);
    if (cached) {
      return cached.payload;
    }

    const result = await this.aiGatewayService.generateText(
      this.toMessages(params.systemInstructions, params.prompt, params.sections),
      {
        temperature: params.temperature,
      },
    );

    if (result == null) {
      return null;
    }

    const runtime = this.aiGatewayService.getRuntimeInfo();
    await this.aiMemoryService.writeCachedResponse({
      cacheKey,
      useCase: params.useCase,
      userId: params.userId,
      role: params.role,
      provider: runtime.provider,
      model: runtime.model,
      contextDigest,
      payload: result,
      ttlSeconds: params.cacheTtlSeconds,
    });

    return result;
  }

  private async generateJson<T>(params: {
    useCase: string;
    userId?: string;
    role?: Role;
    systemInstructions: string[];
    prompt: string;
    sections: AiSection[];
    cacheScope: string;
    cacheTtlSeconds: number;
    temperature: number;
  }): Promise<T | null> {
    const contextDigest = this.aiMemoryService.buildDigest([
      params.cacheScope,
      params.prompt,
      ...params.sections.map((section) => `${section.label}\n${section.content}`),
    ]);
    const cacheKey = this.aiMemoryService.buildDigest([
      params.useCase,
      params.userId,
      params.role,
      contextDigest,
    ]);

    const cached = await this.aiMemoryService.readCachedResponse<T>(cacheKey);
    if (cached) {
      return cached.payload;
    }

    const result = await this.aiGatewayService.generateJson<T>(
      this.toMessages(params.systemInstructions, params.prompt, params.sections),
      {
        temperature: params.temperature,
      },
    );

    if (result == null) {
      return null;
    }

    const runtime = this.aiGatewayService.getRuntimeInfo();
    await this.aiMemoryService.writeCachedResponse({
      cacheKey,
      useCase: params.useCase,
      userId: params.userId ?? null,
      role: params.role ?? null,
      provider: runtime.provider,
      model: runtime.model,
      contextDigest,
      payload: result,
      ttlSeconds: params.cacheTtlSeconds,
    });

    return result;
  }

  private toMessages(
    systemInstructions: string[],
    prompt: string,
    sections: AiSection[],
  ): Array<{ role: 'system' | 'user'; content: string }> {
    const contextBlock = sections
      .map((section) => `[${section.label}]\n${section.content}`)
      .join('\n\n');

    return [
      {
        role: 'system',
        content: systemInstructions.join('\n\n'),
      },
      {
        role: 'user',
        content: `Task:\n${prompt}\n\nContext:\n${contextBlock}`,
      },
    ];
  }
}
