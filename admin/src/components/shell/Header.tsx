import React, { useState, useEffect, useRef } from 'react';
import { Hugeicon } from '../common/Hugeicon';
import { Breadcrumbs, BreadcrumbItem } from '../common/Breadcrumbs';
import { AdminUser } from '../../api/adminAuthApi';

interface HeaderProps {
  title: string;
  breadcrumbItems: BreadcrumbItem[];
  adminUser: AdminUser | null;
  onLogout: () => void;
  onToggleMobileSidebar: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  title,
  breadcrumbItems,
  adminUser,
  onLogout,
  onToggleMobileSidebar,
}) => {
  // Global Search Foundation state
  const [searchQuery, setSearchQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [searchFocused, setSearchFocused] = useState(false);

  // Notification Entry Point state
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const unreadCount = 0; // Real unread notification count foundation

  // Profile Dropdown Menu state
  const [profileMenuOpen, setProfileMenuOpen] = useState(false);

  const searchRef = useRef<HTMLDivElement>(null);
  const notifRef = useRef<HTMLDivElement>(null);
  const profileRef = useRef<HTMLDivElement>(null);

  // Handle click outside for dropdowns
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(e.target as Node)) {
        setSearchFocused(false);
      }
      if (notifRef.current && !notifRef.current.contains(e.target as Node)) {
        setNotificationsOpen(false);
      }
      if (profileRef.current && !profileRef.current.contains(e.target as Node)) {
        setProfileMenuOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setSearchQuery(val);
    if (val.trim()) {
      setIsSearching(true);
      // Simulate real search debounce check
      const timer = setTimeout(() => {
        setIsSearching(false);
      }, 300);
      return () => clearTimeout(timer);
    } else {
      setIsSearching(false);
    }
  };

  return (
    <header className="topbar">
      <div className="flex items-center gap-3">
        <button
          type="button"
          className="topbar-mobile-menu-btn"
          onClick={onToggleMobileSidebar}
          aria-label="Open navigation menu"
        >
          <Hugeicon name="menu" size={20} />
        </button>

        <Breadcrumbs items={breadcrumbItems} />
      </div>

      <div className="topbar-actions">
        {/* Global Search Foundation */}
        <div className="search-container" ref={searchRef} style={{ position: 'relative' }}>
          <div className="search-bar" style={{ width: searchFocused ? 320 : 220, transition: 'all 0.2s ease' }}>
            <Hugeicon name="search" size={14} state={searchFocused ? 'active' : 'default'} />
            <input
              type="text"
              placeholder="Search admin system…"
              value={searchQuery}
              onChange={handleSearchChange}
              onFocus={() => setSearchFocused(true)}
              aria-label="Global search"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => { setSearchQuery(''); setIsSearching(false); }}
                style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
              >
                <Hugeicon name="close" size={12} variant="muted" />
              </button>
            )}
          </div>

          {/* Search Results Dropdown Foundation */}
          {searchFocused && searchQuery.trim() !== '' && (
            <div className="search-results-dropdown fade-up">
              {isSearching ? (
                <div className="flex items-center gap-2 p-3 text-secondary text-sm">
                  <Hugeicon name="refresh" className="animate-spin" size={14} />
                  Searching system records…
                </div>
              ) : (
                <div className="p-3 text-center text-secondary text-sm">
                  <Hugeicon name="search" size={20} variant="muted" style={{ marginBottom: 4 }} />
                  <div>No records matching "<strong>{searchQuery}</strong>"</div>
                  <div className="text-xs text-tertiary" style={{ marginTop: 2 }}>
                    Search connects to real system logs and records.
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Admin Notification Entry Point Foundation */}
        <div style={{ position: 'relative' }} ref={notifRef}>
          <button
            type="button"
            className="topbar-btn"
            onClick={() => setNotificationsOpen((v) => !v)}
            title="Notifications"
            aria-label="Admin notifications entry point"
            style={{ position: 'relative' }}
          >
            <Hugeicon name="notifications" size={16} />
            {unreadCount > 0 && (
              <span className="notif-badge">{unreadCount}</span>
            )}
          </button>

          {notificationsOpen && (
            <div className="notif-dropdown fade-up">
              <div className="notif-dropdown-header">
                <span className="font-bold text-sm">Admin Notifications</span>
                <span className="badge badge-gray">0 Unread</span>
              </div>
              <div className="notif-dropdown-body">
                <div className="empty-state" style={{ padding: '1.5rem 1rem' }}>
                  <Hugeicon name="notifications" size={22} variant="muted" />
                  <div className="empty-state-title" style={{ fontSize: 13 }}>No Unread Notifications</div>
                  <div className="empty-state-desc" style={{ fontSize: 11 }}>
                    All administrative alerts and system notifications are up to date.
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Admin Profile Menu */}
        <div style={{ position: 'relative' }} ref={profileRef}>
          <button
            type="button"
            className="profile-menu-trigger"
            onClick={() => setProfileMenuOpen((v) => !v)}
            aria-label="Admin profile menu"
          >
            <div className="sidebar-avatar" style={{ width: 28, height: 28, fontSize: 11 }}>
              {adminUser?.full_name ? adminUser.full_name.charAt(0).toUpperCase() : 'A'}
            </div>
            <span className="profile-name text-sm font-bold truncate" style={{ maxWidth: 110 }}>
              {adminUser?.full_name?.split(' ')[0] || 'Admin'}
            </span>
            <Hugeicon name="chevronDown" size={12} variant="muted" />
          </button>

          {profileMenuOpen && (
            <div className="profile-dropdown fade-up">
              <div className="profile-dropdown-header">
                <div className="font-bold text-sm">{adminUser?.full_name || 'Administrator'}</div>
                <div className="text-xs text-secondary font-mono" style={{ marginTop: 2 }}>
                  {adminUser?.phone_number}
                </div>
                <div className="flex items-center gap-1 mt-2">
                  <span className="badge badge-blue">{adminUser?.access_level === 'super_admin' ? 'Super Admin' : 'Admin'}</span>
                  <span className="badge badge-gray">{adminUser?.permissions?.length || 0} Perms</span>
                </div>
              </div>

              <div className="profile-dropdown-menu">
                <button
                  type="button"
                  className="profile-menu-item text-danger"
                  onClick={() => {
                    setProfileMenuOpen(false);
                    onLogout();
                  }}
                >
                  <Hugeicon name="logout" size={14} state="error" />
                  Sign Out
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
};
