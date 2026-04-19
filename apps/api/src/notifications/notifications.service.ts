import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserSetting } from '../users/entities';
import { Notification, NotificationType } from './entities';
import { NotificationResponseDto } from './dto';

interface CreateNotificationInput {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  resourceType?: string | null;
  resourceId?: string | null;
}

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private readonly notificationsRepository: Repository<Notification>,
    @InjectRepository(UserSetting)
    private readonly userSettingsRepository: Repository<UserSetting>,
  ) {}

  async createNotification(input: CreateNotificationInput): Promise<void> {
    const userSetting = await this.userSettingsRepository.findOne({
      where: { userId: input.userId },
    });

    if (userSetting?.notificationsEnabled === false) {
      return;
    }

    await this.notificationsRepository.save(
      this.notificationsRepository.create({
        userId: input.userId,
        type: input.type,
        title: input.title.trim(),
        body: input.body.trim(),
        resourceType: input.resourceType ?? null,
        resourceId: input.resourceId ?? null,
      }),
    );
  }

  async listMyNotifications(userId: string): Promise<NotificationResponseDto[]> {
    const notifications = await this.notificationsRepository.find({
      where: { userId },
      order: {
        readAt: 'ASC',
        createdAt: 'DESC',
      },
      take: 40,
    });

    return notifications.map((notification) => this.toNotificationResponse(notification));
  }

  async markAsRead(userId: string, notificationId: string): Promise<NotificationResponseDto> {
    const notification = await this.notificationsRepository.findOne({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    if (notification.readAt == null) {
      notification.readAt = new Date();
      await this.notificationsRepository.save(notification);
    }

    return this.toNotificationResponse(notification);
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.notificationsRepository
      .createQueryBuilder()
      .update(Notification)
      .set({ readAt: new Date() })
      .where('user_id = :userId', { userId })
      .andWhere('read_at IS NULL')
      .execute();
  }

  toNotificationResponse(notification: Notification): NotificationResponseDto {
    return {
      id: notification.id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      resourceType: notification.resourceType,
      resourceId: notification.resourceId,
      readAt: notification.readAt,
      createdAt: notification.createdAt,
      unread: notification.readAt == null,
    };
  }
}
