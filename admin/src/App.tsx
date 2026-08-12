import { useState, useEffect } from 'react';
import { ToastProvider } from './context/ToastContext';
import { ConfirmationProvider } from './context/ConfirmationContext';
import { AdminAuthProvider, useAdminAuth } from './context/AdminAuthContext';
import { AdminShell } from './components/shell/AdminShell';
import { AdminRoute } from './components/shell/Sidebar';
import { OverviewPage } from './pages/OverviewPage';
import { UserManagementPage } from './pages/UserManagementPage';
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

  // Enforce Dark Mode on mount
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', 'dark');
    document.documentElement.style.colorScheme = 'dark';
  }, []);

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
    users: { title: 'User Registry & Account Management', breadcrumb: 'Users', permission: 'users.view' },
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
        onNavigate={setCurrentRoute}
        title="Access Denied"
        breadcrumbItems={[{ label: 'Access Denied' }]}
      >
        <AccessDeniedPage
          requiredPermission={currentMeta.permission}
          onGoHome={() => setCurrentRoute('overview')}
        />
      </AdminShell>
    );
  }

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Overview', onClick: currentRoute !== 'overview' ? () => setCurrentRoute('overview') : undefined },
  ];

  if (currentRoute !== 'overview') {
    breadcrumbs.push({ label: currentMeta.breadcrumb });
  }

  return (
    <AdminShell
      currentRoute={currentRoute}
      onNavigate={setCurrentRoute}
      title={currentMeta.title}
      breadcrumbItems={breadcrumbs}
    >
      {currentRoute === 'overview' && <OverviewPage onNavigate={setCurrentRoute} />}
      {currentRoute === 'users' && <UserManagementPage />}
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
