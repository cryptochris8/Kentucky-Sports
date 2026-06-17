import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './auth/AuthContext';
import { RequireAuth } from './auth/RequireAuth';
import { RoleGuard } from './auth/RoleGuard';
import { AppShell } from './components/AppShell';
import { LoginPage } from './pages/LoginPage';
import { UnauthorizedPage } from './pages/UnauthorizedPage';
import { DashboardPage } from './pages/DashboardPage';
import { GamesPage } from './pages/GamesPage';
import { PredictionsPage } from './pages/PredictionsPage';
import { NewsPage } from './pages/NewsPage';
import { VaultLegendsPage } from './pages/VaultLegendsPage';
import { VaultLegendEditorPage } from './pages/VaultLegendEditorPage';
import { ModerationPage } from './pages/ModerationPage';
import { SyncHealthPage } from './pages/SyncHealthPage';

// All authenticated routes require at minimum the 'editor' or 'admin' role.
// Moderation requires 'moderator' or above.
const EDITOR_ROLES = ['admin', 'editor'] as const;
const MOD_ROLES = ['admin', 'editor', 'moderator'] as const;

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
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
            <Route
              path="sync"
              element={
                <RoleGuard allow={[...EDITOR_ROLES]}>
                  <SyncHealthPage />
                </RoleGuard>
              }
            />
          </Route>

          {/* Catch-all */}
          <Route path="*" element={<UnauthorizedPage />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
