import React, { useEffect, useState, useCallback } from 'react';
import { adminAuthApi, UserDetailsResponse, UserActivityItem } from '../api/adminAuthApi';
import { useAdminAuth } from '../context/AdminAuthContext';
import { useToast } from '../context/ToastContext';
import { useConfirmation } from '../context/ConfirmationContext';
import { GlobalLoadingState } from '../components/common/GlobalLoadingState';
import { GlobalErrorState } from '../components/common/GlobalErrorState';
import { Hugeicon } from '../components/common/Hugeicon';
import { AdjustPointsModal } from '../components/users/AdjustPointsModal';
import { AdminRoute } from '../components/shell/Sidebar';

interface UserDetailPageProps {
  userId: string;
  onNavigate: (route: AdminRoute) => void;
  onBack: () => void;
}

export const UserDetailPage: React.FC<UserDetailPageProps> = ({
  userId,
  onNavigate,
  onBack,
}) => {
  const { hasPermission } = useAdminAuth();
  const { showToast } = useToast();
  const { confirm } = useConfirmation();

  const canManage = hasPermission('users.manage');

  const [data, setData] = useState<UserDetailsResponse | null>(null);
  const [activity, setActivity] = useState<UserActivityItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'profile' | 'offers' | 'interests' | 'contact_gain' | 'spotlight' | 'activity'>('profile');
  const [showPointsModal, setShowPointsModal] = useState<boolean>(false);

  const fetchDetails = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [resDetails, resActivity] = await Promise.all([
        adminAuthApi.getUserDetails(userId),
        adminAuthApi.getUserActivity(userId).catch(() => ({ success: true, activity: [] })),
      ]);
      setData(resDetails);
      setActivity(resActivity.activity || []);
    } catch (err: any) {
      console.error('Failed to fetch user detail:', err);
      setError(err.message || 'Failed to load user profile from database.');
      showToast({
        type: 'error',
        title: 'User Profile Error',
        message: err.message || 'Could not query user profile details.',
      });
    } finally {
      setLoading(false);
    }
  }, [userId, showToast]);

  useEffect(() => {
    fetchDetails();
  }, [fetchDetails]);

  const handleToggleSuspend = () => {
    if (!data?.user) return;
    const user = data.user;
    const isSuspending = user.is_active;

    confirm({
      title: `${isSuspending ? 'Suspend' : 'Reinstate'} User Account`,
      description: `Are you sure you want to ${isSuspending ? 'suspend' : 'reinstate'} access for ${user.full_name} (${user.phone_number})?`,
      consequence: isSuspending
        ? 'Suspended accounts will immediately be denied administrative & mobile app access.'
        : 'Reinstated accounts will regain normal network participation rights.',
      isDestructive: isSuspending,
      confirmLabel: isSuspending ? 'Yes, Suspend Account' : 'Yes, Reinstate Account',
      onConfirm: async () => {
        const res = await adminAuthApi.suspendUserAccount(user.id, isSuspending);
        showToast({
          type: 'success',
          title: `Account ${isSuspending ? 'Suspended' : 'Reinstated'}`,
          message: res.message,
        });
        fetchDetails();
      },
    });
  };

  if (loading && !data) {
    return <GlobalLoadingState type="page" message="Loading comprehensive user profile from database…" />;
  }

  if (error || !data) {
    return (
      <GlobalErrorState
        type="page"
        title="Could Not Load User Profile"
        message={error || 'User profile not found in PostgreSQL database.'}
        onRetry={fetchDetails}
        onAction={onBack}
        actionLabel="Back to Users Registry"
      />
    );
  }

  const user = data.user;
  const offers = data.offers;
  const interests = data.interests;
  const contactGain = data.contactGain;
  const spotlight = data.spotlight;

  return (
    <div className="flex flex-col gap-6 fade-up">
      {/* Points Adjustment Modal */}
      {showPointsModal && (
        <AdjustPointsModal
          user={user}
          onClose={() => setShowPointsModal(false)}
          onSuccess={fetchDetails}
        />
      )}

      {/* Top Header Actions */}
      <div className="flex items-center justify-between">
        <button type="button" className="btn btn-secondary btn-sm" onClick={onBack}>
          <Hugeicon name="chevronLeft" size={14} />
          Back to Users Registry
        </button>

        <div className="flex items-center gap-2">
          <button
            type="button"
            className="btn btn-secondary btn-sm"
            onClick={() => {
              navigator.clipboard.writeText(user.id);
              showToast({ type: 'info', title: 'Copied', message: 'User ID copied to clipboard.' });
            }}
          >
            Copy User ID
          </button>
          <button
            type="button"
            className="btn btn-secondary btn-sm"
            onClick={() => {
              navigator.clipboard.writeText(user.phone_number);
              showToast({ type: 'info', title: 'Copied', message: 'Phone number copied to clipboard.' });
            }}
          >
            Copy Phone Number
          </button>
        </div>
      </div>

      {/* USER DETAIL HEADER CARD */}
      <div
        className="card"
        style={{
          background: 'linear-gradient(135deg, rgba(0, 88, 255, 0.08), rgba(12, 15, 24, 0.95))',
          border: '1px solid rgba(0, 88, 255, 0.25)',
          padding: '1.75rem',
        }}
      >
        <div className="flex items-start justify-between flex-wrap gap-4">
          <div className="flex items-center gap-4">
            <div
              style={{
                width: 56,
                height: 56,
                borderRadius: '50%',
                background: 'linear-gradient(135deg, var(--brand-blue), var(--brand-green))',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#fff',
                fontWeight: 800,
                fontSize: 22,
                flexShrink: 0,
              }}
            >
              {user.full_name.charAt(0).toUpperCase()}
            </div>

            <div>
              <div className="flex items-center gap-2 mb-1 flex-wrap">
                <h1 style={{ fontSize: '1.35rem', fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>
                  {user.full_name}
                </h1>
                <span className={`badge ${user.is_active ? 'badge-green' : 'badge-red'}`}>
                  {user.is_active ? '● Active Account' : '✕ Suspended'}
                </span>
                <span className={`badge ${user.onboarding_completed ? 'badge-blue' : 'badge-yellow'}`}>
                  {user.onboarding_completed ? 'Setup Complete' : 'Incomplete Setup'}
                </span>
                <span className="badge badge-gray">{user.access_level.toUpperCase()}</span>
              </div>

              <div className="text-xs text-secondary font-mono flex items-center gap-3">
                <span>Phone: <strong>{user.phone_number}</strong></span>
                {user.username && <span>Username: <strong>@{user.username}</strong></span>}
                <span>ID: <strong className="text-tertiary">{user.id}</strong></span>
              </div>
            </div>
          </div>

          {canManage && (
            <div className="flex items-center gap-2">
              <button
                type="button"
                className="btn btn-secondary btn-sm"
                onClick={() => setShowPointsModal(true)}
              >
                <Hugeicon name="audit" size={14} />
                Adjust Points ({user.akawo_points} pts)
              </button>
              <button
                type="button"
                className={`btn btn-sm ${user.is_active ? 'btn-danger' : 'btn-success'}`}
                onClick={handleToggleSuspend}
              >
                <Hugeicon name={user.is_active ? 'lock' : 'check'} size={14} />
                {user.is_active ? 'Suspend Account' : 'Reinstate Account'}
              </button>
            </div>
          )}
        </div>
      </div>

      {/* SECTION TABS */}
      <div className="tab-list">
        <button
          type="button"
          className={`tab-btn ${activeTab === 'profile' ? 'active' : ''}`}
          onClick={() => setActiveTab('profile')}
        >
          <Hugeicon name="userProfile" size={14} />
          Profile & Account
        </button>
        <button
          type="button"
          className={`tab-btn ${activeTab === 'offers' ? 'active' : ''}`}
          onClick={() => setActiveTab('offers')}
        >
          <Hugeicon name="content" size={14} />
          Offers / Supply Profile
        </button>
        <button
          type="button"
          className={`tab-btn ${activeTab === 'interests' ? 'active' : ''}`}
          onClick={() => setActiveTab('interests')}
        >
          <Hugeicon name="interests" size={14} />
          Interests & Demand
        </button>
        <button
          type="button"
          className={`tab-btn ${activeTab === 'contact_gain' ? 'active' : ''}`}
          onClick={() => setActiveTab('contact_gain')}
        >
          <Hugeicon name="contacts" size={14} />
          Contact Gain Summary
        </button>
        <button
          type="button"
          className={`tab-btn ${activeTab === 'spotlight' ? 'active' : ''}`}
          onClick={() => setActiveTab('spotlight')}
        >
          <Hugeicon name="spotlight" size={14} />
          Spotlight Summary
        </button>
        <button
          type="button"
          className={`tab-btn ${activeTab === 'activity' ? 'active' : ''}`}
          onClick={() => setActiveTab('activity')}
        >
          <Hugeicon name="audit" size={14} />
          Activity Feed ({activity.length})
        </button>
      </div>

      {/* TAB CONTENT: PROFILE & ACCOUNT */}
      {activeTab === 'profile' && (
        <div className="grid-2 fade-up">
          <div className="card">
            <div className="card-header">
              <span className="card-title">
                <Hugeicon name="userProfile" size={16} state="active" />
                Profile Identity Metadata
              </span>
            </div>
            <div className="card-body flex flex-col gap-3">
              <div className="flex justify-between items-center text-sm">
                <span className="text-secondary">Full Name:</span>
                <span className="font-bold">{user.full_name}</span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-secondary">Phone Number:</span>
                <span className="font-mono font-bold">{user.phone_number}</span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-secondary">Username:</span>
                <span className="font-mono">{user.username || 'Not set'}</span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-secondary">Business Name:</span>
                <span className="font-bold">{user.business_name || 'Not provided'}</span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-secondary">Verification Status:</span>
                <span className="badge badge-gray">{user.verification_status.toUpperCase()}</span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-secondary">Onboarding Status:</span>
                <span className={`badge ${user.onboarding_completed ? 'badge-green' : 'badge-yellow'}`}>
                  {user.onboarding_completed ? 'Completed' : 'Incomplete'}
                </span>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="card-header">
              <span className="card-title">
                <Hugeicon name="lock" size={16} state="active" />
                Account Timestamps & Points
              </span>
            </div>
            <div className="card-body flex flex-col gap-3">
              <div className="flex justify-between items-center text-sm">
                <span className="text-secondary">Akawo Points Balance:</span>
                <span className="font-bold text-lg" style={{ color: 'var(--warning)' }}>
                  {user.akawo_points.toLocaleString()} pts
                </span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-secondary">Access Level:</span>
                <span className="badge badge-blue">{user.access_level}</span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-secondary">Registration Date:</span>
                <span className="font-mono">
                  {new Date(user.created_at).toLocaleString('en-GB', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-secondary">Last Active Timestamp:</span>
                <span className="font-mono text-secondary">
                  {user.last_login
                    ? new Date(user.last_login).toLocaleString('en-GB', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                      })
                    : 'Never logged in'}
                </span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB CONTENT: OFFERS & SUPPLY */}
      {activeTab === 'offers' && (
        <div className="flex flex-col gap-4 fade-up">
          {/* PRIMARY OFFER / NICHE CARD */}
          <div className="card" style={{ borderLeft: '4px solid var(--brand-blue)' }}>
            <div className="card-header">
              <span className="card-title">
                <Hugeicon name="content" size={16} state="active" />
                PRIMARY OFFER / NICHE
              </span>
              <span className="badge badge-blue">Matching Anchor</span>
            </div>
            <div className="card-body">
              {offers.primary ? (
                <div>
                  <div style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-primary)' }}>
                    {offers.primary.micro_niche_name}
                  </div>
                  {offers.primary.category_name && (
                    <div className="text-xs text-secondary mt-1">
                      Category: {offers.primary.category_name}
                    </div>
                  )}
                  <p className="text-xs text-tertiary mt-2">
                    This primary offer is used by the Contact Gain matching engine to calculate reciprocal niche collisions.
                  </p>
                </div>
              ) : (
                <div className="text-secondary text-sm">Not provided / No primary micro-niche set.</div>
              )}
            </div>
          </div>

          {/* SECONDARY OFFERS / NICHES CARD */}
          <div className="card">
            <div className="card-header">
              <span className="card-title">
                <Hugeicon name="content" size={16} />
                SECONDARY OFFERS / NICHES ({offers.secondary.length})
              </span>
            </div>
            <div className="card-body">
              {offers.secondary.length === 0 ? (
                <div className="text-secondary text-sm">No secondary offers declared.</div>
              ) : (
                <div className="grid-3">
                  {offers.secondary.map((sec, i) => (
                    <div
                      key={i}
                      style={{
                        background: 'var(--bg-elevated)',
                        border: '1px solid var(--border)',
                        borderRadius: 'var(--radius-sm)',
                        padding: '0.75rem',
                      }}
                    >
                      <div className="font-bold text-sm">{sec.micro_niche_name}</div>
                      {sec.category_name && <div className="text-xs text-tertiary">{sec.category_name}</div>}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* TAB CONTENT: INTERESTS & DEMAND */}
      {activeTab === 'interests' && (
        <div className="grid-2 fade-up">
          {/* BASELINE INTERESTS */}
          <div className="card">
            <div className="card-header">
              <span className="card-title">
                <Hugeicon name="interests" size={16} />
                Baseline Interests ({interests.baseline.length})
              </span>
            </div>
            <div className="card-body">
              {interests.baseline.length === 0 ? (
                <div className="text-secondary text-sm">No baseline interests declared.</div>
              ) : (
                <div className="flex flex-col gap-2">
                  {interests.baseline.map((item, i) => (
                    <div
                      key={i}
                      style={{
                        background: 'var(--bg-elevated)',
                        border: '1px solid var(--border)',
                        borderRadius: 'var(--radius-sm)',
                        padding: '0.5rem 0.75rem',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <span className="font-bold text-sm">{item.interest_name}</span>
                      <span className="badge badge-gray font-mono">{item.slug}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* DYNAMIC INTEREST GRAPH */}
          <div className="card">
            <div className="card-header">
              <span className="card-title">
                <Hugeicon name="interests" size={16} state="active" />
                Dynamic Interest Graph ({interests.dynamic.length})
              </span>
            </div>
            <div className="card-body">
              {interests.dynamic.length === 0 ? (
                <div className="text-secondary text-sm">No dynamic interest state recorded yet.</div>
              ) : (
                <div className="flex flex-col gap-2">
                  {interests.dynamic.map((item, i) => (
                    <div
                      key={i}
                      style={{
                        background: 'var(--bg-elevated)',
                        border: '1px solid var(--border)',
                        borderRadius: 'var(--radius-sm)',
                        padding: '0.5rem 0.75rem',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <div>
                        <div className="font-bold text-sm">{item.interest_name}</div>
                        <div className="text-xs text-tertiary">Decay Factor: {item.recency_decay_factor}</div>
                      </div>
                      <span className="font-mono font-bold" style={{ color: 'var(--brand-blue)' }}>
                        Score: {item.score}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* TAB CONTENT: CONTACT GAIN SUMMARY */}
      {activeTab === 'contact_gain' && (
        <div className="card fade-up">
          <div className="card-header">
            <span className="card-title">
              <Hugeicon name="contacts" size={16} state="active" />
              Contact Gain Summary (Inspection Only)
            </span>
            <span className={`badge ${contactGain.last_sync_status === 'SYNCED' ? 'badge-green' : 'badge-yellow'}`}>
              {contactGain.last_sync_status}
            </span>
          </div>
          <div className="card-body flex flex-col gap-3">
            <div className="flex justify-between items-center text-sm">
              <span className="text-secondary">Network Contacts Gained:</span>
              <span className="font-bold text-base">{contactGain.contacts_count} contacts</span>
            </div>
            <div className="flex justify-between items-center text-sm">
              <span className="text-secondary">Pending Sync Records:</span>
              <span className="font-bold">{contactGain.pending_sync_count}</span>
            </div>
            <div className="flex justify-between items-center text-sm">
              <span className="text-secondary">Sync Failure Count:</span>
              <span className={`font-bold ${contactGain.failed_sync_count > 0 ? 'text-danger' : ''}`}>
                {contactGain.failed_sync_count}
              </span>
            </div>
          </div>
        </div>
      )}

      {/* TAB CONTENT: SPOTLIGHT SUMMARY */}
      {activeTab === 'spotlight' && (
        <div className="card fade-up">
          <div className="card-header">
            <span className="card-title">
              <Hugeicon name="spotlight" size={16} state="warning" />
              Spotlight Summary (Inspection Only)
            </span>
            <span className="badge badge-gray">{spotlight.submission_status}</span>
          </div>
          <div className="card-body flex flex-col gap-3">
            {spotlight.active_campaign ? (
              <>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-secondary">Active Business Campaign:</span>
                  <span className="font-bold">{spotlight.active_campaign.business_name}</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-secondary">Campaign Title:</span>
                  <span className="font-bold">{spotlight.active_campaign.title}</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-secondary">Participants Count:</span>
                  <span className="font-bold">{spotlight.active_campaign.participants_count}</span>
                </div>
              </>
            ) : (
              <div className="text-secondary text-sm">No Spotlight campaigns recorded for this user.</div>
            )}
          </div>
        </div>
      )}

      {/* TAB CONTENT: ACTIVITY TIMELINE */}
      {activeTab === 'activity' && (
        <div className="card fade-up">
          <div className="card-header">
            <span className="card-title">
              <Hugeicon name="audit" size={16} state="active" />
              Real Activity Timeline ({activity.length})
            </span>
          </div>

          {activity.length === 0 ? (
            <div className="text-secondary text-sm p-6 text-center">
              No audit or operational activity recorded for this user yet.
            </div>
          ) : (
            <div className="table-wrap">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Timestamp</th>
                    <th>Action</th>
                    <th>Source</th>
                    <th>Result</th>
                  </tr>
                </thead>
                <tbody>
                  {activity.map((act) => (
                    <tr key={act.id}>
                      <td className="text-xs font-mono text-secondary">
                        {new Date(act.created_at).toLocaleString('en-GB', {
                          day: 'numeric',
                          month: 'short',
                          year: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </td>
                      <td>
                        <span className="badge badge-blue font-mono">{act.action}</span>
                      </td>
                      <td className="text-xs">{act.event_source}</td>
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
      )}
    </div>
  );
};
