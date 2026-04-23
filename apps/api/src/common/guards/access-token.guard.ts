import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { MoreThan, Repository } from 'typeorm';
import { UserStatus } from '../enums/user-status.enum';
import { AuthenticatedUser } from '../interfaces/authenticated-user.interface';
import { Session } from '../../users/entities';

@Injectable()
export class AccessTokenGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @InjectRepository(Session)
    private readonly sessionsRepository: Repository<Session>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing bearer token');
    }

    const token = authHeader.slice('Bearer '.length).trim();
    if (!token) {
      throw new UnauthorizedException('Missing bearer token');
    }

    try {
      const payload = await this.jwtService.verifyAsync<AuthenticatedUser>(token, {
        secret: this.configService.getOrThrow<string>('auth.jwtSecret'),
        issuer: this.configService.get<string>('auth.jwtIssuer'),
        audience: this.configService.get<string>('auth.jwtAudience'),
      });

      const session = await this.sessionsRepository.findOne({
        where: {
          id: payload.sessionId,
          userId: payload.sub,
          expiresAt: MoreThan(new Date()),
        },
        relations: {
          user: true,
        },
      });

      if (!session) {
        throw new UnauthorizedException('Session is no longer active');
      }

      if (
        session.user.status === UserStatus.SUSPENDED ||
        session.user.status === UserStatus.DEACTIVATED
      ) {
        throw new UnauthorizedException('This account is not allowed to sign in');
      }

      request.user = payload;
      return true;
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }

      throw new UnauthorizedException('Invalid or expired access token');
    }
  }
}
