import { IsEnum, IsOptional } from 'class-validator';
import { EventStatus, EventVisibility } from '../../events/entities';

export class ModerateEventDto {
  @IsOptional()
  @IsEnum(EventStatus)
  status?: EventStatus;

  @IsOptional()
  @IsEnum(EventVisibility)
  visibility?: EventVisibility;
}
