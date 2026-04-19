import { IsString, MaxLength } from 'class-validator';

export class CreateSponsorshipInterestDto {
  @IsString()
  @MaxLength(2000)
  message!: string;
}

