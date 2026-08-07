import { Navigate } from 'react-router';
import { useAuth } from './AuthContext';
import type { UserRole } from '../data/types';

interface RoleGuardProps {
  allow: UserRole[];
  children: React.ReactNode;
}

/**
 * Wraps a route tree and redirects to /unauthorized if the current user's role
 * is not in the `allow` list. Must be nested inside <RequireAuth>.
 */
export function RoleGuard({ allow, children }: RoleGuardProps) {
  const { role, loading } = useAuth();

  if (loading) return null;

  if (!role || !allow.includes(role)) {
    return <Navigate to="/unauthorized" replace />;
  }

  return <>{children}</>;
}
