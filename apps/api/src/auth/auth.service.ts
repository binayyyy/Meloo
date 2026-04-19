import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Role } from '../common/enums/role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { hashOpaqueToken, hashPassword, generateOpaqueToken, verifyPassword } from '../common/utils/crypto.util';
import { UsersService } from '../users/users.service';
import {
  EmailVerificationToken,
  PasswordResetToken,
  Session,
  User,
} from '../users/entities';
import {
  AuthResponseDto,
  ForgotPasswordDto,
  ForgotPasswordResponseDto,
  LoginDto,
  MessageResponseDto,
  RefreshSessionDto,
  ResetPasswordDto,
  SignUpDto,
} from './dto';

interface AccessTokenPayload {
  sub: string;
  email: string;
  role: Role;
  sessionId: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly configService: ConfigService,
    private readonly jwtService: JwtService,
    private readonly usersService: UsersService,
    @InjectRepository(Session)
    private readonly sessionsRepository: Repository<Session>,
    @InjectRepository(PasswordResetToken)
    private readonly passwordResetTokensRepository: Repository<PasswordResetToken>,
    @InjectRepository(EmailVerificationToken)
    private readonly emailVerificationTokensRepository: Repository<EmailVerificationToken>,
  ) {}

  async signUp(dto: SignUpDto, deviceInfo?: string): Promise<AuthResponseDto> {
    const existingUser = await this.usersService.findByEmail(dto.email);
    if (existingUser) {
      throw new ConflictException('An account with this email already exists');
    }

    const passwordHash = await hashPassword(dto.password);
    const user = await this.usersService.createUser({
      email: dto.email,
      passwordHash,
      role: dto.role,
      status: UserStatus.PENDING_VERIFICATION,
    });

    await this.createEmailVerificationToken(user.id);
    return this.createAuthResponse(user.id, deviceInfo);
  }

  async login(dto: LoginDto, deviceInfo?: string): Promise<AuthResponseDto> {
    const user = await this.usersService.findByEmail(dto.email);
    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const isValidPassword = await verifyPassword(dto.password, user.passwordHash);
    if (!isValidPassword) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (user.status === UserStatus.SUSPENDED || user.status === UserStatus.DEACTIVATED) {
      throw new UnauthorizedException('This account is not allowed to sign in');
    }

    return this.createAuthResponse(user.id, deviceInfo);
  }

  async refresh(dto: RefreshSessionDto): Promise<AuthResponseDto> {
    const session = await this.sessionsRepository.findOne({
      where: {
        refreshTokenHash: hashOpaqueToken(dto.refreshToken),
      },
      relations: {
        user: true,
      },
    });

    if (!session || session.expiresAt.getTime() <= Date.now()) {
      throw new UnauthorizedException('Refresh token is invalid or expired');
    }

    const rawRefreshToken = generateOpaqueToken();
    session.refreshTokenHash = hashOpaqueToken(rawRefreshToken);
    session.expiresAt = this.createFutureDate(
      this.configService.get<number>('auth.refreshTokenTtlSeconds', 60 * 60 * 24 * 30),
    );
    await this.sessionsRepository.save(session);

    const accessToken = await this.signAccessToken({
      sub: session.user.id,
      email: session.user.email,
      role: session.user.role,
      sessionId: session.id,
    });
    const fullUser = await this.usersService.getUserOrFail(session.user.id);

    return {
      user: this.usersService.toUserResponse(fullUser),
      tokens: {
        accessToken,
        refreshToken: rawRefreshToken,
        accessTokenExpiresIn: this.configService.get<number>(
          'auth.accessTokenTtlSeconds',
          60 * 15,
        ),
        refreshTokenExpiresIn: this.configService.get<number>(
          'auth.refreshTokenTtlSeconds',
          60 * 60 * 24 * 30,
        ),
      },
    };
  }

  async logout(dto: RefreshSessionDto): Promise<MessageResponseDto> {
    await this.sessionsRepository.delete({
      refreshTokenHash: hashOpaqueToken(dto.refreshToken),
    });

    return {
      message: 'Logged out successfully',
    };
  }

  async forgotPassword(
    dto: ForgotPasswordDto,
  ): Promise<ForgotPasswordResponseDto> {
    const user = await this.usersService.findByEmail(dto.email);

    if (!user) {
      return {
        message:
          'If an account exists for that email, a password reset link has been prepared.',
      };
    }

    const rawToken = generateOpaqueToken();
    await this.passwordResetTokensRepository.save(
      this.passwordResetTokensRepository.create({
        userId: user.id,
        tokenHash: hashOpaqueToken(rawToken),
        expiresAt: this.createFutureDate(
          this.configService.get<number>(
            'auth.passwordResetTokenTtlSeconds',
            60 * 30,
          ),
        ),
      }),
    );

    return {
      message:
        'If an account exists for that email, a password reset link has been prepared.',
      debugResetToken:
        this.configService.get<string>('app.nodeEnv') === 'production'
          ? undefined
          : rawToken,
    };
  }

  async resetPassword(dto: ResetPasswordDto): Promise<MessageResponseDto> {
    const resetToken = await this.passwordResetTokensRepository.findOne({
      where: {
        tokenHash: hashOpaqueToken(dto.token),
      },
      relations: {
        user: true,
      },
    });

    if (
      !resetToken ||
      resetToken.consumedAt ||
      resetToken.expiresAt.getTime() <= Date.now()
    ) {
      throw new UnauthorizedException('Reset token is invalid or expired');
    }

    resetToken.consumedAt = new Date();
    await this.passwordResetTokensRepository.save(resetToken);

    await this.usersService.updatePassword(
      resetToken.userId,
      await hashPassword(dto.newPassword),
    );
    await this.sessionsRepository.delete({ userId: resetToken.userId });

    return {
      message: 'Password has been reset successfully',
    };
  }

  private async createAuthResponse(
    userId: string,
    deviceInfo?: string,
  ): Promise<AuthResponseDto> {
    const user = await this.usersService.getUserOrFail(userId);
    const rawRefreshToken = generateOpaqueToken();
    const session = await this.sessionsRepository.save(
      this.sessionsRepository.create({
        userId: user.id,
        refreshTokenHash: hashOpaqueToken(rawRefreshToken),
        deviceInfo: deviceInfo ?? null,
        expiresAt: this.createFutureDate(
          this.configService.get<number>('auth.refreshTokenTtlSeconds', 60 * 60 * 24 * 30),
        ),
      }),
    );

    const accessToken = await this.signAccessToken({
      sub: user.id,
      email: user.email,
      role: user.role,
      sessionId: session.id,
    });

    return {
      user: this.usersService.toUserResponse(user),
      tokens: {
        accessToken,
        refreshToken: rawRefreshToken,
        accessTokenExpiresIn: this.configService.get<number>(
          'auth.accessTokenTtlSeconds',
          60 * 15,
        ),
        refreshTokenExpiresIn: this.configService.get<number>(
          'auth.refreshTokenTtlSeconds',
          60 * 60 * 24 * 30,
        ),
      },
    };
  }

  private async signAccessToken(
    payload: AccessTokenPayload,
  ): Promise<string> {
    return this.jwtService.signAsync(payload, {
      secret: this.configService.getOrThrow<string>('auth.jwtSecret'),
      expiresIn: this.configService.get<number>('auth.accessTokenTtlSeconds', 60 * 15),
      issuer: this.configService.get<string>('auth.jwtIssuer'),
      audience: this.configService.get<string>('auth.jwtAudience'),
    });
  }

  private async createEmailVerificationToken(userId: string): Promise<void> {
    await this.emailVerificationTokensRepository.save(
      this.emailVerificationTokensRepository.create({
        userId,
        tokenHash: hashOpaqueToken(generateOpaqueToken()),
        expiresAt: this.createFutureDate(
          this.configService.get<number>(
            'auth.emailVerificationTokenTtlSeconds',
            60 * 60 * 24,
          ),
        ),
      }),
    );
  }

  private createFutureDate(offsetSeconds: number): Date {
    return new Date(Date.now() + offsetSeconds * 1000);
  }
}

