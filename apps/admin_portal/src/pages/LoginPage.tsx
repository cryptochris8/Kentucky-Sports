import { useState, type FormEvent } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { Button, Input, FormField } from '../components/ui';

export function LoginPage() {
  const { signIn, devSignIn } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const from = (location.state as { from?: { pathname: string } })?.from?.pathname ?? '/';

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await signIn(email, password);
      navigate(from, { replace: true });
    } catch (err: unknown) {
      const e = err as { message?: string };
      setError(e.message ?? 'Sign-in failed. Check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  const handleDevSignIn = async () => {
    setError('');
    setLoading(true);
    try {
      await devSignIn();
      navigate(from, { replace: true });
    } catch (err: unknown) {
      const e = err as { message?: string };
      setError(e.message ?? 'Dev sign-in failed.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#1E3A5F] p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-sm p-8">
        {/* Brand */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-[#1E5AA8] mb-3">
            <span className="text-[#C8B273] font-bold text-xl">BG</span>
          </div>
          <h1 className="text-2xl font-bold text-gray-900">Admin Portal</h1>
          <p className="text-sm text-gray-500 mt-1">Bluegrass Gameday</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <FormField label="Email" htmlFor="email" required>
            <Input
              id="email"
              type="email"
              autoComplete="email"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </FormField>
          <FormField label="Password" htmlFor="password" required>
            <Input
              id="password"
              type="password"
              autoComplete="current-password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </FormField>

          {error && (
            <p className="text-xs text-red-600 bg-red-50 rounded p-2 border border-red-200">
              {error}
            </p>
          )}

          <Button type="submit" disabled={loading} className="w-full justify-center">
            {loading ? 'Signing in…' : 'Sign in'}
          </Button>
        </form>

        {/* Dev helper — only shown in emulator mode */}
        {import.meta.env.VITE_USE_EMULATOR !== 'false' && (
          <div className="mt-6 pt-6 border-t border-gray-100">
            <p className="text-xs text-gray-400 mb-3 text-center">
              Local dev (emulator) only
            </p>
            <Button
              variant="secondary"
              onClick={handleDevSignIn}
              disabled={loading}
              className="w-full justify-center"
            >
              Dev sign-in (admin@bluegrassgameday.dev)
            </Button>
            <p className="text-[11px] text-gray-400 mt-2 text-center leading-snug">
              Creates the demo admin account in the Auth emulator and signs in.
              Role is read from the seeded{' '}
              <code className="bg-gray-100 px-0.5 rounded">users/&#123;uid&#125;</code> doc.
              In production, roles are set by a Cloud Function.
            </p>
          </div>
        )}

        <p className="text-[11px] text-gray-400 text-center mt-6">
          Independent fan app — not affiliated with UK Athletics.
        </p>
      </div>
    </div>
  );
}
