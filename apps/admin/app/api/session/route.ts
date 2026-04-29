import { NextRequest, NextResponse } from 'next/server';
import {
  type AdminAuthResponse,
  applyAdminSession,
  clearAdminSession,
  fetchCurrentAdmin,
  getApiBaseUrl,
  getOptionalAdminSession,
  isMobileUserAgent,
  readAdminRefreshToken,
} from '../../../lib/admin-session';

type AuthResponse = {
  user: {
    role: string;
  };
  tokens: {
    accessToken: string;
    refreshToken: string;
    accessTokenExpiresIn: number;
    refreshTokenExpiresIn: number;
  };
};

export async function GET(): Promise<NextResponse> {
  const session = await getOptionalAdminSession();
  if (session == null) {
    return NextResponse.json({ user: null }, { status: 401 });
  }

  return NextResponse.json({ user: session });
}

export async function POST(request: NextRequest): Promise<NextResponse> {
  if (isMobileUserAgent(request.headers.get('user-agent'))) {
    return NextResponse.json(
      { message: 'Admin console is available on desktop only.' },
      { status: 403 },
    );
  }

  const body = (await request.json()) as {
    email?: string;
    password?: string;
  };

  const response = await fetch(`${getApiBaseUrl()}/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': request.headers.get('user-agent') ?? 'meloo-admin',
    },
    body: JSON.stringify({
      email: body.email?.trim() ?? '',
      password: body.password ?? '',
    }),
  });

  const payload = (await response.json()) as
    | { message?: string | string[] }
    | AuthResponse;

  if (!response.ok) {
    return NextResponse.json(
      {
        message:
          typeof payload === 'object' &&
          payload != null &&
          'message' in payload &&
          payload.message != null
            ? Array.isArray(payload.message)
              ? payload.message.join(', ')
              : payload.message
            : 'Sign-in failed.',
      },
      { status: response.status },
    );
  }

  const auth = payload as AuthResponse;
  if (auth.user.role !== 'admin') {
    return NextResponse.json(
      { message: 'This account does not have admin access.' },
      { status: 403 },
    );
  }

  const viewer = await fetchCurrentAdmin(auth.tokens.accessToken);
  if (viewer == null || viewer.role !== 'admin') {
    return NextResponse.json(
      { message: 'Admin session could not be verified.' },
      { status: 401 },
    );
  }

  return applyAdminSession(NextResponse.json({ user: viewer }), {
    ...(auth as AuthResponse),
    user: viewer,
  } satisfies AdminAuthResponse);
}

export async function DELETE(): Promise<NextResponse> {
  const refreshToken = await readAdminRefreshToken();

  if (refreshToken != null) {
    try {
      await fetch(`${getApiBaseUrl()}/auth/logout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ refreshToken }),
      });
    } catch {
    }
  }

  return clearAdminSession(NextResponse.json({ ok: true }));
}
