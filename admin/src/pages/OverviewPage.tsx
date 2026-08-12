import React from 'react';
import { useAdminAuth } from '../context/AdminAuthContext';
import { Hugeicon } from '../components/common/Hugeicon';
import { AdminRoute } from '../components/shell/Sidebar';

interface OverviewPageProps {
  onNavigate: (route: AdminRoute) => void;
}

export const OverviewPage: React.FC<OverviewPageProps> = ({ onNavigate }) => {
  const { adminUser } = useAdminAuth();

  // Determine time-of-day greeting
  const hour = new Date().getHours();
  const timeGreeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
  const adminName = adminUser?.full_name || 'Administrator';

  return (
    <div className="flex flex-col gap-6 fade-up">
      {/* Page Header */}
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">
            {timeGreeting}, {adminName}
          </h1>
          <p className="page-subtitle">
            Welcome to the BizSquare MVP 1.0 Administrative Control Shell.
          </p>
        </div>
      </div>

      {/* Real Admin Session Card */}
      <div
        className="card"
        style={{
          background: 'linear-gradient(135deg, rgba(0, 88, 255, 0.08), rgba(12, 15, 24, 0.95))',
          border: '1px solid rgba(0, 88, 255, 0.25)',
          padding: '1.5rem',
        }}
      >
        <div className="flex justify-between items-center flex-wrap gap-4">
          <div className="flex items-center gap-3">
            <div
              style={{
                width: 48,
                height: 48,
                borderRadius: 12,
                background: 'var(--brand-blue-dim)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                border: '1px solid rgba(0, 88, 255, 0.3)',
              }}
            >
              <Hugeicon name="userProfile" state="active" size={24} />
            </div>

            <div>
              <div className="flex items-center gap-2 mb-1">
                <span style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
                  {adminUser?.full_name}
                </span>
                <span className="badge badge-blue">
                  {adminUser?.access_level === 'super_admin' ? 'Super Admin' : 'Admin'}
                </span>
                <span className="badge badge-green">● Active Session</span>
              </div>
              <div className="text-xs text-secondary font-mono">
                Account ID: {adminUser?.id || '—'} | Phone: {adminUser?.phone_number || '—'}
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              className="btn btn-secondary btn-sm"
              onClick={() => onNavigate('system')}
            >
              <Hugeicon name="system" size={14} />
              System Health
            </button>
            <button
              type="button"
              className="btn btn-secondary btn-sm"
              onClick={() => onNavigate('audit')}
            >
              <Hugeicon name="audit" size={14} />
              Audit Log
            </button>
          </div>
        </div>
      </div>

      {/* Permissions Grid */}
      <div className="card">
        <div className="card-header">
          <span className="card-title">
            <Hugeicon name="lock" size={16} state="active" />
            Active Role & Granted Permissions
          </span>
          <span className="badge badge-gray">{adminUser?.permissions?.length || 0} Permissions</span>
        </div>

        <div className="card-body">
          <p className="text-sm text-secondary mb-4">
            Your administrative account has been granted the following authorization scopes derived server-side from PostgreSQL:
          </p>

          <div className="grid-3">
            {adminUser?.permissions?.map((perm) => (
              <div
                key={perm}
                style={{
                  background: 'var(--bg-elevated)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-sm)',
                  padding: '0.625rem 0.75rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                }}
              >
                <Hugeicon name="check" state="success" size={14} />
                <span className="font-mono text-xs font-bold" style={{ color: 'var(--text-primary)' }}>
                  {perm}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Operational Roadmap Notice */}
      <div
        className="card"
        style={{
          border: '1px dashed var(--border-bright)',
          background: 'var(--bg-surface)',
          padding: '1.5rem',
        }}
      >
        <div className="flex items-start gap-3">
          <div
            style={{
              width: 36,
              height: 36,
              borderRadius: 8,
              background: 'var(--bg-elevated)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
            }}
          >
            <Hugeicon name="info" size={18} variant="muted" />
          </div>

          <div>
            <h4 style={{ fontSize: '0.9375rem', fontWeight: 700, marginBottom: '0.25rem' }}>
              Operational Foundation Ready
            </h4>
            <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', lineHeight: 1.5, margin: 0 }}>
              The Admin Dashboard Shell, Authentication, Authorization Foundation, Audit Infrastructure, and System Monitoring are live. Operational business modules (Users, Contact Gain, Spotlight, Content Bank, Notifications Composer) will be enabled in their dedicated implementation turns without using mock metrics.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
