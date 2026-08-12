import React from 'react';
import { Hugeicon, HugeiconName } from '../common/Hugeicon';
import { AdminUser } from '../../api/adminAuthApi';

export type AdminRoute = 'overview' | 'users' | 'notifications' | 'system' | 'audit';

export interface NavItemConfig {
  id: string;
  label: string;
  icon: HugeiconName;
  route?: AdminRoute;
  enabled: boolean;
  requiredPermission?: string;
  badge?: string;
}

export interface NavGroupConfig {
  label: string;
  items: NavItemConfig[];
}

export const NAVIGATION_GROUPS: NavGroupConfig[] = [
  {
    label: 'Overview',
    items: [
      { id: 'overview', label: 'Overview', icon: 'overview', route: 'overview', enabled: true },
    ],
  },
  {
    label: 'OPERATIONS',
    items: [
      { id: 'users', label: 'Users', icon: 'users', route: 'users', enabled: true, requiredPermission: 'users.view' },
      { id: 'contacts', label: 'Contacts & Gain', icon: 'contacts', enabled: false, badge: 'MVP 1.0' },
      { id: 'spotlight', label: 'Spotlight', icon: 'spotlight', enabled: false, badge: 'MVP 1.0' },
    ],
  },
  {
    label: 'CONTENT',
    items: [
      { id: 'interests', label: 'Interests', icon: 'interests', enabled: false, badge: 'MVP 1.0' },
      { id: 'content', label: 'Content Bank', icon: 'content', enabled: false, badge: 'MVP 1.0' },
    ],
  },
  {
    label: 'COMMUNICATION',
    items: [
      { id: 'notifications', label: 'Notifications', icon: 'notifications', route: 'notifications', enabled: true },
    ],
  },
  {
    label: 'INSIGHTS',
    items: [
      { id: 'analytics', label: 'Analytics', icon: 'analytics', enabled: false, badge: 'MVP 1.0' },
    ],
  },
  {
    label: 'SYSTEM',
    items: [
      { id: 'system', label: 'System Health', icon: 'system', route: 'system', enabled: true, requiredPermission: 'system.view' },
    ],
  },
  {
    label: 'ADMINISTRATION',
    items: [
      { id: 'audit', label: 'Audit Log', icon: 'audit', route: 'audit', enabled: true, requiredPermission: 'audit.view' },
    ],
  },
];

interface SidebarProps {
  currentRoute: AdminRoute;
  onNavigate: (route: AdminRoute) => void;
  adminUser: AdminUser | null;
  onLogout: () => void;
  collapsed: boolean;
  onToggleCollapse: () => void;
  mobileOpen: boolean;
  onCloseMobile: () => void;
  hasPermission: (permission: string) => boolean;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentRoute,
  onNavigate,
  adminUser,
  onLogout,
  collapsed,
  onToggleCollapse,
  mobileOpen,
  onCloseMobile,
  hasPermission,
}) => {
  return (
    <>
      {/* Mobile Backdrop Overlay */}
      {mobileOpen && (
        <div
          className="modal-backdrop"
          style={{ zIndex: 90 }}
          onClick={onCloseMobile}
          aria-hidden="true"
        />
      )}

      <aside
        className={`sidebar ${collapsed ? 'sidebar-collapsed' : ''} ${mobileOpen ? 'sidebar-mobile-open' : ''}`}
      >
        {/* Logo Section */}
        <div className="sidebar-logo">
          <div className="sidebar-logo-icon">
            <img src="/logo.png" alt="BizSquare Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          </div>
          {!collapsed && (
            <>
              <span className="sidebar-logo-text">BizSquare</span>
              <span className="sidebar-logo-badge">Admin</span>
            </>
          )}
          <button
            type="button"
            className="sidebar-toggle-btn"
            onClick={onToggleCollapse}
            title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            <Hugeicon name={collapsed ? 'chevronRight' : 'chevronLeft'} size={14} />
          </button>
        </div>

        {/* Navigation Section */}
        <nav className="sidebar-nav" aria-label="Main Navigation">
          {NAVIGATION_GROUPS.map((group) => (
            <div key={group.label} className="sidebar-section" style={{ padding: '0.75rem 0 0.25rem' }}>
              {!collapsed && <div className="sidebar-section-label">{group.label}</div>}

              {group.items.map((item) => {
                // Permission check if required
                if (item.requiredPermission && !hasPermission(item.requiredPermission)) {
                  return null;
                }

                const isActive = item.route === currentRoute;
                const isDisabled = !item.enabled;

                return (
                  <button
                    key={item.id}
                    type="button"
                    className={`nav-item ${isActive ? 'active' : ''} ${isDisabled ? 'disabled' : ''}`}
                    onClick={() => {
                      if (isDisabled) return;
                      if (item.route) {
                        onNavigate(item.route);
                        onCloseMobile();
                      }
                    }}
                    disabled={isDisabled}
                    title={isDisabled ? `${item.label} (Not enabled in current turn)` : item.label}
                  >
                    <Hugeicon
                      name={item.icon}
                      size={16}
                      state={isActive ? 'active' : isDisabled ? 'disabled' : 'default'}
                      variant={isActive ? 'strong' : 'outline'}
                    />

                    {!collapsed && (
                      <>
                        <span className="nav-item-label">{item.label}</span>
                        {isDisabled && (
                          <span className="nav-item-badge danger">Not Enabled</span>
                        )}
                      </>
                    )}
                  </button>
                );
              })}
            </div>
          ))}
        </nav>

        {/* Admin Profile Footer */}
        <div className="sidebar-footer">
          <div className="sidebar-user">
            <div className="sidebar-avatar">
              {adminUser?.full_name ? adminUser.full_name.charAt(0).toUpperCase() : 'A'}
            </div>

            {!collapsed && (
              <div className="sidebar-user-info">
                <div className="sidebar-user-name" title={adminUser?.full_name || 'Admin Account'}>
                  {adminUser?.full_name || 'Admin Account'}
                </div>
                <div className="sidebar-user-role">
                  {adminUser?.access_level === 'super_admin' ? 'Super Admin' : 'Admin'}
                </div>
              </div>
            )}

            <button
              type="button"
              className="topbar-btn"
              onClick={onLogout}
              title="Sign Out"
              aria-label="Sign Out"
              style={{ marginLeft: 'auto', padding: 4 }}
            >
              <Hugeicon name="logout" size={14} state="error" />
            </button>
          </div>
        </div>
      </aside>
    </>
  );
};
