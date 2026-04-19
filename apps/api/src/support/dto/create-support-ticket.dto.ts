import { IsEnum, IsString, MaxLength } from 'class-validator';
import { SupportTicketCategory } from '../entities';

export class CreateSupportTicketDto {
  @IsEnum(SupportTicketCategory)
  category!: SupportTicketCategory;

  @IsString()
  @MaxLength(160)
  subject!: string;

  @IsString()
  @MaxLength(3000)
  description!: string;
}
