import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DeepPartial, Repository } from 'typeorm';
import { UserStatus } from '../common/enums/user-status.enum';
import { Role } from '../common/enums/role.enum';
import { UpdateMeDto, UserResponseDto } from './dto';
import { User, UserProfile, UserSetting } from './entities';

interface CreateUserParams {
  email: string;
  passwordHash: string;
  role: Role;
  status?: UserStatus;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(UserProfile)
    private readonly userProfilesRepository: Repository<UserProfile>,
    @InjectRepository(UserSetting)
    private readonly userSettingsRepository: Repository<UserSetting>,
  ) {}

  findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: {
        email: email.toLowerCase().trim(),
      },
    });
  }

  async createUser(params: CreateUserParams): Promise<User> {
    const user = await this.usersRepository.save(
      this.usersRepository.create({
        email: params.email.toLowerCase().trim(),
        passwordHash: params.passwordHash,
        role: params.role,
        status: params.status ?? UserStatus.PENDING_VERIFICATION,
      }),
    );

    await this.userProfilesRepository.save(
      this.userProfilesRepository.create({
        userId: user.id,
      }),
    );

    await this.userSettingsRepository.save(
      this.userSettingsRepository.create({
        userId: user.id,
      }),
    );

    return this.getUserOrFail(user.id);
  }

  async getUserOrFail(userId: string): Promise<User> {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      relations: {
        profile: true,
        setting: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async updateMe(userId: string, dto: UpdateMeDto): Promise<UserResponseDto> {
    if (dto.profile) {
      await this.upsertProfile(userId, dto.profile);
    }

    if (dto.settings) {
      await this.upsertSettings(userId, dto.settings);
    }

    return this.toUserResponse(await this.getUserOrFail(userId));
  }

  async updatePassword(userId: string, passwordHash: string): Promise<void> {
    await this.usersRepository.update(userId, { passwordHash });
  }

  toUserResponse(user: User): UserResponseDto {
    return {
      id: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
      profile: user.profile
        ? {
            fullName: user.profile.fullName,
            avatarUrl: user.profile.avatarUrl,
            phone: user.profile.phone,
            bio: user.profile.bio,
          }
        : null,
      settings: user.setting
        ? {
            notificationsEnabled: user.setting.notificationsEnabled,
            marketingEnabled: user.setting.marketingEnabled,
            privacyLevel: user.setting.privacyLevel,
            aiAssistEnabled: user.setting.aiAssistEnabled,
          }
        : null,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  private async upsertProfile(
    userId: string,
    update: DeepPartial<UserProfile>,
  ): Promise<void> {
    const existingProfile = await this.userProfilesRepository.findOne({
      where: { userId },
    });

    if (!existingProfile) {
      await this.userProfilesRepository.save(
        this.userProfilesRepository.create({
          userId,
          ...update,
        }),
      );
      return;
    }

    await this.userProfilesRepository.save({
      ...existingProfile,
      ...update,
    });
  }

  private async upsertSettings(
    userId: string,
    update: DeepPartial<UserSetting>,
  ): Promise<void> {
    const existingSettings = await this.userSettingsRepository.findOne({
      where: { userId },
    });

    if (!existingSettings) {
      await this.userSettingsRepository.save(
        this.userSettingsRepository.create({
          userId,
          ...update,
        }),
      );
      return;
    }

    await this.userSettingsRepository.save({
      ...existingSettings,
      ...update,
    });
  }
}

