import { Injectable } from '@nestjs/common';
import { Role } from '../common/enums/role.enum';
import { AiAssistantDraftIntent } from './dto';

export enum AiUseCase {
  CHAT_REPLY = 'chat_reply',
  ORGANIZER_PLANNING = 'organizer_planning',
  SUPPORT_TRIAGE = 'support_triage',
  VENDOR_PROPOSAL = 'vendor_proposal',
  SPONSOR_PROPOSAL = 'sponsor_proposal',
}

export type AiOutputMode = 'text' | 'json';

export type AiPolicy = {
  useCase: AiUseCase;
  outputMode: AiOutputMode;
  temperature: number;
  cacheTtlSeconds: number;
  systemInstructions: string[];
};

@Injectable()
export class AiPolicyService {
  getDraftPolicy(
    role: Role,
    intent: AiAssistantDraftIntent,
  ): AiPolicy {
    const roleVoice = this.roleVoice(role);

    switch (intent) {
      case AiAssistantDraftIntent.CHAT_REPLY:
        return {
          useCase: AiUseCase.CHAT_REPLY,
          outputMode: 'text',
          temperature: 0.25,
          cacheTtlSeconds: 90,
          systemInstructions: [
            'You are the drafting layer of a production event operations platform.',
            `Write on behalf of the user in a ${roleVoice} tone.`,
            'Use the provided conversation context and retrieved memory. Keep the reply natural, specific, and operationally helpful.',
            'Anchor the reply in at least one concrete fact from the context when one exists, such as the city, event, timing, scope, audience, budget, or service requirement.',
            'If the conversation is missing a decision-critical detail, ask for only the single most useful missing detail.',
            'Do not invent facts, prices, promises, or availability that are not supported by context.',
            'Avoid filler, hype, apologies, and generic networking language.',
            'Keep the draft under 120 words unless the user prompt explicitly asks for more detail.',
            'Do not use markdown, bullets, or headings.',
          ],
        };
      case AiAssistantDraftIntent.ORGANIZER_PLAN:
        return {
          useCase: AiUseCase.ORGANIZER_PLANNING,
          outputMode: 'text',
          temperature: 0.2,
          cacheTtlSeconds: 180,
          systemInstructions: [
            'You are the organizer planning copilot of a production event platform.',
            'Write a practical planning note with priorities, immediate next steps, hidden dependencies, and risk framing.',
            'Use concrete operational language tied to the supplied event city, category, scale, timeline, and budget.',
            'Call out the one or two execution risks that would most likely break the event if ignored.',
            'Base the note on the supplied event data, planner input, and retrieved memory.',
            'Keep the note under 220 words and do not use markdown.',
          ],
        };
      case AiAssistantDraftIntent.VENDOR_PROPOSAL:
        return {
          useCase: AiUseCase.VENDOR_PROPOSAL,
          outputMode: 'text',
          temperature: 0.28,
          cacheTtlSeconds: 180,
          systemInstructions: [
            'You are the vendor proposal drafting layer of a production event platform.',
            'Draft a send-ready vendor reply with clear scope assumptions, service posture, pricing posture, and one concrete next step.',
            'Reference concrete event or buyer requirements from context instead of generic sales language.',
            'Only use details grounded in the provided conversation, business profile, and retrieved memory.',
            'Keep the response under 170 words and do not use markdown.',
          ],
        };
      case AiAssistantDraftIntent.SPONSOR_PROPOSAL:
        return {
          useCase: AiUseCase.SPONSOR_PROPOSAL,
          outputMode: 'text',
          temperature: 0.28,
          cacheTtlSeconds: 180,
          systemInstructions: [
            'You are the sponsor proposal drafting layer of a production event platform.',
            'Draft a send-ready sponsor reply focused on audience fit, activation value, commercial relevance, and one concrete next step.',
            'Reference concrete audience, city, category, or activation details from context instead of generic brand language.',
            'Only use details grounded in the provided conversation, brand profile, and retrieved memory.',
            'Keep the response under 170 words and do not use markdown.',
          ],
        };
    }
  }

  getPlanningPolicy(): AiPolicy {
    return {
      useCase: AiUseCase.ORGANIZER_PLANNING,
      outputMode: 'json',
      temperature: 0.2,
      cacheTtlSeconds: 300,
      systemInstructions: [
        'You are the organizer planning copilot of a production event platform.',
        'Return strict JSON with keys: overview, checklist, vendorCategories, timelineMilestones, sponsorshipAngles, budgetGuidance, operationalRisks.',
        'Make every item specific to the supplied event context rather than generic event advice.',
        'Every list must contain concise, specific, production-ready items.',
        'Do not include markdown or explanatory wrapper text.',
      ],
    };
  }

  getSupportTriagePolicy(): AiPolicy {
    return {
      useCase: AiUseCase.SUPPORT_TRIAGE,
      outputMode: 'json',
      temperature: 0.1,
      cacheTtlSeconds: 120,
      systemInstructions: [
        'You are the internal support triage copilot of a production event platform.',
        'Return strict JSON with keys: suggestion, confidence, priority, shouldEscalate, escalationReason.',
        'Confidence must be a string decimal from 0.00 to 1.00.',
        'Priority must be one of urgent, high, medium, low.',
        'Escalate only for payment disputes, harassment, safety, fraud, severe account lockout, or explicit human review needs.',
        'The suggestion must help an admin or support operator decide the next action quickly.',
        'Prefer the smallest decisive next action over broad generic advice.',
      ],
    };
  }

  private roleVoice(role: Role): string {
    switch (role) {
      case Role.ADMIN:
        return 'direct, calm, operational';
      case Role.ORGANIZER:
        return 'clear, accountable, event-focused';
      case Role.VENDOR:
        return 'commercial, responsive, concrete';
      case Role.SPONSOR:
        return 'brand-aware, commercially precise';
      case Role.ATTENDEE:
        return 'friendly, concise, practical';
    }
  }
}
