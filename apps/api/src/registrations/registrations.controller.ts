import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';
import { AccessTokenGuard } from '../common/guards/access-token.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import {
  CreateRegistrationDto,
  CreateTicketTypeDto,
  RegistrationResponseDto,
  TicketTypeResponseDto,
  UpdateTicketTypeDto,
} from './dto';
import { RegistrationsService } from './registrations.service';

@Controller()
export class RegistrationsController {
  constructor(private readonly registrationsService: RegistrationsService) {}

  @Get('events/:id/ticket-types')
  listPublicTicketTypes(
    @Param('id') eventId: string,
  ): Promise<TicketTypeResponseDto[]> {
    return this.registrationsService.listPublicTicketTypes(eventId);
  }

  @Get('events/:id/ticket-types/manage')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  listManageTicketTypes(
    @Param('id') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<TicketTypeResponseDto[]> {
    return this.registrationsService.listManageTicketTypes(
      eventId,
      user.sub,
      user.role,
    );
  }

  @Post('events/:id/ticket-types')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  createTicketType(
    @Param('id') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateTicketTypeDto,
  ): Promise<TicketTypeResponseDto> {
    return this.registrationsService.createTicketType(
      eventId,
      user.sub,
      user.role,
      dto,
    );
  }

  @Patch('ticket-types/:id')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  updateTicketType(
    @Param('id') ticketTypeId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateTicketTypeDto,
  ): Promise<TicketTypeResponseDto> {
    return this.registrationsService.updateTicketType(
      ticketTypeId,
      user.sub,
      user.role,
      dto,
    );
  }

  @Post('events/:id/registrations')
  @UseGuards(AccessTokenGuard)
  createRegistration(
    @Param('id') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateRegistrationDto,
  ): Promise<RegistrationResponseDto> {
    return this.registrationsService.createRegistration(eventId, user.sub, dto);
  }

  @Get('registrations/my')
  @UseGuards(AccessTokenGuard)
  listMyRegistrations(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<RegistrationResponseDto[]> {
    return this.registrationsService.listMyRegistrations(user.sub);
  }
}

