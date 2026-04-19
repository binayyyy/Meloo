import { registerAs } from '@nestjs/config';

export default registerAs('payments', () => ({
  stripeSecretKey: process.env.STRIPE_SECRET_KEY ?? '',
  stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET ?? '',
  stripeCurrency: (process.env.STRIPE_CURRENCY ?? 'usd').toLowerCase(),
  defaultReturnUrl:
    process.env.PAYMENT_RETURN_URL ?? 'http://127.0.0.1:8081',
}));
