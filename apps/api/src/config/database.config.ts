import { registerAs } from '@nestjs/config';

export default registerAs('database', () => ({
  type: process.env.DB_TYPE ?? 'postgres',
  host: process.env.DB_HOST ?? 'localhost',
  port: Number.parseInt(process.env.DB_PORT ?? '5432', 10),
  username: process.env.DB_USERNAME ?? 'postgres',
  password: process.env.DB_PASSWORD ?? 'postgres',
  database: process.env.DB_NAME ?? 'smart_event',
  sqljsLocation: process.env.DB_SQLJS_LOCATION ?? '.tooling/demo/smart-event-local.sqlite',
  synchronize:
    process.env.DB_SYNCHRONIZE === 'true' ||
    (process.env.DB_SYNCHRONIZE !== 'false' &&
      (process.env.NODE_ENV ?? 'development') !== 'production'),
  autoLoadEntities: true,
}));
