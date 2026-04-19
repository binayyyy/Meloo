import { IsEnum } from 'class-validator';
import { VendorRequestStatus } from '../entities';

export class RespondVendorRequestDto {
  @IsEnum(VendorRequestStatus)
  status!: VendorRequestStatus;
}
