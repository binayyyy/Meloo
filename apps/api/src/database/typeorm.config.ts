import { ConfigType } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import databaseConfig from '../config/database.config';

export function createTypeOrmOptions(
  dbConfig: ConfigType<typeof databaseConfig>,
): TypeOrmModuleOptions {
  if (dbConfig.type === 'sqljs') {
    return {
      type: 'sqljs',
      autoSave: true,
      location: dbConfig.sqljsLocation,
      synchronize: dbConfig.synchronize,
      autoLoadEntities: dbConfig.autoLoadEntities,
    };
  }

  return {
    type: 'postgres',
    host: dbConfig.host,
    port: dbConfig.port,
    username: dbConfig.username,
    password: dbConfig.password,
    database: dbConfig.database,
    synchronize: dbConfig.synchronize,
    autoLoadEntities: dbConfig.autoLoadEntities,
  };
}
