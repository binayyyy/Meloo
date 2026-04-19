import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';
import { AccessTokenGuard } from '../common/guards/access-token.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import {
  CreateSupportTicketDto,
  EscalationResponseDto,
  SupportTicketResponseDto,
} from './dto';
import { SupportService } from './support.service';

@Controller('support')
@UseGuards(AccessTokenGuard)
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post('tickets')
  createTicket(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateSupportTicketDto,
  ): Promise<SupportTicketResponseDto> {
    return this.supportService.createTicket(user.sub, dto);
  }

  @Get('tickets/my')
  listMyTickets(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SupportTicketResponseDto[]> {
    return this.supportService.listMyTickets(user.sub);
  }

  @Get('tickets/:id')
  getTicket(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') ticketId: string,
  ): Promise<SupportTicketResponseDto> {
    return this.supportService.getTicketForUser(user.sub, ticketId, user.role);
  }

  @Get('escalations')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ADMIN)
  listEscalations(): Promise<EscalationResponseDto[]> {
    return this.supportService.listEscalations();
  }
}
