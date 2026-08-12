import React, { useState } from 'react';
import { Sidebar, AdminRoute } from './Sidebar';
import { Header } from './Header';
import { BreadcrumbItem } from '../common/Breadcrumbs';
import { useAdminAuth } from '../../context/AdminAuthContext';

interface AdminShellProps {
  currentRoute: AdminRoute;
  onNavigate: (route: AdminRoute) => void;
  title: string;
  breadcrumbItems: BreadcrumbItem[];
  children: React.ReactNode;
}

export const AdminShell: React.FC<AdminShellProps> = ({
  currentRoute,
  onNavigate,
  title,
  breadcrumbItems,
  children,
}) => {
  const { adminUser, logout, hasPermission } = useAdminAuth();
  const [collapsed, setCollapsed] = useState<boolean>(false);
  const [mobileOpen, setMobileOpen] = useState<boolean>(false);

  return (
    <div className={`app-shell ${collapsed ? 'app-shell-collapsed' : ''}`}>
      <Sidebar
        currentRoute={currentRoute}
        onNavigate={onNavigate}
        adminUser={adminUser}
        onLogout={logout}
        collapsed={collapsed}
        onToggleCollapse={() => setCollapsed((v) => !v)}
        mobileOpen={mobileOpen}
        onCloseMobile={() => setMobileOpen(false)}
        hasPermission={hasPermission}
      />

      <div className="main-wrapper">
        <Header
          title={title}
          breadcrumbItems={breadcrumbItems}
          adminUser={adminUser}
          onLogout={logout}
          onToggleMobileSidebar={() => setMobileOpen((v) => !v)}
        />

        <main className="page-content" key={currentRoute}>
          {children}
        </main>
      </div>
    </div>
  );
};
