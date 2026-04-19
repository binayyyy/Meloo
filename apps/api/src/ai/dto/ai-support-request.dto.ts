import { IsOptional, IsString, MaxLength } from 'class-validator';

export class AiSupportRequestDto {
  @IsOptional()
  @IsString()
  @MaxLength(50)
  category?: string;

  @IsString()
  @MaxLength(3000)
  message!: string;
}
