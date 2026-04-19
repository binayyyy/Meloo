import {
  IsDateString,
  IsInt,
  IsNumberString,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateTicketTypeDto {
  @IsString()
  @MaxLength(120)
  name!: string;

  @IsNumberString()
  price!: string;

  @IsInt()
  @Min(1)
  quantity!: number;

  @IsDateString()
  saleStartAt!: string;

  @IsDateString()
  saleEndAt!: string;
}

