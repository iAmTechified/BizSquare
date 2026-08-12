import React, { useEffect, useState, useCallback } from 'react';
import {
  adminAuthApi,
  ContactGainCycleItem,
  CycleUserOutcomeItem,
} from '../api/adminAuthApi';
import { useAdminAuth } from '../context/AdminAuthContext';
import { useToast } from '../context/ToastContext';
import { useConfirmation } from '../context/ConfirmationContext';
import { GlobalLoadingState } from '../components/common/GlobalLoadingState';
import { GlobalErrorState } from '../components/common/GlobalErrorState';
import { GlobalEmptyState } from '../components/common/GlobalEmptyState';
import { Hugeicon } from '../components/common/Hugeicon';
import { UserContactGainModal } from '../components/contact_gain/UserContactGainModal';

export const ContactGainPage: React.FC = () => {
  const { hasPermission } = useAdminAuth();
  const { showToast } = useToast();
  const { confirm } = useConfirmation();

  const canManage = hasPermission('contacts.manage');

  const [currentCycle, setCurrentCycle] = useState<ContactGainCycleItem | null>(null);
  const [cycles, setCycles] = useState<ContactGainCycleItem[]>([]);
  const [userOutcomes, setUserOutcomes] = useState<CycleUserOutcomeItem[]>([]);
  const [gaps, setGaps] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Modals & User inspection state
  const [inspectingUserId, setInspectingUserId] = useState<string | null>(null);
  const [triggering, setTriggering] = useState<boolean>(false);
  const [retryingSync, setRetryingSync] = useState<boolean>(false);

  // Tabs & filters state
  const [activeSection, setActiveSection] = useState<'overview' | 'outcomes' | 'history'>('overview');
  const [outcomeSearch, setOutcomeSearch] = useState<string>('');
  const [outcomeFilter, setOutcomeFilter] = useState<string>('all');

  const fetchContactGainData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const resCurrent = await adminAuthApi.getCurrentContactGainCycle();
      setCurrentCycle(resCurrent.current_cycle);

      const [resCycles, resGaps] = await Promise.all([
        adminAuthApi.getContactGainCycles(20, 0).catch(() => ({ success: true, cycles: [] })),
        adminAuthApi.getContactGainGaps().catch(() => ({ success: true, gaps: { underfilled_users: [] } })),
      ]);

      setCycles(resCycles.cycles || []);
      setGaps(resGaps.gaps?.underfilled_users || []);

      if (resCurrent.current_cycle?.id) {
        const resOutcomes = await adminAuthApi.getCycleUserOutcomes(resCurrent.current_cycle.id, {
          search: outcomeSearch,
          outcome: outcomeFilter,
          limit: 30,
          offset: 0,
        }).catch(() => ({ success: true, user_outcomes: [] }));

        setUserOutcomes(resOutcomes.user_outcomes || []);
      }
    } catch (err: any) {
      console.error('Failed to fetch Contact Gain data:', err);
      setError(err.message || 'Failed to query Contact Gain data from PostgreSQL database.');
      showToast({
        type: 'error',
        title: 'Contact Gain Query Error',
        message: err.message || 'Could not fetch Contact Gain cycle state.',
      });
    } finally {
      setLoading(false);
    }
  }, [outcomeSearch, outcomeFilter, showToast]);

  useEffect(() => {
    fetchContactGainData();
  }, [fetchContactGainData]);

  const handleTriggerCycle = () => {
    confirm({
      title: 'Trigger Weekly Contact Gain Cycle',
      description: 'Are you sure you want to execute a new weekly Contact Gain matching cycle?',
      consequence: 'The backend matching engine will calculate 10% targets, competitor exclusions, reciprocity, and populate device sync queues for all eligible active users.',
      isDestructive: false,
      confirmLabel: 'Run Weekly Cycle',
      onConfirm: async () => {
        setTriggering(true);
        try {
          const res = await adminAuthApi.triggerWeeklyMatchingCycle();
          showToast({
            type: 'success',
            title: 'Cycle Executed',
            message: res.message || 'Weekly Contact Gain matching cycle completed successfully.',
          });
          fetchContactGainData();
        } catch (err: any) {
          console.error('Trigger cycle error:', err);
          showToast({
            type: 'error',
            title: 'Cycle Execution Failed',
            message: err.message || 'Failed to execute matching cycle.',
          });
        } finally {
          setTriggering(false);
        }
      },
    });
  };

  const handleRetrySync = () => {
    if (!currentCycle) return;
    confirm({
      title: 'Retry Failed Device Sync Records',
      description: `Are you sure you want to retry failed device sync records for Cycle #${currentCycle.cycle_number}?`,
      consequence: 'This will atomically re-queue failed syncs for device delivery without creating duplicate contacts or exceeding caps.',
      isDestructive: false,
      confirmLabel: 'Retry Failed Syncs',
      onConfirm: async () => {
        setRetryingSync(true);
        try {
          const res = await adminAuthApi.retryCycleDeviceSync(currentCycle.id);
          showToast({
            type: 'success',
            title: 'Sync Re-queued',
            message: res.message || `Queued ${res.retried_count} records for sync retry.`,
          });
          fetchContactGainData();
        } catch (err: any) {
          console.error('Retry sync error:', err);
          showToast({
            type: 'error',
            title: 'Sync Retry Failed',
            message: err.message || 'Failed to retry sync records.',
          });
        } finally {
          setRetryingSync(false);
        }
      },
    });
  };

  if (loading && !currentCycle && cycles.length === 0) {
    return <GlobalLoadingState type="page" message="Querying authoritative Contact Gain cycle state…" />;
  }

  if (error && !currentCycle) {
    return (
      <GlobalErrorState
        type="page"
        title="Could Not Load Contact Gain Operations"
        message={error}
        onRetry={fetchContactGainData}
      />
    );
  }

  return (
    <div className="flex flex-col gap-6 fade-up">
      {/* User Contact Gain Inspection Modal */}
      {inspectingUserId && (
        <UserContactGainModal
          userId={inspectingUserId}
          onClose={() => setInspectingUserId(null)}
        />
      )}

      {/* Page Header */}
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">Contact Gain Operations</h1>
          <p className="page-subtitle">Monitor weekly contact discovery, matching and synchronization.</p>
        </div>

        <div className="flex items-center gap-2">
          {canManage && (
            <button
              type="button"
              className="btn btn-primary"
              onClick={handleTriggerCycle}
              disabled={triggering || currentCycle?.status === 'RUNNING'}
            >
              <Hugeicon name="refresh" className={triggering ? 'animate-spin' : ''} size={14} />
              {triggering ? 'Executing Cycle…' : 'Trigger Weekly Cycle'}
            </button>
          )}

          <button type="button" className="btn btn-secondary" onClick={fetchContactGainData}>
            <Hugeicon name="refresh" className={loading ? 'animate-spin' : ''} size={14} />
            Refresh
          </button>
        </div>
      </div>

      {/* HERO CARD: CURRENT CYCLE STATUS */}
      <div
        className="card"
        style={{
          background: 'linear-gradient(135deg, rgba(0, 88, 255, 0.08), rgba(12, 15, 24, 0.95))',
          border: '1px solid rgba(0, 88, 255, 0.3)',
          padding: '1.75rem',
        }}
      >
        <div className="flex items-center justify-between flex-wrap gap-4 mb-4">
          <div className="flex items-center gap-2">
            <Hugeicon name="contacts" size={20} state="active" />
            <span style={{ fontSize: '0.85rem', fontWeight: 800, letterSpacing: '1px', textTransform: 'uppercase', color: 'var(--brand-blue)' }}>
              CURRENT MATCHING CYCLE #{currentCycle ? currentCycle.cycle_number : '1'}
            </span>
            {currentCycle?.status === 'RUNNING' && (
              <span className="badge badge-yellow flex items-center gap-1">
                <Hugeicon name="refresh" className="animate-spin" size={12} />
                Processing
              </span>
            )}
          </div>

          {currentCycle && (
            <div className="flex items-center gap-2">
              <span className={`badge ${currentCycle.status === 'COMPLETED' ? 'badge-green' : currentCycle.status === 'FAILED' ? 'badge-red' : 'badge-blue'}`}>
                Status: {currentCycle.status}
              </span>
              <span className="text-xs text-tertiary font-mono">
                Batch Date: {new Date(currentCycle.batch_date).toLocaleDateString('en-GB')}
              </span>
            </div>
          )}
        </div>

        {currentCycle ? (
          <div className="flex flex-col gap-4">
            {/* KPI Metrics Row */}
            <div className="grid-4 gap-4">
              <div className="metric-card">
                <div className="metric-label">Users Processed</div>
                <div className="metric-value text-xl font-bold">{currentCycle.users_processed}</div>
                <div className="text-xs text-tertiary">Network size: {currentCycle.network_size_live || currentCycle.network_size}</div>
              </div>

              <div className="metric-card">
                <div className="metric-label">10% Fill Target Met</div>
                <div className="metric-value text-xl font-bold" style={{ color: 'var(--brand-green)' }}>
                  {currentCycle.users_filled}
                </div>
                <div className="text-xs text-tertiary">Target/user: {currentCycle.weekly_target_calculated || currentCycle.target_per_user}</div>
              </div>

              <div className="metric-card">
                <div className="metric-label">Below Target (Supply Gap)</div>
                <div className="metric-value text-xl font-bold" style={{ color: 'var(--warning-yellow)' }}>
                  {currentCycle.users_underfilled}
                </div>
                <div className="text-xs text-tertiary">Competitor exclusions: {currentCycle.competitor_exclusions_count}</div>
              </div>

              <div className="metric-card">
                <div className="metric-label">Total Contacts Gained</div>
                <div className="metric-value text-xl font-bold" style={{ color: 'var(--brand-blue)' }}>
                  {currentCycle.total_allocations}
                </div>
                <div className="text-xs text-tertiary">
                  Tier 1: {currentCycle.tier_1_count} • Tier 2: {currentCycle.tier_2_count} • Tier 3: {currentCycle.tier_3_count}
                </div>
              </div>
            </div>

            {/* Sync Pipeline Bar */}
            <div
              style={{
                background: 'var(--bg-elevated)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-md)',
                padding: '1rem',
              }}
              className="flex justify-between items-center flex-wrap gap-4"
            >
              <div className="flex items-center gap-4">
                <span className="text-xs text-secondary font-bold uppercase">Device Sync Pipeline:</span>
                <span className="badge badge-green">Synced: {currentCycle.sync_metrics?.synced || 0}</span>
                <span className="badge badge-yellow">Pending: {currentCycle.sync_metrics?.pending || 0}</span>
                {currentCycle.sync_metrics?.failed ? (
                  <span className="badge badge-red">Failed: {currentCycle.sync_metrics.failed}</span>
                ) : (
                  <span className="badge badge-gray">Failed: 0</span>
                )}
              </div>

              {canManage && (currentCycle.sync_metrics?.failed ?? 0) > 0 && (
                <button
                  type="button"
                  className="btn btn-xs btn-secondary"
                  onClick={handleRetrySync}
                  disabled={retryingSync}
                >
                  <Hugeicon name="refresh" className={retryingSync ? 'animate-spin' : ''} size={12} />
                  Retry Failed Syncs ({currentCycle.sync_metrics?.failed})
                </button>
              )}
            </div>
          </div>
        ) : (
          <div className="p-6 text-center text-secondary text-sm">
            No Contact Gain cycle has executed yet. Click &quot;Trigger Weekly Cycle&quot; to run the matching engine.
          </div>
        )}
      </div>

      {/* SECTION TABS */}
      <div className="tab-list">
        <button
          type="button"
          className={`tab-btn ${activeSection === 'overview' ? 'active' : ''}`}
          onClick={() => setActiveSection('overview')}
        >
          <Hugeicon name="overview" size={14} />
          Overview & Matching Gaps
        </button>
        <button
          type="button"
          className={`tab-btn ${activeSection === 'outcomes' ? 'active' : ''}`}
          onClick={() => setActiveSection('outcomes')}
        >
          <Hugeicon name="users" size={14} />
          User Outcomes ({userOutcomes.length})
        </button>
        <button
          type="button"
          className={`tab-btn ${activeSection === 'history' ? 'active' : ''}`}
          onClick={() => setActiveSection('history')}
        >
          <Hugeicon name="history" size={14} />
          Weekly Cycle History ({cycles.length})
        </button>
      </div>

      {/* SECTION 1: OVERVIEW & MATCHING GAPS */}
      {activeSection === 'overview' && (
        <div className="grid-2 fade-up">
          {/* Matching Gaps & Imbalances */}
          <div className="card">
            <div className="card-header flex justify-between items-center">
              <span className="card-title">
                <Hugeicon name="warning" size={16} state="warning" />
                Matching Gaps & Supply Imbalances ({gaps.length})
              </span>
            </div>
            <div className="card-body">
              {gaps.length === 0 ? (
                <div className="text-center p-6 text-secondary text-sm">
                  No matching gaps detected! All users received their 10% minimum target.
                </div>
              ) : (
                <div className="flex flex-col gap-2">
                  {gaps.slice(0, 5).map((gap) => (
                    <div
                      key={gap.user_id}
                      style={{
                        background: 'var(--bg-elevated)',
                        border: '1px solid var(--border)',
                        borderRadius: 'var(--radius-sm)',
                        padding: '0.75rem',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <div>
                        <div className="font-bold text-sm">{gap.full_name}</div>
                        <div className="text-xs text-secondary">{gap.business_name || gap.primary_offer}</div>
                        <div className="text-xs text-tertiary mt-0.5">
                          Reason: {gap.unfilled_reason || 'Insufficient eligible supply in matching pool'}
                        </div>
                      </div>

                      <div className="text-right">
                        <span className="badge badge-yellow text-xs">
                          {gap.allocated_count} / {gap.target_count} Received
                        </span>
                        <div className="mt-1">
                          <button
                            type="button"
                            className="btn btn-xs btn-secondary"
                            onClick={() => setInspectingUserId(gap.user_id)}
                          >
                            Inspect User
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Matching Engine Rules Summary */}
          <div className="card">
            <div className="card-header">
              <span className="card-title">
                <Hugeicon name="info" size={16} state="active" />
                Matching Engine Priority & Safeguards
              </span>
            </div>
            <div className="card-body flex flex-col gap-3 text-xs text-secondary">
              <div
                style={{
                  background: 'var(--bg-elevated)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-sm)',
                  padding: '0.75rem',
                }}
              >
                <div className="font-bold text-sm text-primary mb-1">Priority 1 (Primary Supply Match)</div>
                <p>Matches user&apos;s staged interest with candidate&apos;s Primary Business Offer.</p>
              </div>

              <div
                style={{
                  background: 'var(--bg-elevated)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-sm)',
                  padding: '0.75rem',
                }}
              >
                <div className="font-bold text-sm text-primary mb-1">Priority 2 (Secondary Supply Match)</div>
                <p>Matches user&apos;s staged interest with candidate&apos;s Secondary Business Offers.</p>
              </div>

              <div
                style={{
                  background: 'var(--bg-elevated)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-sm)',
                  padding: '0.75rem',
                }}
              >
                <div className="font-bold text-sm text-primary mb-1">Competitor Exclusion Safeguard</div>
                <p>If two users share the same Primary Offer/Niche, matching is strictly prohibited to prevent competitor collision.</p>
              </div>

              <div
                style={{
                  background: 'var(--bg-elevated)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-sm)',
                  padding: '0.75rem',
                }}
              >
                <div className="font-bold text-sm text-primary mb-1">Atomic Reciprocal Contact Ledger</div>
                <p>When A receives B as a gained contact, B receives A atomically to ensure mutual WhatsApp status visibility.</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* SECTION 2: CYCLE USER OUTCOMES TABLE */}
      {activeSection === 'outcomes' && (
        <div className="card fade-up">
          <div className="card-header flex justify-between items-center">
            <span className="card-title">
              <Hugeicon name="users" size={16} state="active" />
              Cycle User Outcomes
            </span>

            <div className="flex items-center gap-3">
              <div className="search-bar" style={{ width: 220 }}>
                <Hugeicon name="search" size={14} variant="muted" />
                <input
                  type="text"
                  placeholder="Search user name, phone…"
                  value={outcomeSearch}
                  onChange={(e) => setOutcomeSearch(e.target.value)}
                />
              </div>

              <select
                className="form-control text-xs"
                style={{ width: 150, padding: '0.3rem 0.5rem' }}
                value={outcomeFilter}
                onChange={(e) => setOutcomeFilter(e.target.value)}
              >
                <option value="all">All Outcomes</option>
                <option value="filled">Target Met</option>
                <option value="underfilled">Below Target</option>
                <option value="zero_matches">Zero Matches</option>
              </select>
            </div>
          </div>

          {userOutcomes.length === 0 ? (
            <GlobalEmptyState
              icon="users"
              title="No User Outcomes Found"
              description="No user outcomes match your current search or filter."
            />
          ) : (
            <div className="table-wrap">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>User Identity</th>
                    <th>Primary Offer</th>
                    <th>10% Target</th>
                    <th>Gained</th>
                    <th>Outcome Status</th>
                    <th>Sync Status</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {userOutcomes.map((u) => (
                    <tr key={u.id}>
                      <td>
                        <div className="font-bold text-sm">{u.full_name}</div>
                        <div className="text-xs text-tertiary font-mono">{u.phone_number || u.business_name}</div>
                      </td>
                      <td className="text-xs text-secondary">{u.primary_offer}</td>
                      <td className="font-mono text-sm">{u.target_count}</td>
                      <td className="font-mono text-sm font-bold">{u.allocated_count}</td>
                      <td>
                        <span
                          className={`badge ${
                            u.outcome_status === 'Target Met'
                              ? 'badge-green'
                              : u.outcome_status === 'Below Target'
                              ? 'badge-yellow'
                              : 'badge-red'
                          }`}
                        >
                          {u.outcome_status}
                        </span>
                      </td>
                      <td>
                        <span className={`badge ${u.sync_status === 'SYNCED' ? 'badge-blue' : 'badge-gray'}`}>
                          {u.sync_status || 'PENDING_SYNC'}
                        </span>
                      </td>
                      <td>
                        <button
                          type="button"
                          className="btn btn-xs btn-secondary"
                          onClick={() => setInspectingUserId(u.user_id)}
                        >
                          Inspect
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* SECTION 3: WEEKLY CYCLE HISTORY */}
      {activeSection === 'history' && (
        <div className="card fade-up">
          <div className="card-header flex justify-between items-center">
            <span className="card-title">
              <Hugeicon name="history" size={16} state="active" />
              Weekly Cycle History
            </span>
          </div>

          {cycles.length === 0 ? (
            <GlobalEmptyState
              icon="history"
              title="No Cycle History Available"
              description="No weekly Contact Gain cycles have executed yet."
            />
          ) : (
            <div className="table-wrap">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Cycle #</th>
                    <th>Batch Date</th>
                    <th>Status</th>
                    <th>Network Size</th>
                    <th>Target / User</th>
                    <th>Total Allocations</th>
                    <th>Tier Breakdown (T1 / T2 / T3)</th>
                    <th>Executed At</th>
                  </tr>
                </thead>
                <tbody>
                  {cycles.map((c) => (
                    <tr key={c.id}>
                      <td className="font-bold font-mono text-sm">#{c.cycle_number}</td>
                      <td className="text-sm">{new Date(c.batch_date).toLocaleDateString('en-GB')}</td>
                      <td>
                        <span
                          className={`badge ${
                            c.status === 'COMPLETED' ? 'badge-green' : c.status === 'FAILED' ? 'badge-red' : 'badge-yellow'
                          }`}
                        >
                          {c.status}
                        </span>
                      </td>
                      <td className="font-mono text-sm">{c.network_size}</td>
                      <td className="font-mono text-sm">{c.target_per_user}</td>
                      <td className="font-mono text-sm font-bold">{c.total_allocations}</td>
                      <td className="text-xs text-secondary font-mono">
                        {c.tier_1_count} / {c.tier_2_count} / {c.tier_3_count}
                      </td>
                      <td className="text-xs text-tertiary">
                        {new Date(c.created_at).toLocaleString('en-GB', {
                          day: 'numeric',
                          month: 'short',
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
