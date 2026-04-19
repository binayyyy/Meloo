import { VendorRequestStatus } from '../entities';

export class VendorRequestEventSummaryDto {
  id!: string;
  title!: string;
  city!: string;
  venue!: string;
  startAt!: Date;
  endAt!: Date;
}

export class VendorRequestVendorSummaryDto {
  id!: string;
  userId!: string;
  businessName!: string;
  category!: string;
  serviceArea!: string;
  verified!: boolean;
}

export class VendorRequestResponseDto {
  id!: string;
  event!: VendorRequestEventSummaryDto;
  organizerId!: string;
  vendor!: VendorRequestVendorSummaryDto;
  status!: VendorRequestStatus;
  message!: string;
  proposedBudget!: string;
  createdAt!: Date;
  updatedAt!: Date;
}
