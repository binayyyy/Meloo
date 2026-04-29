'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { FormEvent, useState } from 'react';

export function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(
    searchParams.get('reason') === 'session'
      ? 'Your session expired. Sign in again to continue.'
      : null,
  );
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      const response = await fetch('/api/session', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: email.trim(),
          password,
        }),
      });

      const payload = (await response.json()) as { message?: string };
      if (!response.ok) {
        throw new Error(payload.message ?? 'Sign-in failed.');
      }

      router.replace('/');
      router.refresh();
    } catch (submitError) {
      setError(
        submitError instanceof Error ? submitError.message : 'Sign-in failed.',
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form className="auth-card" onSubmit={handleSubmit}>
      <div className="auth-copy">
        <p className="eyebrow">Meloo operations</p>
        <h1>Admin access</h1>
        <p>
          Sign in with your admin account to review operations, trust, support,
          and release health.
        </p>
      </div>

      {error ? (
        <div className="alert-banner">
          <strong>Access blocked</strong>
          <span>{error}</span>
        </div>
      ) : null}

      <label className="field-stack">
        <span>Email</span>
        <input
          className="field-input"
          type="email"
          value={email}
          autoComplete="username"
          placeholder="name@company.com"
          onChange={(event) => setEmail(event.target.value)}
          required
        />
      </label>

      <label className="field-stack">
        <span>Password</span>
        <input
          className="field-input"
          type="password"
          value={password}
          autoComplete="current-password"
          placeholder="Enter your password"
          onChange={(event) => setPassword(event.target.value)}
          required
        />
      </label>

      <button className="button button-primary auth-submit" type="submit">
        {isSubmitting ? 'Signing in...' : 'Sign in'}
      </button>
    </form>
  );
}
