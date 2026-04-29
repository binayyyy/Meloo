import { NextRequest, NextResponse } from 'next/server';
import {
  getAdminAccessToken,
  getApiBaseUrl,
  isMobileUserAgent,
} from '../../../../lib/admin-session';

type RouteContext = {
  params: Promise<{
    kind: string;
  }>;
};

export async function POST(
  request: NextRequest,
  context: RouteContext,
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

  const { kind } = await context.params;
  const upstreamPath =
    kind === 'image' ? '/uploads/images' : '/uploads/documents';
  const response = await fetch(`${getApiBaseUrl()}${upstreamPath}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
    body: await request.formData(),
  });

  const payload = await response.text();
  return new NextResponse(payload, {
    status: response.status,
    headers: {
      'Content-Type': response.headers.get('content-type') ?? 'application/json',
    },
  });
}
