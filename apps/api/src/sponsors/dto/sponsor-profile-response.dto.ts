export class SponsorProfileResponseDto {
  id!: string;
  userId!: string;
  companyName!: string;
  description!: string;
  industries!: string;
  logoUrl!: string | null;
  websiteUrl!: string | null;
  verificationDocumentUrl!: string | null;
  verified!: boolean;
}
