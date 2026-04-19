import { IsInt, IsNumberString, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';

export class PlanningAssistantRequestDto {
  @IsOptional()
  @IsUUID()
  eventId?: string;

  @IsOptional()
  @IsInt()
  @Min(10)
  expectedAttendees?: number;

  @IsOptional()
  @IsNumberString()
  budget?: string;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  planningGoal?: string;
}
