import { IsString, Matches, MaxLength } from 'class-validator';

export class CreateEventCategoryDto {
  @IsString()
  @MaxLength(80)
  name!: string;

  @IsString()
  @MaxLength(80)
  @Matches(/^[a-z0-9-]+$/, {
    message: 'slug must contain lowercase letters, numbers, or hyphens only',
  })
  slug!: string;
}
