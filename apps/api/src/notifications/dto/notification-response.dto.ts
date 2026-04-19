import { NotificationType } from '../entities';

export class NotificationResponseDto {
  id!: string;
  type!: NotificationType;
  title!: string;
  body!: string;
  resourceType!: string | null;
  resourceId!: string | null;
  readAt!: Date | null;
  createdAt!: Date;
  unread!: boolean;
}
