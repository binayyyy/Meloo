import { UserResponseDto } from '../../users/dto';

export class AuthTokensDto {
  accessToken!: string;
  refreshToken!: string;
  accessTokenExpiresIn!: number;
  refreshTokenExpiresIn!: number;
}

export class AuthResponseDto {
  user!: UserResponseDto;
  tokens!: AuthTokensDto;
}

