import path from 'path';
import type { NextConfig } from 'next';

const isProduction = process.env.NODE_ENV === 'production';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  outputFileTracingRoot: path.join(__dirname, '../..'),
  distDir: isProduction ? '.next' : '.next-dev',
  output: isProduction ? 'standalone' : undefined,
};

export default nextConfig;
