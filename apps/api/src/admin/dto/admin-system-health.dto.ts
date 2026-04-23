class AdminServiceReadinessDto {
  configured!: boolean;
  detail!: string;
}

class AdminAiReadinessDto extends AdminServiceReadinessDto {
  enabled!: boolean;
  provider!: string;
  model!: string;
  baseUrl!: string;
}

class AdminPaymentsReadinessDto extends AdminServiceReadinessDto {
  currency!: string;
  webhookConfigured!: boolean;
}

class AdminRuntimeMemoryDto {
  rssMb!: number;
  heapUsedMb!: number;
  heapTotalMb!: number;
}

class AdminPlatformTotalsDto {
  users!: number;
  activeSessions!: number;
  publishedEvents!: number;
  openSupportTickets!: number;
  openEscalations!: number;
}

export class AdminSystemHealthDto {
  nodeEnv!: string;
  apiPrefix!: string;
  corsOrigin!: string;
  uptimeSeconds!: number;
  databaseConnected!: boolean;
  memory!: AdminRuntimeMemoryDto;
  ai!: AdminAiReadinessDto;
  payments!: AdminPaymentsReadinessDto;
  totals!: AdminPlatformTotalsDto;
}
