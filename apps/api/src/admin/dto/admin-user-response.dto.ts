export class AdminUserResponseDto {
  id!: string;
  email!: string;
  role!: string;
  status!: string;
  fullName!: string | null;
  avatarUrl!: string | null;
  phone!: string | null;
  createdAt!: string;
  updatedAt!: string;
  activeSessionCount!: number;
  lastSessionAt!: string | null;
  vendorProfileId!: string | null;
  sponsorProfileId!: string | null;
  vendorVerified!: boolean;
  sponsorVerified!: boolean;
}
