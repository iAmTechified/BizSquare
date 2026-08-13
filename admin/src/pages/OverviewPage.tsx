import React, { useEffect, useState, useCallback, useRef } from 'react';
import { adminAuthApi, OverviewData } from '../api/adminAuthApi';
import { useAdminAuth } from '../context/AdminAuthContext';
import { GlobalLoadingState } from '../components/common/GlobalLoadingState';
import { GlobalErrorState } from '../components/common/GlobalErrorState';
import { GlobalEmptyState } from '../components/common/GlobalEmptyState';
import { Hugeicon } from '../components/common/Hugeicon';
import { useToast } from '../context/ToastContext';
import { AdminRoute } from '../components/shell/Sidebar';

type RangeOption = 'today' | '7d' | '30d';

interface OverviewPageProps {
  onNavigate: (route: AdminRoute) => void;
}

const CACHE_KEY = 'bizsquare_admin_overview_cache';

export const OverviewPage: React.FC<OverviewPageProps> = ({ onNavigate }) => {
  const { adminUser } = useAdminAuth();
  const { showToast } = useToast();

  const [range, setRange] = useState<RangeOption>('today');
  const [data, setData] = useState<OverviewData | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [isOfflineCache, setIsOfflineCache] = useState<boolean>(false);

  // Prevent duplicate concurrent requests
  const isFetchingRef = useRef<boolean>(false);

  // Load from session storage cache on mount if available
  useEffect(() => {
    try {
      const cached = sessionStorage.getItem(CACHE_KEY);
      if (cached) {
        const parsed = JSON.parse(cached);
        if (parsed.data && parsed.timestamp) {
          setData(parsed.data);
          setLastUpdated(new Date(parsed.timestamp));
        }
      }
    } catch {
      // Ignore cache parse error
    }
  }, []);

  const fetchOverview = useCallback(
    async (selectedRange: RangeOption, isManualRefresh = false) => {
      if (isFetchingRef.current) return;
      isFetchingRef.current = true;

      if (isManualRefresh) {
        setRefreshing(true);
      } else if (!data) {
        setLoading(true);
      }

      setError(null);
      setIsOfflineCache(false);

      try {
        const res = await adminAuthApi.getOverview(selectedRange);
        setData(res);
        const now = new Date();
        setLastUpdated(now);

        // Update session cache
        try {
          sessionStorage.setItem(CACHE_KEY, JSON.stringify({ data: res, timestamp: now.toISOString() }));
        } catch {
          // Ignore cache write error
        }

        if (isManualRefresh) {
          showToast({
            type: 'success',
            title: 'Overview Refreshed',
            message: 'Operational metrics updated from backend database.',
          });
        }
      } catch (err: any) {
        console.error('Failed to fetch overview data:', err);
        
        // If we have cached data, fall back to cached view with offline warning
        const cached = sessionStorage.getItem(CACHE_KEY);
        if (cached) {
          try {
            const parsed = JSON.parse(cached);
            setData(parsed.data);
            setIsOfflineCache(true);
            showToast({
              type: 'warning',
              title: 'Offline Mode',
              message: 'Using last cached overview. Backend API is unreachable.',
            });
          } catch {
            setError(err.message || 'Failed to fetch operational overview.');
          }
        } else {
          setError(err.message || 'Failed to fetch operational overview.');
        }
      } finally {
        setLoading(false);
        setRefreshing(false);
        isFetchingRef.current = false;
      }
    },
    [data, showToast]
  );

  useEffect(() => {
    fetchOverview(range, false);
  }, [range, fetchOverview]);

  const handleRefreshClick = () => {
    fetchOverview(range, true);
  };

  const [sendingTestPush, setSendingTestPush] = useState(false);
  const handleTestPush = async () => {
    setSendingTestPush(true);
    try {
      const res = await adminAuthApi.sendAdminNotification({
        title: 'Test Broadcast 🚀',
        body: 'This is a test notification sent from the Admin Dashboard.',
        category: 'ANNOUNCEMENT',
        visual_variant: 'HIGHLIGHT',
        destination: 'bizsquare://home',
        audience_type: 'ALL'
      });
      showToast({ type: 'success', title: 'Test Push Sent', message: res.message });
    } catch (err: any) {
      showToast({ type: 'error', title: 'Test Push Failed', message: err.message || 'Failed to send test push' });
    } finally {
      setSendingTestPush(false);
    }
  };

  // Time-ago formatting helper
  const getRelativeTimeText = () => {
    if (!lastUpdated) return 'Not updated yet';
    const seconds = Math.floor((new Date().getTime() - lastUpdated.getTime()) / 1000);
    if (seconds < 10) return 'Just now';
    if (seconds < 60) return `${seconds}s ago`;
    const mins = Math.floor(seconds / 60);
    if (mins < 60) return `${mins}m ago`;
    return `${Math.floor(mins / 60)}h ago`;
  };

  // Severity style resolver
  const getSeverityBadge = (severity: string) => {
    switch (severity) {
      case 'critical':
        return <span className="badge badge-red font-bold">CRITICAL</span>;
      case 'high':
        return <span className="badge badge-yellow font-bold">HIGH</span>;
      case 'medium':
        return <span className="badge badge-blue font-bold">MEDIUM</span>;
      default:
        return <span className="badge badge-gray font-bold">INFO</span>;
    }
  };

  if (loading && !data) {
    return <GlobalLoadingState type="page" message="Compiling real-time operational overview from database…" />;
  }

  if (error && !data) {
    return (
      <GlobalErrorState
        type="network"
        title="Could Not Load Operational Overview"
        message={error}
        onRetry={() => fetchOverview(range, true)}
      />
    );
  }

  const users = data?.users;
  const contactGain = data?.contactGain;
  const spotlight = data?.spotlight;
  const notifications = data?.notifications;
  const attentionItems = data?.attentionItems || [];
  const recentActivity = data?.recentActivity || [];
  const systemHealth = data?.systemHealth;

  return (
    <div className="flex flex-col gap-6 fade-up">
      {/* Header & Controls */}
      <div className="page-header flex justify-between items-start flex-wrap gap-4">
        <div className="page-header-left">
          <h1 className="page-title">Admin Overview</h1>
          <p className="page-subtitle">
            Monitor real-time operational status, system health, and high-priority interventions across BizSquare.
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* Refresh Time Indicator */}
          <div className="text-xs text-secondary flex items-center gap-1 font-mono">
            <Hugeicon name="refresh" size={12} variant="muted" />
            <span>Updated {getRelativeTimeText()}</span>
          </div>

          {/* Date Range Selector */}
          <div className="tab-list">
            <button
              type="button"
              className={`tab-btn ${range === 'today' ? 'active' : ''}`}
              onClick={() => setRange('today')}
              disabled={refreshing}
            >
              Today
            </button>
            <button
              type="button"
              className={`tab-btn ${range === '7d' ? 'active' : ''}`}
              onClick={() => setRange('7d')}
              disabled={refreshing}
            >
              7 Days
            </button>
            <button
              type="button"
              className={`tab-btn ${range === '30d' ? 'active' : ''}`}
              onClick={() => setRange('30d')}
              disabled={refreshing}
            >
              30 Days
            </button>
          </div>

          {/* Test Push Action */}
          <button
            type="button"
            className="btn btn-primary"
            onClick={handleTestPush}
            disabled={sendingTestPush}
          >
            <Hugeicon name="notifications" className={sendingTestPush ? 'animate-spin' : ''} size={14} />
            {sendingTestPush ? 'Sending…' : 'Test Push'}
          </button>

          {/* Refresh Action */}
          <button
            type="button"
            className="btn btn-secondary"
            onClick={handleRefreshClick}
            disabled={refreshing}
          >
            <Hugeicon name="refresh" className={refreshing ? 'animate-spin' : ''} size={14} />
            {refreshing ? 'Refreshing…' : 'Refresh'}
          </button>
        </div>
      </div>

      {/* Offline Cache Warning Banner */}
      {isOfflineCache && (
        <div className="alert alert-error fade-up">
          <Hugeicon name="warning" state="error" size={16} />
          <div>
            <strong>Offline Mode:</strong> Showing cached overview data from {lastUpdated?.toLocaleTimeString()}. Backend server is currently unreachable.
          </div>
        </div>
      )}

      {/* SECTION 1: Key Operational Metrics Cards */}
      <div className="stat-grid">
        {/* Metric 1: Total Active Users */}
        <div className="stat-card" style={{ '--card-accent': 'var(--brand-blue)', '--card-accent-dim': 'var(--brand-blue-dim)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Active Users</span>
            <div className="stat-icon">
              <Hugeicon name="users" size={14} state="active" />
            </div>
          </div>
          <div className="stat-value">
            {users ? users.active_users.toLocaleString() : '—'}
          </div>
          <div className="stat-change text-secondary">
            {users ? `+${users.new_users_in_period} new in selected period` : 'Total registered accounts'}
          </div>
        </div>

        {/* Metric 2: Contacts Gained in Period */}
        <div className="stat-card" style={{ '--card-accent': 'var(--brand-green)', '--card-accent-dim': 'var(--brand-green-dim)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Contacts Gained</span>
            <div className="stat-icon">
              <Hugeicon name="contacts" size={14} state="success" />
            </div>
          </div>
          <div className="stat-value">
            {contactGain ? contactGain.contacts_gained_in_period.toLocaleString() : '0'}
          </div>
          <div className="stat-change text-secondary">
            {contactGain?.sync_failures && contactGain.sync_failures > 0 ? (
              <span style={{ color: 'var(--danger)' }}>{contactGain.sync_failures} sync failures</span>
            ) : (
              'Synced contact relationships'
            )}
          </div>
        </div>

        {/* Metric 3: Spotlight Turn Status */}
        <div className="stat-card" style={{ '--card-accent': 'var(--warning)', '--card-accent-dim': 'var(--warning-dim)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Spotlight Turn</span>
            <div className="stat-icon">
              <Hugeicon name="spotlight" size={14} state="warning" />
            </div>
          </div>
          <div className="stat-value truncate" style={{ fontSize: '1.25rem', marginTop: 4 }}>
            {spotlight?.active_campaign ? spotlight.active_campaign.business_name : 'No Active Turn'}
          </div>
          <div className="stat-change text-secondary">
            {spotlight?.pending_reviews_count && spotlight.pending_reviews_count > 0 ? (
              <span style={{ color: 'var(--warning)' }}>{spotlight.pending_reviews_count} pending reviews</span>
            ) : (
              spotlight?.active_campaign ? `${spotlight.active_campaign.participants_count} participants` : 'Spotlight economy idle'
            )}
          </div>
        </div>

        {/* Metric 4: Notifications Sent in Period */}
        <div className="stat-card" style={{ '--card-accent': 'var(--brand-pink)', '--card-accent-dim': 'var(--brand-pink-dim)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Notifications Sent</span>
            <div className="stat-icon">
              <Hugeicon name="notifications" size={14} />
            </div>
          </div>
          <div className="stat-value">
            {notifications ? notifications.sent_in_period.toLocaleString() : '0'}
          </div>
          <div className="stat-change text-secondary">
            {notifications?.scheduled ? `${notifications.scheduled} scheduled` : 'Push notifications'}
          </div>
        </div>
      </div>

      {/* SECTION 2: Attention Required (High-Priority Operational Alerts) */}
      <div className="card">
        <div className="card-header">
          <span className="card-title">
            <Hugeicon name="warning" size={16} state={attentionItems.length > 0 ? 'warning' : 'success'} />
            Attention Required
            {attentionItems.length > 0 ? (
              <span className="badge badge-yellow">{attentionItems.length} Intervention{attentionItems.length > 1 ? 's' : ''}</span>
            ) : (
              <span className="badge badge-green">● All Systems Clear</span>
            )}
          </span>
        </div>

        {attentionItems.length === 0 ? (
          <GlobalEmptyState
            icon="check"
            title="No Operational Interventions Required"
            description="BizSquare system algorithms, matching cycles, Spotlight turns, and user accounts are operating normally."
            badge="Healthy Status"
            style={{ padding: '2rem 1.5rem' }}
          />
        ) : (
          <div className="card-body flex flex-col gap-3">
            {attentionItems.map((item) => (
              <div
                key={item.id}
                style={{
                  background: 'var(--bg-elevated)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-md)',
                  padding: '1rem 1.25rem',
                  display: 'flex',
                  alignItems: 'flex-start',
                  justifyContent: 'space-between',
                  gap: '1rem',
                }}
              >
                <div className="flex items-start gap-3">
                  <div style={{ marginTop: 2 }}>{getSeverityBadge(item.severity)}</div>
                  <div>
                    <div style={{ fontSize: '0.9375rem', fontWeight: 700, color: 'var(--text-primary)', marginBottom: 2 }}>
                      {item.title}
                    </div>
                    <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', margin: 0, lineHeight: 1.4 }}>
                      {item.description}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <span className="badge badge-gray font-mono">{item.sourceModule}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* SECTION 3: Operations Status Grid (Contact Gain, Spotlight, Notifications) */}
      <div className="grid-3">
        {/* Contact Gain Status Card */}
        <div className="card">
          <div className="card-header">
            <span className="card-title">
              <Hugeicon name="contacts" size={15} state="active" />
              Contact Gain Engine
            </span>
            <span className="badge badge-blue">
              {contactGain?.latest_cycle ? `Cycle #${contactGain.latest_cycle.cycle_number}` : 'No Runs'}
            </span>
          </div>
          <div className="card-body flex flex-col gap-3">
            {contactGain?.latest_cycle ? (
              <>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-secondary">Cycle Status:</span>
                  <span className={`badge ${contactGain.latest_cycle.status === 'COMPLETED' ? 'badge-green' : contactGain.latest_cycle.status === 'FAILED' ? 'badge-red' : 'badge-yellow'}`}>
                    {contactGain.latest_cycle.status}
                  </span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-secondary">Users Processed:</span>
                  <span className="font-bold">{contactGain.latest_cycle.users_processed.toLocaleString()}</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-secondary">Total Allocations:</span>
                  <span className="font-bold">{contactGain.latest_cycle.total_allocations.toLocaleString()}</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-secondary">Underfilled Users:</span>
                  <span className={`font-bold ${contactGain.latest_cycle.users_underfilled > 0 ? 'text-warning' : ''}`}>
                    {contactGain.latest_cycle.users_underfilled}
                  </span>
                </div>
              </>
            ) : (
              <div className="text-center text-sm text-secondary p-4">
                No matching cycles recorded in PostgreSQL database yet.
              </div>
            )}
          </div>
        </div>

        {/* Spotlight Economy Status Card */}
        <div className="card">
          <div className="card-header">
            <span className="card-title">
              <Hugeicon name="spotlight" size={15} state="warning" />
              Spotlight Economy
            </span>
            <span className="badge badge-yellow">
              {spotlight?.active_campaign ? '● Active Turn' : 'Idle'}
            </span>
          </div>
          <div className="card-body flex flex-col gap-3">
            {spotlight?.active_campaign ? (
              <>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-secondary">Active Business:</span>
                  <span className="font-bold truncate" style={{ maxWidth: 140 }}>
                    {spotlight.active_campaign.business_name}
                  </span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-secondary">Turn Owner:</span>
                  <span className="font-bold">{spotlight.active_campaign.owner_name}</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-secondary">Participants:</span>
                  <span className="font-bold">{spotlight.active_campaign.participants_count}</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-secondary">Pending Reviews:</span>
                  <span className={`font-bold ${spotlight.pending_reviews_count > 0 ? 'text-warning' : ''}`}>
                    {spotlight.pending_reviews_count}
                  </span>
                </div>
              </>
            ) : (
              <div className="text-center text-sm text-secondary p-4">
                No active Spotlight campaign turn currently live.
              </div>
            )}
          </div>
        </div>

        {/* Notifications & System Jobs Status Card */}
        <div className="card">
          <div className="card-header">
            <span className="card-title">
              <Hugeicon name="notifications" size={15} />
              Communication & Delivery
            </span>
            <span className="badge badge-gray">Broadcasts</span>
          </div>
          <div className="card-body flex flex-col gap-3">
            <div className="flex justify-between items-center text-sm">
              <span className="text-secondary">Sent in Selected Period:</span>
              <span className="font-bold">{notifications?.sent_in_period.toLocaleString() || '0'}</span>
            </div>
            <div className="flex justify-between items-center text-sm">
              <span className="text-secondary">Delivery Failures:</span>
              <span className={`font-bold ${notifications?.failed_in_period && notifications.failed_in_period > 0 ? 'text-danger' : ''}`}>
                {notifications?.failed_in_period || 0}
              </span>
            </div>
            <div className="flex justify-between items-center text-sm">
              <span className="text-secondary">Scheduled Queue:</span>
              <span className="font-bold">{notifications?.scheduled || 0}</span>
            </div>
          </div>
        </div>
      </div>

      {/* SECTION 4: Recent Operational Activity & System Infrastructure Health */}
      <div className="grid-2">
        {/* Recent Operational Activity Feed (From PostgreSQL audit_logs) */}
        <div className="card">
          <div className="card-header">
            <span className="card-title">
              <Hugeicon name="audit" size={16} state="active" />
              Recent Operational Activity
            </span>
            <button
              type="button"
              className="btn btn-xs btn-secondary"
              onClick={() => onNavigate('audit')}
            >
              View Full Audit
            </button>
          </div>

          {recentActivity.length === 0 ? (
            <GlobalEmptyState
              icon="audit"
              title="No Recent Audit Activity"
              description="No administrative actions or events recorded in audit trail."
              style={{ padding: '1.5rem' }}
            />
          ) : (
            <div className="table-wrap">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Time</th>
                    <th>Action</th>
                    <th>Admin</th>
                    <th>Result</th>
                  </tr>
                </thead>
                <tbody>
                  {recentActivity.map((act) => (
                    <tr key={act.id}>
                      <td className="text-xs font-mono text-secondary">
                        {new Date(act.created_at).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })}
                      </td>
                      <td>
                        <span className="badge badge-blue font-mono">{act.action}</span>
                      </td>
                      <td className="text-xs font-bold">{act.admin_name}</td>
                      <td>
                        <span className={`badge ${act.result === 'success' ? 'badge-green' : 'badge-red'}`}>
                          {act.result}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* System Infrastructure Health Summary */}
        <div className="card">
          <div className="card-header">
            <span className="card-title">
              <Hugeicon name="system" size={16} state={systemHealth?.status === 'healthy' ? 'success' : 'error'} />
              Infrastructure Health
            </span>
            <button
              type="button"
              className="btn btn-xs btn-secondary"
              onClick={() => onNavigate('system')}
            >
              Full Health Report
            </button>
          </div>

          <div className="card-body flex flex-col gap-4">
            <div className="flex items-center justify-between p-3 rounded" style={{ background: 'var(--bg-elevated)', border: '1px solid var(--border)' }}>
              <div className="flex items-center gap-2">
                <Hugeicon name="system" size={16} state={systemHealth?.db_status === 'connected' ? 'success' : 'error'} />
                <div>
                  <div className="font-bold text-sm">PostgreSQL Database Pool</div>
                  <div className="text-xs text-secondary">Query Latency: {systemHealth?.db_latency_ms || 0} ms</div>
                </div>
              </div>
              <span className={`badge ${systemHealth?.db_status === 'connected' ? 'badge-green' : 'badge-red'}`}>
                {systemHealth?.db_status === 'connected' ? '● Connected' : '✕ Error'}
              </span>
            </div>

            <div className="flex items-center justify-between p-3 rounded" style={{ background: 'var(--bg-elevated)', border: '1px solid var(--border)' }}>
              <div className="flex items-center gap-2">
                <Hugeicon name="refresh" size={16} state="active" />
                <div>
                  <div className="font-bold text-sm">Express Server Uptime</div>
                  <div className="text-xs text-secondary">Node process uptime</div>
                </div>
              </div>
              <span className="font-mono text-sm font-bold">
                {systemHealth ? `${Math.floor(systemHealth.uptime_seconds / 3600)}h ${Math.floor((systemHealth.uptime_seconds % 3600) / 60)}m` : '0h 0m'}
              </span>
            </div>

            <div className="flex items-center justify-between p-3 rounded" style={{ background: 'var(--bg-elevated)', border: '1px solid var(--border)' }}>
              <div className="flex items-center gap-2">
                <Hugeicon name="analytics" size={16} />
                <div>
                  <div className="font-bold text-sm">Node Heap Memory</div>
                  <div className="text-xs text-secondary">Memory allocated</div>
                </div>
              </div>
              <span className="font-mono text-sm font-bold">
                {systemHealth?.memory_used_mb || 0} MB
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
