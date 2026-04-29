import { redirect } from 'next/navigation';
import { LoginForm } from './login-form';
import { assertDesktopRequest, getOptionalAdminSession } from '../../lib/admin-session';

export default async function LoginPage() {
  await assertDesktopRequest();
  const session = await getOptionalAdminSession();
  if (session != null) {
    redirect('/');
  }

  return (
    <main className="auth-shell">
      <div className="auth-stage">
        <div className="auth-panel">
          <div className="brand-lockup auth-brand">
            <div className="brand-logo-frame">
              <img className="brand-logo" src="/branding/meloo-logo-v1.png" alt="Meloo" />
            </div>
            <div>
              <p className="brand-title">Meloo platforms</p>
              <p className="brand-subtitle">Operations console</p>
            </div>
          </div>
          <LoginForm />
        </div>
      </div>
    </main>
  );
}
