import { EventStatus, EventVisibility } from '../entities';
import { EventCategoryResponseDto } from './event-category-response.dto';

export class EventResponseDto {
  id!: string;
  organizerId!: string;
  title!: string;
  description!: string;
  category!: EventCategoryResponseDto;
  venue!: string;
  city!: string;
  latitude!: number | null;
  longitude!: number | null;
  vendorMatchRadiusKm!: number | null;
  startAt!: Date;
  endAt!: Date;
  status!: EventStatus;
  visibility!: EventVisibility;
  coverImageUrl!: string | null;
  createdAt!: Date;
  updatedAt!: Date;
}
