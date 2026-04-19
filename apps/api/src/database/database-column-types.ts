export const DATE_COLUMN_TYPE =
  process.env.DB_TYPE === 'sqljs' ? 'datetime' : 'timestamptz';

export const ENUM_COLUMN_TYPE =
  process.env.DB_TYPE === 'sqljs' ? 'simple-enum' : 'enum';
