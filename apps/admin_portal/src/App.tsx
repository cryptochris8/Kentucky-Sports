import { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router';
import { AuthProvider } from './auth/AuthContext';
import { RequireAuth } from './auth/RequireAuth';
import { RoleGuard } from './auth/RoleGuard';
import { ADMIN_ROLES, EDITOR_ROLES, MOD_ROLES } from './auth/roles';
import { AppShell } from './components/AppShell';
import { LoadingState } from './components/ui';

// Route-level code-splitting: each page becomes its own chunk instead of one
// monolithic bundle. Pages use named exports, so map them to lazy defaults.
const LoginPage = lazy(() => import('./pages/LoginPage').then((m) => ({ default: m.LoginPage })));
const UnauthorizedPage = lazy(() => import('./pages/UnauthorizedPage').then((m) => ({ default: m.UnauthorizedPage })));
const DashboardPage = lazy(() => import('./pages/DashboardPage').then((m) => ({ default: m.DashboardPage })));
const GamesPage = lazy(() => import('./pages/GamesPage').then((m) => ({ default: m.GamesPage })));
const PredictionsPage = lazy(() => import('./pages/PredictionsPage').then((m) => ({ default: m.PredictionsPage })));
const NewsPage = lazy(() => import('./pages/NewsPage').then((m) => ({ default: m.NewsPage })));
const VaultLegendsPage = lazy(() => import('./pages/VaultLegendsPage').then((m) => ({ default: m.VaultLegendsPage })));
const VaultLegendEditorPage = lazy(() => import('./pages/VaultLegendEditorPage').then((m) => ({ default: m.VaultLegendEditorPage })));
const ModerationPage = lazy(() => import('./pages/ModerationPage').then((m) => ({ default: m.ModerationPage })));
const SyncHealthPage = lazy(() => import('./pages/SyncHealthPage').then((m) => ({ default: m.SyncHealthPage })));

// All authenticated routes require at minimum the 'editor' or 'admin' role.
// Moderation requires 'moderator' or above. (Role lists live in auth/roles.ts.)

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Suspense fallback={<LoadingState label="Loading…" />}>
          <Routes>
            {/* Public */}
            <Route path="/login" element={<LoginPage />} />
            <Route path="/unauthorized" element={<UnauthorizedPage />} />

            {/* Protected — requires auth + role */}
            <Route
              element={
                <RequireAuth>
                  <RoleGuard allow={[...MOD_ROLES]}>
                    <AppShell />
                  </RoleGuard>
                </RequireAuth>
              }
            >
              <Route index element={<DashboardPage />} />
              <Route
                path="games"
                element={
                  <RoleGuard allow={[...EDITOR_ROLES]}>
                    <GamesPage />
                  </RoleGuard>
                }
              />
              <Route
                path="predictions"
                element={
                  <RoleGuard allow={[...EDITOR_ROLES]}>
                    <PredictionsPage />
                  </RoleGuard>
                }
              />
              <Route
                path="news"
                element={
                  <RoleGuard allow={[...EDITOR_ROLES]}>
                    <NewsPage />
                  </RoleGuard>
                }
              />
              <Route
                path="vault"
                element={
                  <RoleGuard allow={[...EDITOR_ROLES]}>
                    <VaultLegendsPage />
                  </RoleGuard>
                }
              />
              <Route
                path="vault/:id"
                element={
                  <RoleGuard allow={[...EDITOR_ROLES]}>
                    <VaultLegendEditorPage />
                  </RoleGuard>
                }
              />
              <Route path="moderation" element={<ModerationPage />} />
              {/* Admin-only: firestore.rules restricts sync_runs reads to admins,
                  so routing an editor here would only render a dead error page. */}
              <Route
                path="sync"
                element={
                  <RoleGuard allow={[...ADMIN_ROLES]}>
                    <SyncHealthPage />
                  </RoleGuard>
                }
              />
            </Route>

            {/* Catch-all */}
            <Route path="*" element={<UnauthorizedPage />} />
          </Routes>
        </Suspense>
      </AuthProvider>
    </BrowserRouter>
  );
}
