import { cookies, headers } from 'next/headers';
import { redirect } from 'next/navigation';
import { NextResponse } from 'next/server';

export const ADMIN_ACCESS_COOKIE = 'meloo_admin_access';
export const ADMIN_REFRESH_COOKIE = 'meloo_admin_refresh';

const MOBILE_USER_AGENT_PATTERN =
  /android|iphone|ipad|ipod|iemobile|opera mini|mobile/i;

export type AdminViewer = {
  id: string;
  email: string;
  role: string;
  status: string;
  profile: {
    fullName: string | null;
    avatarUrl?: string | null;
  } | null;
};

type AuthTokens = {
  accessToken: string;
  refreshToken: string;
  accessTokenExpiresIn: number;
  refreshTokenExpiresIn: number;
};

export type AdminAuthResponse = {
  user: AdminViewer;
  tokens: AuthTokens;
};

export function getApiBaseUrl(): string {
  return process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000/api';
}

export function isMobileUserAgent(userAgent: string | null | undefined): boolean {
  return userAgent != null && MOBILE_USER_AGENT_PATTERN.test(userAgent);
}

export async function requireAdminSession(): Promise<AdminViewer> {
  await assertDesktopRequest();
  const accessToken = await getAdminAccessToken();

  if (!accessToken) {
    redirect('/login');
  }

  const user = await fetchCurrentAdmin(accessToken);
  if (user == null || user.role !== 'admin') {
    redirect('/login?reason=session');
  }

  return user;
}

export async function getOptionalAdminSession(): Promise<AdminViewer | null> {
  if (await isMobileRequest()) {
    return null;
  }

  const accessToken = await getAdminAccessToken();
  if (!accessToken) {
    return null;
  }

  const user = await fetchCurrentAdmin(accessToken);
  return user?.role === 'admin' ? user : null;
}

export async function getAdminAccessToken(): Promise<string | null> {
  const cookieStore = await cookies();
  return cookieStore.get(ADMIN_ACCESS_COOKIE)?.value ?? null;
}

export async function assertDesktopRequest(): Promise<void> {
  if (await isMobileRequest()) {
    redirect('/blocked?reason=device');
  }
}

export async function isMobileRequest(): Promise<boolean> {
  const headerStore = await headers();
  return isMobileUserAgent(headerStore.get('user-agent'));
}

export async function fetchCurrentAdmin(
  accessToken: string,
): Promise<AdminViewer | null> {
  const response = await fetch(`${getApiBaseUrl()}/users/me`, {
    cache: 'no-store',
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    return null;
  }

  return (await response.json()) as AdminViewer;
}

export function applyAdminSession(
  response: NextResponse,
  auth: AdminAuthResponse,
): NextResponse {
  const secure = process.env.NODE_ENV === 'production';

  response.cookies.set({
    name: ADMIN_ACCESS_COOKIE,
    value: auth.tokens.accessToken,
    httpOnly: true,
    sameSite: 'lax',
    secure,
    path: '/',
    maxAge: auth.tokens.accessTokenExpiresIn,
  });
  response.cookies.set({
    name: ADMIN_REFRESH_COOKIE,
    value: auth.tokens.refreshToken,
    httpOnly: true,
    sameSite: 'lax',
    secure,
    path: '/',
    maxAge: auth.tokens.refreshTokenExpiresIn,
  });

  return response;
}

export function clearAdminSession(response: NextResponse): NextResponse {
  response.cookies.set({
    name: ADMIN_ACCESS_COOKIE,
    value: '',
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: 0,
  });
  response.cookies.set({
    name: ADMIN_REFRESH_COOKIE,
    value: '',
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: 0,
  });

  return response;
}

export async function readAdminRefreshToken(): Promise<string | null> {
  const cookieStore = await cookies();
  return cookieStore.get(ADMIN_REFRESH_COOKIE)?.value ?? null;
}
