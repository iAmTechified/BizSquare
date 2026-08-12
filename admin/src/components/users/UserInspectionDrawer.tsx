import React, { useEffect, useState } from 'react';
import { adminAuthApi, UserDetailsResponse, AdminUserListItem } from '../../api/adminAuthApi';
import { Hugeicon } from '../common/Hugeicon';

interface UserInspectionDrawerProps {
  user: AdminUserListItem;
  onClose: () => void;
  onOpenPointsModal: (user: AdminUserListItem) => void;
  onToggleSuspend: (user: AdminUserListItem) => void;
  canManageUsers: boolean;
}

export const UserInspectionDrawer: React.FC<UserInspectionDrawerProps> = ({
  user,
  onClose,
  onOpenPointsModal,
  onToggleSuspend,
  canManageUsers,
}) => {
  const [details, setDetails] = useState<UserDetailsResponse | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [activeTab, setActiveTab] = useState<'profile' | 'ledger'>('profile');

  useEffect(() => {
    setLoading(true);
    adminAuthApi
      .getUserDetails(user.id)
      .then((res) => setDetails(res))
      .catch((err) => console.error('Failed to load user details:', err))
      .finally(() => setLoading(false));
  }, [user.id]);

  const activeUser = details?.user || user;

  return (
    <div className="modal-backdrop" onClick={onClose} role="dialog" aria-modal="true">
      <div
        className="modal fade-up"
        style={{
          maxWidth: 580,
          marginRight: 0,
          marginLeft: 'auto',
          height: '100vh',
          maxHeight: '100vh',
          borderRadius: 'var(--radius-xl) 0 0 var(--radius-xl)',
          display: 'flex',
          flexDirection: 'column',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Drawer Header */}
        <div className="modal-header">
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
              {activeUser.full_name.charAt(0).toUpperCase()}
            </div>
            <div>
              <div className="font-bold text-base flex items-center gap-2">
                {activeUser.full_name}
                <span className={`badge ${activeUser.is_active ? 'badge-green' : 'badge-red'}`}>
                  {activeUser.is_active ? '● Active' : '✕ Suspended'}
                </span>
              </div>
              <div className="text-xs text-tertiary font-mono">{activeUser.id}</div>
            </div>
          </div>

          <button type="button" className="modal-close" onClick={onClose} aria-label="Close drawer">
            <Hugeicon name="close" size={14} />
          </button>
        </div>

        {/* Tab Selection Header */}
        <div style={{ padding: '0.75rem 1.5rem', borderBottom: '1px solid var(--border)', background: 'var(--bg-elevated)' }}>
          <div className="tab-list">
            <button
              type="button"
              className={`tab-btn ${activeTab === 'profile' ? 'active' : ''}`}
              onClick={() => setActiveTab('profile')}
            >
              <Hugeicon name="userProfile" size={14} />
              Profile Details
            </button>
            <button
              type="button"
              className={`tab-btn ${activeTab === 'ledger' ? 'active' : ''}`}
              onClick={() => setActiveTab('ledger')}
            >
              <Hugeicon name="audit" size={14} />
              Akawo Ledger History ({details?.points_history.length || 0})
            </button>
          </div>
        </div>

        {/* Drawer Body */}
        <div className="modal-body flex-1 overflow-y-auto" style={{ padding: '1.5rem' }}>
          {activeTab === 'profile' ? (
            <div className="flex flex-col gap-4">
              {/* Key Metrics Row */}
              <div className="grid-2">
                <div
                  style={{
                    background: 'var(--bg-elevated)',
                    border: '1px solid var(--border)',
                    borderRadius: 'var(--radius-md)',
                    padding: '1rem',
                  }}
                >
                  <div className="text-xs text-secondary font-bold uppercase mb-1">Akawo Points</div>
                  <div className="text-2xl font-bold" style={{ color: 'var(--warning)' }}>
                    {activeUser.akawo_points.toLocaleString()} pts
                  </div>
                </div>

                <div
                  style={{
                    background: 'var(--bg-elevated)',
                    border: '1px solid var(--border)',
                    borderRadius: 'var(--radius-md)',
                    padding: '1rem',
                  }}
                >
                  <div className="text-xs text-secondary font-bold uppercase mb-1">Access Level</div>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="badge badge-blue">{activeUser.access_level.toUpperCase()}</span>
                  </div>
                </div>
              </div>

              {/* Profile Details List */}
              <div className="card" style={{ padding: '1rem 1.25rem' }}>
                <div className="flex flex-col gap-3">
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-secondary">Phone Number:</span>
                    <span className="font-mono font-bold">{activeUser.phone_number}</span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-secondary">Registration Date:</span>
                    <span className="text-sm">
                      {new Date(activeUser.created_at).toLocaleString('en-GB', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                      })}
                    </span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-secondary">Last Login Timestamp:</span>
                    <span className="text-sm font-mono text-secondary">
                      {activeUser.last_login
                        ? new Date(activeUser.last_login).toLocaleString('en-GB', {
                            day: 'numeric',
                            month: 'short',
                            year: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit',
                          })
                        : 'Never logged in'}
                    </span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-secondary">Network Contacts Count:</span>
                    <span className="font-bold">{details?.metrics.contacts_count || 0} contacts</span>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="flex flex-col gap-3">
              {loading ? (
                <div className="p-4 text-center text-secondary text-sm flex items-center justify-center gap-2">
                  <Hugeicon name="refresh" className="animate-spin" size={16} />
                  Loading ledger history...
                </div>
              ) : details?.points_history.length === 0 ? (
                <div className="text-center p-6 text-secondary text-sm">
                  No points ledger transactions recorded for this user.
                </div>
              ) : (
                <div className="table-wrap">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Date</th>
                        <th>Type / Reason</th>
                        <th>Points</th>
                      </tr>
                    </thead>
                    <tbody>
                      {details?.points_history.map((tx) => (
                        <tr key={tx.id}>
                          <td className="text-xs font-mono text-secondary">
                            {new Date(tx.created_at).toLocaleDateString('en-GB', {
                              day: 'numeric',
                              month: 'short',
                              hour: '2-digit',
                              minute: '2-digit',
                            })}
                          </td>
                          <td className="text-xs">{tx.transaction_type}</td>
                          <td className="font-mono font-bold">
                            <span style={{ color: tx.points_awarded >= 0 ? 'var(--success)' : 'var(--danger)' }}>
                              {tx.points_awarded >= 0 ? '+' : ''}
                              {tx.points_awarded}
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

        {/* Drawer Footer Actions */}
        {canManageUsers && (
          <div className="modal-footer" style={{ background: 'var(--bg-elevated)' }}>
            <button
              type="button"
              className="btn btn-secondary"
              onClick={() => onOpenPointsModal(activeUser)}
            >
              <Hugeicon name="audit" size={14} />
              Adjust Points
            </button>
            <button
              type="button"
              className={`btn ${activeUser.is_active ? 'btn-danger' : 'btn-success'}`}
              onClick={() => onToggleSuspend(activeUser)}
            >
              <Hugeicon name={activeUser.is_active ? 'lock' : 'check'} size={14} />
              {activeUser.is_active ? 'Suspend Account' : 'Reinstate Account'}
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
