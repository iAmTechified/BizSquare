import { useState, useEffect } from 'react';
import { ToastProvider } from './context/ToastContext';
import { ConfirmationProvider } from './context/ConfirmationContext';
import { AdminAuthProvider, useAdminAuth } from './context/AdminAuthContext';
import { AdminShell } from './components/shell/AdminShell';
import { AdminRoute } from './components/shell/Sidebar';
import { OverviewPage } from './pages/OverviewPage';
import { UserManagementPage } from './pages/UserManagementPage';
import { UserDetailPage } from './pages/UserDetailPage';
import { SetupCodesPage } from './pages/SetupCodesPage';
import { NotificationsPage } from './pages/NotificationsPage';
import { SystemHealthPage } from './pages/SystemHealthPage';
import { AuditLogPage } from './pages/AuditLogPage';
import { LoginPage } from './pages/LoginPage';
import { AccessDeniedPage } from './pages/AccessDeniedPage';
import { GlobalLoadingState } from './components/common/GlobalLoadingState';
import { GlobalErrorState } from './components/common/GlobalErrorState';
import { BreadcrumbItem } from './components/common/Breadcrumbs';
import './index.css';

function MainAppContent() {
  const { status, isLoading, verifySession, hasPermission } = useAdminAuth();
  const [currentRoute, setCurrentRoute] = useState<AdminRoute>('overview');
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);

  // Enforce Dark Mode on mount
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', 'dark');
    document.documentElement.style.colorScheme = 'dark';
  }, []);

  const handleNavigate = (route: AdminRoute) => {
    setSelectedUserId(null);
    setCurrentRoute(route);
  };

  // Show full page loading skeleton during initialization
  if (status === 'INITIALIZING' || (isLoading && status !== 'AUTHENTICATED')) {
    return <GlobalLoadingState type="page" message="Verifying administrative session & credentials…" />;
  }

  // Handle unauthenticated state
  if (status === 'UNAUTHENTICATED') {
    return <LoginPage />;
  }

  // Handle authorization access denied state
  if (status === 'ACCESS_DENIED') {
    return <AccessDeniedPage />;
  }

  // Handle network / server connectivity error state
  if (status === 'NETWORK_ERROR') {
    return (
      <GlobalErrorState
        type="network"
        title="Backend Unreachable"
        message="Could not connect to BizSquare backend server to verify administrative session."
        onRetry={verifySession}
      />
    );
  }

  // Route metadata mapping
  const routeMeta: Record<AdminRoute, { title: string; breadcrumb: string; permission?: string }> = {
    overview: { title: 'Admin Overview', breadcrumb: 'Overview' },
    users: { title: selectedUserId ? 'User Profile Inspection' : 'Users', breadcrumb: 'Users', permission: 'users.view' },
    setup_codes: { title: 'Setup Codes', breadcrumb: 'Setup Codes', permission: 'system.view' },
    notifications: { title: 'Notification Composer & Broadcasts', breadcrumb: 'Notifications' },
    system: { title: 'System Health & Monitoring', breadcrumb: 'System Health', permission: 'system.view' },
    audit: { title: 'Administrative Audit Log', breadcrumb: 'Audit Log', permission: 'audit.view' },
  };

  const currentMeta = routeMeta[currentRoute] || routeMeta.overview;

  // Permission check for protected sub-routes
  if (currentMeta.permission && !hasPermission(currentMeta.permission)) {
    return (
      <AdminShell
        currentRoute={currentRoute}
        onNavigate={handleNavigate}
        title="Access Denied"
        breadcrumbItems={[{ label: 'Access Denied' }]}
      >
        <AccessDeniedPage
          requiredPermission={currentMeta.permission}
          onGoHome={() => handleNavigate('overview')}
        />
      </AdminShell>
    );
  }

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Overview', onClick: currentRoute !== 'overview' || selectedUserId ? () => handleNavigate('overview') : undefined },
  ];

  if (currentRoute !== 'overview') {
    if (selectedUserId) {
      breadcrumbs.push({ label: 'Users', onClick: () => setSelectedUserId(null) });
      breadcrumbs.push({ label: 'User Detail' });
    } else {
      breadcrumbs.push({ label: currentMeta.breadcrumb });
    }
  }

  return (
    <AdminShell
      currentRoute={currentRoute}
      onNavigate={handleNavigate}
      title={currentMeta.title}
      breadcrumbItems={breadcrumbs}
    >
      {currentRoute === 'overview' && <OverviewPage onNavigate={handleNavigate} />}
      {currentRoute === 'users' && !selectedUserId && (
        <UserManagementPage onSelectUser={(id) => setSelectedUserId(id)} />
      )}
      {currentRoute === 'users' && selectedUserId && (
        <UserDetailPage
          userId={selectedUserId}
          onNavigate={handleNavigate}
          onBack={() => setSelectedUserId(null)}
        />
      )}
      {currentRoute === 'setup_codes' && <SetupCodesPage />}
      {currentRoute === 'notifications' && <NotificationsPage />}
      {currentRoute === 'system' && <SystemHealthPage />}
      {currentRoute === 'audit' && <AuditLogPage />}
    </AdminShell>
  );
}

function App() {
  return (
    <ToastProvider>
      <ConfirmationProvider>
        <AdminAuthProvider>
          <MainAppContent />
        </AdminAuthProvider>
      </ConfirmationProvider>
    </ToastProvider>
  );
}

export default App;
