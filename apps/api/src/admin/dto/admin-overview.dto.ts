export class AdminOverviewDto {
  totalUserCount!: number;
  activeUserCount!: number;
  suspendedUserCount!: number;
  activeSessionCount!: number;
  totalEventCount!: number;
  publishedEventCount!: number;
  draftEventCount!: number;
  cancelledEventCount!: number;
  pendingVendorVerificationCount!: number;
  pendingSponsorVerificationCount!: number;
  openSupportTicketCount!: number;
  openEscalationCount!: number;
}
