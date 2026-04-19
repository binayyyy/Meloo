import { IsBoolean, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateVendorRequestDto {
  @IsUUID()
  eventId!: string;

  @IsString()
  @MaxLength(2000)
  message!: string;

  @IsString()
  proposedBudget!: string;

  @IsOptional()
  @IsBoolean()
  directBookingPreferred?: boolean;
}
