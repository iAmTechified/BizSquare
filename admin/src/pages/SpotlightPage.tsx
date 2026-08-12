import React, { useEffect, useState, useCallback } from 'react';
import {
  adminAuthApi,
  AdminSpotlightTurnItem,
  UpcomingSpotlightUser,
} from '../api/adminAuthApi';
import { useAdminAuth } from '../context/AdminAuthContext';
import { useToast } from '../context/ToastContext';
import { useConfirmation } from '../context/ConfirmationContext';
import { GlobalLoadingState } from '../components/common/GlobalLoadingState';
import { GlobalErrorState } from '../components/common/GlobalErrorState';
import { GlobalEmptyState } from '../components/common/GlobalEmptyState';
import { Hugeicon } from '../components/common/Hugeicon';
import { SpotlightOverrideModal } from '../components/spotlight/SpotlightOverrideModal';
import { DisapproveSubmissionModal } from '../components/spotlight/DisapproveSubmissionModal';
import { MediaInspectionCard } from '../components/media/MediaInspectionCard';

export const SpotlightPage: React.FC = () => {
  const { hasPermission } = useAdminAuth();
  const { showToast } = useToast();
  const { confirm } = useConfirmation();

  const canModerate = hasPermission('spotlight.moderate');
  const canOverride = hasPermission('spotlight.override');

  const [currentTurn, setCurrentTurn] = useState<AdminSpotlightTurnItem | null>(null);
  const [upcoming, setUpcoming] = useState<UpcomingSpotlightUser[]>([]);
  const [submissions, setSubmissions] = useState<AdminSpotlightTurnItem[]>([]);
  const [history, setHistory] = useState<AdminSpotlightTurnItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Modals state
  const [showOverrideModal, setShowOverrideModal] = useState<boolean>(false);
  const [disapproveSubmission, setDisapproveSubmission] = useState<AdminSpotlightTurnItem | null>(null);

  // Tabs state
  const [activeSection, setActiveSection] = useState<'overview' | 'submissions' | 'history'>('overview');
  const [historySearch, setHistorySearch] = useState<string>('');
  const [historyFilter, setHistoryFilter] = useState<string>('all');

  const fetchSpotlightData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [resCurrent, resUpcoming, resSubmissions, resHistory] = await Promise.all([
        adminAuthApi.getCurrentSpotlightTurn(),
        adminAuthApi.getUpcomingSpotlightQueue().catch(() => ({ success: true, upcoming: [] })),
        adminAuthApi.getSpotlightSubmissions('pending_review', 10, 0).catch(() => ({ success: true, submissions: [] })),
        adminAuthApi.getSpotlightHistory({ search: historySearch, status: historyFilter, limit: 20, offset: 0 }).catch(() => ({ success: true, history: [] })),
      ]);

      setCurrentTurn(resCurrent.current_turn);
      setUpcoming(resUpcoming.upcoming || []);
      setSubmissions(resSubmissions.submissions || []);
      setHistory(resHistory.history || []);
    } catch (err: any) {
      console.error('Failed to fetch spotlight operations data:', err);
      setError(err.message || 'Failed to query Spotlight data from database.');
      showToast({
        type: 'error',
        title: 'Spotlight Query Error',
        message: err.message || 'Could not query Spotlight turn state.',
      });
    } finally {
      setLoading(false);
    }
  }, [historySearch, historyFilter, showToast]);

  useEffect(() => {
    fetchSpotlightData();
  }, [fetchSpotlightData]);

  const handleApproveSubmission = (sub: AdminSpotlightTurnItem) => {
    confirm({
      title: `Approve Spotlight: "${sub.title}"`,
      description: `Are you sure you want to approve this Spotlight submission by ${sub.full_name}?`,
      consequence: 'The approved Spotlight content will immediately become active in the mobile user experience.',
      isDestructive: false,
      confirmLabel: 'Approve Submission',
      onConfirm: async () => {
        const res = await adminAuthApi.approveSpotlightSubmission(sub.id);
        showToast({ type: 'success', title: 'Submission Approved', message: res.message });
        fetchSpotlightData();
      },
    });
  };

  const handleStopSpotlight = (sub: AdminSpotlightTurnItem) => {
    confirm({
      title: `Stop Active Spotlight: "${sub.title}"`,
      description: `Are you sure you want to stop this active Spotlight campaign for ${sub.full_name}?`,
      consequence: 'This will immediately remove the Spotlight from the active user experience. Users will no longer see this content.',
      isDestructive: true,
      confirmLabel: 'Yes, Stop Spotlight',
      onConfirm: async () => {
        const res = await adminAuthApi.stopSpotlightCampaign(sub.id, 'Administrative stop');
        showToast({ type: 'success', title: 'Spotlight Stopped', message: res.message });
        fetchSpotlightData();
      },
    });
  };

  if (loading && !currentTurn && submissions.length === 0 && history.length === 0) {
    return <GlobalLoadingState type="page" message="Querying authoritative Spotlight engine state…" />;
  }

  if (error && !currentTurn) {
    return (
      <GlobalErrorState
        type="page"
        title="Could Not Load Spotlight Operations"
        message={error}
        onRetry={fetchSpotlightData}
      />
    );
  }

  return (
    <div className="flex flex-col gap-6 fade-up">
      {/* Override Modal */}
      {showOverrideModal && (
        <SpotlightOverrideModal
          currentTurn={currentTurn}
          onClose={() => setShowOverrideModal(false)}
          onSuccess={fetchSpotlightData}
        />
      )}

      {/* Disapprove Modal */}
      {disapproveSubmission && (
        <DisapproveSubmissionModal
          submission={disapproveSubmission}
          onClose={() => setDisapproveSubmission(null)}
          onSuccess={fetchSpotlightData}
        />
      )}

      {/* Page Header */}
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">Spotlight Operations</h1>
          <p className="page-subtitle">Manage Spotlight participation, reviews and turn scheduling.</p>
        </div>

        <div className="flex items-center gap-2">
          {canOverride && (
            <button
              type="button"
              className="btn btn-secondary"
              onClick={() => setShowOverrideModal(true)}
            >
              <Hugeicon name="spotlight" size={14} />
              Override Turn
            </button>
          )}

          <button type="button" className="btn btn-secondary" onClick={fetchSpotlightData}>
            <Hugeicon name="refresh" className={loading ? 'animate-spin' : ''} size={14} />
            Refresh
          </button>
        </div>
      </div>

      {/* VISUAL PRIORITY HERO CARD: WHOSE TURN IS IT? */}
      <div
        className="card"
        style={{
          background: 'linear-gradient(135deg, rgba(255, 0, 166, 0.08), rgba(12, 15, 24, 0.95))',
          border: '1px solid rgba(255, 0, 166, 0.3)',
          padding: '1.75rem',
        }}
      >
        <div className="flex items-center justify-between flex-wrap gap-4 mb-4">
          <div className="flex items-center gap-2">
            <Hugeicon name="spotlight" size={20} state="warning" />
            <span style={{ fontSize: '0.85rem', fontWeight: 800, letterSpacing: '1px', textTransform: 'uppercase', color: 'var(--brand-pink)' }}>
              CURRENT SPOTLIGHT TURN
            </span>
            {currentTurn?.is_override && (
              <span className="badge badge-yellow">● Administrative Override</span>
            )}
          </div>

          {currentTurn && (
            <span className={`badge ${currentTurn.is_active ? 'badge-green' : 'badge-gray'}`}>
              {currentTurn.turn_status_label || currentTurn.status}
            </span>
          )}
        </div>

        {currentTurn ? (
          <div className="grid-2 gap-6 items-center">
            {/* Turn Owner Identity */}
            <div className="flex items-center gap-4">
              <div
                style={{
                  width: 64,
                  height: 64,
                  borderRadius: '50%',
                  background: 'linear-gradient(135deg, var(--brand-pink), var(--brand-blue))',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#fff',
                  fontWeight: 800,
                  fontSize: 24,
                  flexShrink: 0,
                }}
              >
                {currentTurn.full_name.charAt(0).toUpperCase()}
              </div>

              <div>
                <h2 style={{ fontSize: '1.4rem', fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>
                  {currentTurn.full_name}
                </h2>
                <div className="text-sm font-bold" style={{ color: 'var(--brand-blue)' }}>
                  {currentTurn.business_name || currentTurn.primary_offer}
                </div>
                <div className="text-xs text-tertiary font-mono mt-1">
                  Phone: {currentTurn.phone_number || 'N/A'} • Participants: {currentTurn.participant_count} shared
                </div>
              </div>
            </div>

            {/* Campaign Content Preview */}
            <div
              style={{
                background: 'var(--bg-elevated)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-md)',
                padding: '1rem',
              }}
            >
              <div className="text-xs text-secondary font-bold uppercase mb-1">Campaign Title</div>
              <div className="font-bold text-sm mb-1">{currentTurn.title}</div>
              <p className="text-xs text-tertiary line-clamp-2 mb-2">{currentTurn.promo_text}</p>
              <div className="flex items-center justify-between text-xs text-secondary pt-2" style={{ borderTop: '1px solid var(--border)' }}>
                <span>Start: {new Date(currentTurn.start_date).toLocaleDateString('en-GB')}</span>
                <span>End: {new Date(currentTurn.end_date).toLocaleDateString('en-GB')}</span>
              </div>
            </div>
          </div>
        ) : (
          <div className="p-6 text-center text-secondary text-sm">
            No Spotlight campaign is currently active in the backend database.
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
          Overview & Queue
        </button>
        <button
          type="button"
          className={`tab-btn ${activeSection === 'submissions' ? 'active' : ''}`}
          onClick={() => setActiveSection('submissions')}
        >
          <Hugeicon name="audit" size={14} />
          Moderation Queue ({submissions.length})
        </button>
        <button
          type="button"
          className={`tab-btn ${activeSection === 'history' ? 'active' : ''}`}
          onClick={() => setActiveSection('history')}
        >
          <Hugeicon name="history" size={14} />
          Spotlight History ({history.length})
        </button>
      </div>

      {/* SECTION 1: OVERVIEW & UPCOMING QUEUE */}
      {activeSection === 'overview' && (
        <div className="grid-2 fade-up">
          {/* Moderation Queue Preview */}
          <div className="card">
            <div className="card-header flex justify-between items-center">
              <span className="card-title">
                <Hugeicon name="audit" size={16} state="active" />
                Pending Moderation Reviews
                <span className="badge badge-yellow">{submissions.length}</span>
              </span>
              <button
                type="button"
                className="btn btn-xs btn-secondary"
                onClick={() => setActiveSection('submissions')}
              >
                View Queue →
              </button>
            </div>
            <div className="card-body">
              {submissions.length === 0 ? (
                <div className="text-center p-6 text-secondary text-sm">
                  You&apos;re all caught up! No pending Spotlight submissions awaiting review.
                </div>
              ) : (
                <div className="flex flex-col gap-3">
                  {submissions.slice(0, 3).map((sub) => (
                    <div
                      key={sub.id}
                      style={{
                        background: 'var(--bg-elevated)',
                        border: '1px solid var(--border)',
                        borderRadius: 'var(--radius-sm)',
                        padding: '0.85rem',
                      }}
                    >
                      <div className="flex justify-between items-start mb-1">
                        <span className="font-bold text-sm">{sub.title}</span>
                        <span className="badge badge-yellow">Pending</span>
                      </div>
                      <div className="text-xs text-secondary mb-2">Submitted by: {sub.full_name}</div>
                      {canModerate && (
                        <div className="flex items-center gap-2">
                          <button
                            type="button"
                            className="btn btn-xs btn-success"
                            onClick={() => handleApproveSubmission(sub)}
                          >
                            Approve
                          </button>
                          <button
                            type="button"
                            className="btn btn-xs btn-danger"
                            onClick={() => setDisapproveSubmission(sub)}
                          >
                            Disapprove
                          </button>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Upcoming Turn Queue */}
          <div className="card">
            <div className="card-header">
              <span className="card-title">
                <Hugeicon name="users" size={16} state="active" />
                Upcoming Spotlight Queue ({upcoming.length})
              </span>
            </div>
            <div className="card-body">
              {upcoming.length === 0 ? (
                <div className="text-center p-6 text-secondary text-sm">
                  No upcoming Spotlight turns currently scheduled in the backend queue.
                </div>
              ) : (
                <div className="flex flex-col gap-2">
                  {upcoming.map((user, i) => (
                    <div
                      key={user.id}
                      style={{
                        background: 'var(--bg-elevated)',
                        border: '1px solid var(--border)',
                        borderRadius: 'var(--radius-sm)',
                        padding: '0.6rem 0.85rem',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <div className="flex items-center gap-3">
                        <span className="font-mono text-xs text-tertiary font-bold">{i + 1}.</span>
                        <div>
                          <div className="font-bold text-sm">{user.full_name}</div>
                          <div className="text-xs text-secondary">{user.business_name || user.primary_offer}</div>
                        </div>
                      </div>

                      <span className="badge badge-gray text-xs">Eligible</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* SECTION 2: MODERATION QUEUE & SUBMISSIONS */}
      {activeSection === 'submissions' && (
        <div className="card fade-up">
          <div className="card-header flex justify-between items-center">
            <span className="card-title">
              <Hugeicon name="audit" size={16} state="active" />
              Spotlight Moderation Queue
              <span className="badge badge-yellow">{submissions.length} pending</span>
            </span>
          </div>

          {submissions.length === 0 ? (
            <GlobalEmptyState
              icon="check"
              title="No Submissions Awaiting Moderation"
              description="All Spotlight submissions have been reviewed and processed."
            />
          ) : (
            <div className="card-body flex flex-col gap-4">
              {submissions.map((sub) => (
                <div
                  key={sub.id}
                  style={{
                    background: 'var(--bg-elevated)',
                    border: '1px solid var(--border)',
                    borderRadius: 'var(--radius-md)',
                    padding: '1.25rem',
                  }}
                >
                  <div className="flex justify-between items-start flex-wrap gap-3 mb-3">
                    <div className="flex items-center gap-3">
                      <div
                        style={{
                          width: 40,
                          height: 40,
                          borderRadius: '50%',
                          background: 'linear-gradient(135deg, var(--brand-blue), var(--brand-green))',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          color: '#fff',
                          fontWeight: 800,
                          fontSize: 16,
                        }}
                      >
                        {sub.full_name.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <div className="font-bold text-base">{sub.full_name}</div>
                        <div className="text-xs text-secondary font-mono">
                          {sub.business_name || sub.primary_offer} • Phone: {sub.phone_number}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-2">
                      <span className="badge badge-yellow">{sub.submission_status}</span>
                      <span className="text-xs text-tertiary font-mono">
                        {new Date(sub.created_at).toLocaleString('en-GB', {
                          day: 'numeric',
                          month: 'short',
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </span>
                    </div>
                  </div>

                  {/* Submission Content */}
                  <div className="mb-4">
                    <div className="font-bold text-base mb-1" style={{ color: 'var(--brand-blue)' }}>
                      {sub.title}
                    </div>
                    <p className="text-sm text-primary mb-2">{sub.promo_text}</p>
                    {sub.caption && <p className="text-xs text-secondary italic mb-2">&quot;{sub.caption}&quot;</p>}

                    {/* Media Pipeline Component */}
                    <MediaInspectionCard mediaUrl={sub.flyer_url} onRefresh={fetchSpotlightData} />
                  </div>

                  {/* Actions */}
                  {canModerate && (
                    <div className="flex items-center justify-end gap-2 pt-3" style={{ borderTop: '1px solid var(--border)' }}>
                      <button
                        type="button"
                        className="btn btn-sm btn-success"
                        onClick={() => handleApproveSubmission(sub)}
                      >
                        <Hugeicon name="check" size={14} />
                        Approve Submission
                      </button>
                      <button
                        type="button"
                        className="btn btn-sm btn-secondary"
                        onClick={() => setDisapproveSubmission(sub)}
                      >
                        <Hugeicon name="error" size={14} />
                        Disapprove
                      </button>
                      <button
                        type="button"
                        className="btn btn-sm btn-danger"
                        onClick={() => handleStopSpotlight(sub)}
                      >
                        <Hugeicon name="close" size={14} />
                        Stop Spotlight
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* SECTION 3: SPOTLIGHT HISTORY */}
      {activeSection === 'history' && (
        <div className="card fade-up">
          <div className="card-header flex justify-between items-center">
            <span className="card-title">
              <Hugeicon name="history" size={16} state="active" />
              Spotlight Campaign History
            </span>

            <div className="flex items-center gap-3">
              <div className="search-bar" style={{ width: 220 }}>
                <Hugeicon name="search" size={14} variant="muted" />
                <input
                  type="text"
                  placeholder="Search history…"
                  value={historySearch}
                  onChange={(e) => setHistorySearch(e.target.value)}
                />
              </div>

              <select
                className="form-control text-xs"
                style={{ width: 140, padding: '0.3rem 0.5rem' }}
                value={historyFilter}
                onChange={(e) => setHistoryFilter(e.target.value)}
              >
                <option value="all">All Outcomes</option>
                <option value="completed">Completed</option>
                <option value="active">Active</option>
                <option value="approved">Approved</option>
                <option value="disapproved">Disapproved</option>
                <option value="stopped">Stopped</option>
              </select>
            </div>
          </div>

          {history.length === 0 ? (
            <GlobalEmptyState
              icon="history"
              title="No Spotlight History Found"
              description="No historical Spotlight campaigns match your current search or filter."
            />
          ) : (
            <div className="table-wrap">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Participant</th>
                    <th>Campaign Title</th>
                    <th>Status / Outcome</th>
                    <th>Participants Shared</th>
                    <th>Turn Dates</th>
                    <th>Created</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((h) => (
                    <tr key={h.id}>
                      <td className="font-bold text-sm">{h.full_name}</td>
                      <td className="text-sm">{h.title}</td>
                      <td>
                        <span
                          className={`badge ${
                            h.status === 'completed' || h.submission_status === 'approved' || h.submission_status === 'verified'
                              ? 'badge-green'
                              : h.status === 'stopped' || h.submission_status === 'disapproved'
                              ? 'badge-red'
                              : 'badge-yellow'
                          }`}
                        >
                          {h.status}
                        </span>
                      </td>
                      <td className="font-mono text-sm">{h.participant_count} shared</td>
                      <td className="text-xs text-secondary">
                        {new Date(h.start_date).toLocaleDateString('en-GB')} – {new Date(h.end_date).toLocaleDateString('en-GB')}
                      </td>
                      <td className="text-xs text-tertiary">
                        {new Date(h.created_at).toLocaleDateString('en-GB')}
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
