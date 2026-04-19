import { Role } from '../../common/enums/role.enum';
import {
  EscalationStatus,
  SupportTicketCategory,
  SupportTicketPriority,
  SupportTicketStatus,
} from '../entities';

export class SupportTicketUserSummaryDto {
  userId!: string;
  email!: string;
  role!: Role;
  fullName!: string | null;
}

export class EscalationResponseDto {
  id!: string;
  sourceType!: string;
  sourceId!: string;
  reason!: string;
  aiConfidence!: string;
  status!: EscalationStatus;
  assignedTo!: string | null;
  createdAt!: Date;
  updatedAt!: Date;
}

export class SupportTicketResponseDto {
  id!: string;
  category!: SupportTicketCategory;
  subject!: string;
  description!: string;
  status!: SupportTicketStatus;
  priority!: SupportTicketPriority;
  requester!: SupportTicketUserSummaryDto;
  assignedAdminId!: string | null;
  assistantSuggestion!: string | null;
  aiConfidence!: string | null;
  escalation!: EscalationResponseDto | null;
  createdAt!: Date;
  updatedAt!: Date;
}
