import { Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AccessTokenGuard } from '../common/guards/access-token.guard';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import { MessageResponseDto } from '../auth/dto';
import { NotificationResponseDto } from './dto';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
@UseGuards(AccessTokenGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get('my')
  listMyNotifications(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<NotificationResponseDto[]> {
    return this.notificationsService.listMyNotifications(user.sub);
  }

  @Patch(':id/read')
  markAsRead(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') notificationId: string,
  ): Promise<NotificationResponseDto> {
    return this.notificationsService.markAsRead(user.sub, notificationId);
  }

  @Patch('read-all')
  async markAllAsRead(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<MessageResponseDto> {
    await this.notificationsService.markAllAsRead(user.sub);
    return { message: 'Notifications marked as read' };
  }
}
