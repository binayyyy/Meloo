import { NextRequest, NextResponse } from 'next/server';
import { getApiBaseUrl } from '../../../../lib/admin-session';

type RouteContext = {
  params: Promise<{
    path: string[];
  }>;
};

export async function GET(
  request: NextRequest,
  context: RouteContext,
): Promise<NextResponse> {
  const { path } = await context.params;
  const upstreamUrl = new URL(
    `${getApiBaseUrl()}/${path.join('/')}${request.nextUrl.search}`,
  );

  const response = await fetch(upstreamUrl, {
    cache: 'no-store',
  });
  const body = await response.text();

  return new NextResponse(body, {
    status: response.status,
    headers: {
      'Content-Type': response.headers.get('content-type') ?? 'application/json',
    },
  });
}
