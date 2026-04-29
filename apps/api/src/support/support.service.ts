import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiService } from '../ai/ai.service';
import { Role } from '../common/enums/role.enum';
import { NotificationType } from '../notifications/entities';
import { NotificationsService } from '../notifications/notifications.service';
import { User } from '../users/entities';
import {
  CreateSupportTicketDto,
  EscalationResponseDto,
  SupportTicketResponseDto,
} from './dto';
import {
  Escalation,
  EscalationSourceType,
  EscalationStatus,
  SupportTicket,
  SupportTicketCategory,
  SupportTicketPriority,
  SupportTicketStatus,
} from './entities';

@Injectable()
export class SupportService {
  constructor(
    private readonly aiService: AiService,
    private readonly notificationsService: NotificationsService,
    @InjectRepository(SupportTicket)
    private readonly supportTicketsRepository: Repository<SupportTicket>,
    @InjectRepository(Escalation)
    private readonly escalationsRepository: Repository<Escalation>,
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  async createTicket(
    userId: string,
    dto: CreateSupportTicketDto,
  ): Promise<SupportTicketResponseDto> {
    const requester = await this.getUserOrFail(userId);
    const assistant = await this.aiService.generateSupportAssistance(
      dto.category,
      dto.description,
      {
        requesterId: userId,
        actingRole: Role.ADMIN,
        subject: dto.subject,
      },
    );

    const ticket = await this.supportTicketsRepository.save(
      this.supportTicketsRepository.create({
        userId,
        category: dto.category,
        subject: dto.subject.trim(),
        description: dto.description.trim(),
        status: SupportTicketStatus.OPEN,
        priority: assistant.priority as SupportTicketPriority,
        assistantSuggestion: assistant.suggestion,
        aiConfidence: assistant.confidence,
      }),
    );

    let escalation: Escalation | null = null;
    if (assistant.shouldEscalate && assistant.escalationReason != null) {
      escalation = await this.escalationsRepository.save(
        this.escalationsRepository.create({
          sourceType: EscalationSourceType.SUPPORT_TICKET,
          sourceId: ticket.id,
          reason: assistant.escalationReason,
          aiConfidence: assistant.confidence,
          status: EscalationStatus.OPEN,
        }),
      );
    }

    await this.notificationsService.createNotification({
      userId,
      type: NotificationType.SUPPORT,
      title: 'Support ticket created',
      body: `Your ticket "${ticket.subject}" is now ${ticket.status}.`,
      resourceType: 'support-ticket',
      resourceId: ticket.id,
    });

    return this.toTicketResponse(ticket, requester, escalation);
  }

  async listMyTickets(userId: string): Promise<SupportTicketResponseDto[]> {
    const tickets = await this.supportTicketsRepository.find({
      where: { userId },
      relations: {
        user: {
          profile: true,
        },
      },
      order: { createdAt: 'DESC' },
    });

    const escalations = await this.findEscalationsForTickets(tickets.map((ticket) => ticket.id));
    return tickets.map((ticket) =>
      this.toTicketResponse(ticket, ticket.user, escalations.get(ticket.id) ?? null),
    );
  }

  async getTicketForUser(
    userId: string,
    ticketId: string,
    role: Role,
  ): Promise<SupportTicketResponseDto> {
    const ticket = await this.supportTicketsRepository.findOne({
      where: { id: ticketId },
      relations: {
        user: {
          profile: true,
        },
      },
    });

    if (!ticket) {
      throw new NotFoundException('Support ticket not found');
    }

    if (role !== Role.ADMIN && ticket.userId !== userId) {
      throw new NotFoundException('Support ticket not found');
    }

    const escalation = await this.escalationsRepository.findOne({
      where: {
        sourceType: EscalationSourceType.SUPPORT_TICKET,
        sourceId: ticket.id,
      },
    });

    return this.toTicketResponse(ticket, ticket.user, escalation);
  }

  async listEscalations(): Promise<EscalationResponseDto[]> {
    const escalations = await this.escalationsRepository.find({
      order: { createdAt: 'DESC' },
    });
    return escalations.map((escalation) => this.toEscalationResponse(escalation));
  }

  async listAllTickets(): Promise<SupportTicketResponseDto[]> {
    const tickets = await this.supportTicketsRepository.find({
      relations: {
        user: {
          profile: true,
        },
      },
      order: { createdAt: 'DESC' },
    });

    const escalations = await this.findEscalationsForTickets(tickets.map((ticket) => ticket.id));
    return tickets.map((ticket) =>
      this.toTicketResponse(ticket, ticket.user, escalations.get(ticket.id) ?? null),
    );
  }

  async assignTicket(
    ticketId: string,
    adminUserId: string,
  ): Promise<SupportTicketResponseDto> {
    const ticket = await this.supportTicketsRepository.findOne({
      where: { id: ticketId },
      relations: {
        user: {
          profile: true,
        },
      },
    });

    if (!ticket) {
      throw new NotFoundException('Support ticket not found');
    }

    ticket.assignedAdminId = adminUserId;
    ticket.status = SupportTicketStatus.IN_PROGRESS;
    await this.supportTicketsRepository.save(ticket);

    const escalation = await this.escalationsRepository.findOne({
      where: {
        sourceType: EscalationSourceType.SUPPORT_TICKET,
        sourceId: ticket.id,
      },
    });

    if (escalation) {
      escalation.assignedTo = adminUserId;
      escalation.status = EscalationStatus.IN_REVIEW;
      await this.escalationsRepository.save(escalation);
    }

    await this.notificationsService.createNotification({
      userId: ticket.userId,
      type: NotificationType.SUPPORT,
      title: 'Support ticket assigned',
      body: `An admin is now reviewing "${ticket.subject}".`,
      resourceType: 'support-ticket',
      resourceId: ticket.id,
    });

    return this.toTicketResponse(ticket, ticket.user, escalation);
  }

  async resolveTicket(ticketId: string): Promise<SupportTicketResponseDto> {
    const ticket = await this.supportTicketsRepository.findOne({
      where: { id: ticketId },
      relations: {
        user: {
          profile: true,
        },
      },
    });

    if (!ticket) {
      throw new NotFoundException('Support ticket not found');
    }

    ticket.status = SupportTicketStatus.RESOLVED;
    await this.supportTicketsRepository.save(ticket);

    const escalation = await this.escalationsRepository.findOne({
      where: {
        sourceType: EscalationSourceType.SUPPORT_TICKET,
        sourceId: ticket.id,
      },
    });

    if (escalation) {
      escalation.status = EscalationStatus.RESOLVED;
      await this.escalationsRepository.save(escalation);
    }

    await this.notificationsService.createNotification({
      userId: ticket.userId,
      type: NotificationType.SUPPORT,
      title: 'Support ticket resolved',
      body: `Your ticket "${ticket.subject}" has been resolved.`,
      resourceType: 'support-ticket',
      resourceId: ticket.id,
    });

    return this.toTicketResponse(ticket, ticket.user, escalation);
  }

  private async getUserOrFail(userId: string): Promise<User> {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      relations: {
        profile: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  private async findEscalationsForTickets(
    ticketIds: string[],
  ): Promise<Map<string, Escalation>> {
    if (ticketIds.length === 0) {
      return new Map();
    }

    const escalations = await this.escalationsRepository.find({
      where: {
        sourceType: EscalationSourceType.SUPPORT_TICKET,
      },
    });

    return new Map(
      escalations
        .filter((escalation) => ticketIds.includes(escalation.sourceId))
        .map((escalation) => [escalation.sourceId, escalation]),
    );
  }

  private toTicketResponse(
    ticket: SupportTicket,
    requester: User,
    escalation: Escalation | null,
  ): SupportTicketResponseDto {
    return {
      id: ticket.id,
      category: ticket.category,
      subject: ticket.subject,
      description: ticket.description,
      status: ticket.status,
      priority: ticket.priority,
      requester: {
        userId: requester.id,
        email: requester.email,
        role: requester.role,
        fullName: requester.profile?.fullName ?? null,
      },
      assignedAdminId: ticket.assignedAdminId,
      assistantSuggestion: ticket.assistantSuggestion,
      aiConfidence: ticket.aiConfidence,
      escalation: escalation ? this.toEscalationResponse(escalation) : null,
      createdAt: ticket.createdAt,
      updatedAt: ticket.updatedAt,
    };
  }

  private toEscalationResponse(escalation: Escalation): EscalationResponseDto {
    return {
      id: escalation.id,
      sourceType: escalation.sourceType,
      sourceId: escalation.sourceId,
      reason: escalation.reason,
      aiConfidence: escalation.aiConfidence,
      status: escalation.status,
      assignedTo: escalation.assignedTo,
      createdAt: escalation.createdAt,
      updatedAt: escalation.updatedAt,
    };
  }
}
