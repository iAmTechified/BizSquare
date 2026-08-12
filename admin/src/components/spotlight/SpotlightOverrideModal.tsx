import React, { useEffect, useState } from 'react';
import { adminAuthApi, UpcomingSpotlightUser, AdminSpotlightTurnItem } from '../../api/adminAuthApi';
import { Hugeicon } from '../common/Hugeicon';
import { useToast } from '../../context/ToastContext';

interface SpotlightOverrideModalProps {
  currentTurn: AdminSpotlightTurnItem | null;
  onClose: () => void;
  onSuccess: () => void;
}

export const SpotlightOverrideModal: React.FC<SpotlightOverrideModalProps> = ({
  currentTurn,
  onClose,
  onSuccess,
}) => {
  const { showToast } = useToast();
  const [search, setSearch] = useState<string>('');
  const [eligibleUsers, setEligibleUsers] = useState<UpcomingSpotlightUser[]>([]);
  const [selectedUser, setSelectedUser] = useState<UpcomingSpotlightUser | null>(null);
  const [reason, setReason] = useState<string>('');
  const [loadingUsers, setLoadingUsers] = useState<boolean>(true);
  const [submitting, setSubmitting] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoadingUsers(true);
    adminAuthApi
      .getEligibleUsersForOverride(search)
      .then((res) => setEligibleUsers(res.users || []))
      .catch((err) => console.error('Failed to load eligible users for override:', err))
      .finally(() => setLoadingUsers(false));
  }, [search]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!selectedUser) {
      setError('Please select a replacement participant for the Spotlight turn.');
      return;
    }

    if (!reason.trim()) {
      setError('An administrative reason is required for a Spotlight turn override.');
      return;
    }

    setSubmitting(true);
    try {
      const res = await adminAuthApi.overrideSpotlightTurn(selectedUser.id, reason.trim());
      showToast({
        type: 'success',
        title: 'Spotlight Turn Overridden',
        message: res.message || `Spotlight turn assigned to ${selectedUser.full_name}.`,
      });
      onSuccess();
      onClose();
    } catch (err: any) {
      console.error('Spotlight override error:', err);
      setError(err.message || 'Failed to override Spotlight turn.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="modal-backdrop" onClick={onClose} role="dialog" aria-modal="true">
      <div className="modal fade-up" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 520 }}>
        <div className="modal-header">
          <span className="modal-title flex items-center gap-2">
            <Hugeicon name="spotlight" size={18} state="warning" />
            Override Spotlight Turn
          </span>
          <button type="button" className="modal-close" onClick={onClose} disabled={submitting} aria-label="Close dialog">
            <Hugeicon name="close" size={14} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body flex flex-col gap-4">
            <div className="alert alert-warning">
              <Hugeicon name="warning" state="warning" size={16} />
              <span>
                <strong>Administrative Override:</strong> This action will bypass normal turn sequencing, deactivate the current active campaign, and immediately assign the Spotlight turn to the selected user.
              </span>
            </div>

            {/* Current vs Proposed Comparison */}
            <div className="grid-2">
              <div
                style={{
                  background: 'var(--bg-elevated)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-md)',
                  padding: '0.75rem',
                }}
              >
                <div className="text-xs text-secondary font-bold uppercase mb-1">Current Turn</div>
                <div className="font-bold text-sm text-primary">
                  {currentTurn ? currentTurn.full_name : 'None (Active)'}
                </div>
                {currentTurn?.business_name && (
                  <div className="text-xs text-tertiary">{currentTurn.business_name}</div>
                )}
              </div>

              <div
                style={{
                  background: 'rgba(0, 88, 255, 0.08)',
                  border: '1px solid var(--brand-blue)',
                  borderRadius: 'var(--radius-md)',
                  padding: '0.75rem',
                }}
              >
                <div className="text-xs text-secondary font-bold uppercase mb-1">Proposed Replacement</div>
                <div className="font-bold text-sm" style={{ color: 'var(--brand-blue)' }}>
                  {selectedUser ? selectedUser.full_name : 'Select user below…'}
                </div>
                {selectedUser?.business_name && (
                  <div className="text-xs text-secondary">{selectedUser.business_name}</div>
                )}
              </div>
            </div>

            {/* Searchable User Selector */}
            <div className="form-group">
              <label className="form-label">Search Replacement User</label>
              <div className="search-bar mb-2">
                <Hugeicon name="search" size={14} variant="muted" />
                <input
                  type="text"
                  placeholder="Search user by name, phone, business…"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  disabled={submitting}
                />
              </div>

              {loadingUsers ? (
                <div className="p-3 text-center text-xs text-secondary flex items-center justify-center gap-2">
                  <Hugeicon name="refresh" className="animate-spin" size={14} />
                  Searching eligible users…
                </div>
              ) : (
                <div className="flex flex-col gap-1 max-h-44 overflow-y-auto">
                  {eligibleUsers.map((u) => (
                    <div
                      key={u.id}
                      style={{
                        padding: '0.5rem 0.75rem',
                        borderRadius: 'var(--radius-sm)',
                        border: selectedUser?.id === u.id ? '1px solid var(--brand-blue)' : '1px solid var(--border)',
                        background: selectedUser?.id === u.id ? 'var(--bg-elevated)' : 'transparent',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                      onClick={() => setSelectedUser(u)}
                    >
                      <div>
                        <div className="font-bold text-sm">{u.full_name}</div>
                        <div className="text-xs text-secondary">{u.business_name || u.primary_offer}</div>
                      </div>
                      <span className={`badge ${u.is_currently_active ? 'badge-yellow' : 'badge-green'}`}>
                        {u.eligibility_status}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Reason */}
            <div className="form-group">
              <label className="form-label">Administrative Reason (Audit Record)</label>
              <textarea
                className="form-control"
                placeholder="Explain why this administrative turn override is required..."
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                required
                disabled={submitting}
                rows={3}
              />
            </div>

            {error && (
              <div className="alert alert-error">
                <Hugeicon name="error" state="error" size={16} />
                <span>{error}</span>
              </div>
            )}
          </div>

          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" onClick={onClose} disabled={submitting}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary" disabled={submitting || !selectedUser}>
              {submitting ? (
                <>
                  <Hugeicon name="refresh" className="animate-spin" size={14} />
                  Executing Override…
                </>
              ) : (
                'Override Turn'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
