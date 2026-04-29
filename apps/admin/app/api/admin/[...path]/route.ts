import { NextRequest, NextResponse } from 'next/server';
import {
  getAdminAccessToken,
  getApiBaseUrl,
  isMobileUserAgent,
} from '../../../../lib/admin-session';

type RouteContext = {
  params: Promise<{
    path: string[];
  }>;
};

export async function GET(
  request: NextRequest,
  context: RouteContext,
): Promise<NextResponse> {
  return proxyAdminRequest(request, context, 'GET');
}

export async function POST(
  request: NextRequest,
  context: RouteContext,
): Promise<NextResponse> {
  return proxyAdminRequest(request, context, 'POST');
}

export async function PATCH(
  request: NextRequest,
  context: RouteContext,
): Promise<NextResponse> {
  return proxyAdminRequest(request, context, 'PATCH');
}

async function proxyAdminRequest(
  request: NextRequest,
  context: RouteContext,
  method: 'GET' | 'POST' | 'PATCH',
): Promise<NextResponse> {
  if (isMobileUserAgent(request.headers.get('user-agent'))) {
    return NextResponse.json(
      { message: 'Admin console is available on desktop only.' },
      { status: 403 },
    );
  }

  const accessToken = await getAdminAccessToken();
  if (!accessToken) {
    return NextResponse.json(
      { message: 'Admin session is missing or expired.' },
      { status: 401 },
    );
  }

  const { path } = await context.params;
  const upstreamUrl = new URL(
    `${getApiBaseUrl()}/admin/${path.join('/')}${request.nextUrl.search}`,
  );
  const contentType = request.headers.get('content-type');
  const body =
    method === 'GET'
      ? undefined
      : contentType?.includes('application/json')
        ? await request.text()
        : undefined;

  const response = await fetch(upstreamUrl, {
    method,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      ...(contentType?.includes('application/json')
        ? { 'Content-Type': 'application/json' }
        : {}),
    },
    body,
    cache: 'no-store',
  });

  const payload = await response.text();
  return new NextResponse(payload, {
    status: response.status,
    headers: {
      'Content-Type': response.headers.get('content-type') ?? 'application/json',
    },
  });
}
