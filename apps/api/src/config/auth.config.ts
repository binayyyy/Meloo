import { registerAs } from '@nestjs/config';

function parseSeconds(value: string | undefined, fallback: number): number {
  const parsed = Number.parseInt(value ?? '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

export default registerAs('auth', () => ({
  jwtSecret:
    process.env.JWT_SECRET ?? 'replace-me-with-a-long-random-jwt-secret',
  accessTokenTtlSeconds: parseSeconds(
    process.env.ACCESS_TOKEN_TTL_SECONDS,
    60 * 15,
  ),
  refreshTokenTtlSeconds: parseSeconds(
    process.env.REFRESH_TOKEN_TTL_SECONDS,
    60 * 60 * 24 * 30,
  ),
  passwordResetTokenTtlSeconds: parseSeconds(
    process.env.PASSWORD_RESET_TOKEN_TTL_SECONDS,
    60 * 30,
  ),
  emailVerificationTokenTtlSeconds: parseSeconds(
    process.env.EMAIL_VERIFICATION_TOKEN_TTL_SECONDS,
    60 * 60 * 24,
  ),
  jwtIssuer: process.env.JWT_ISSUER ?? 'smart-event-api',
  jwtAudience: process.env.JWT_AUDIENCE ?? 'smart-event-clients',
}));

