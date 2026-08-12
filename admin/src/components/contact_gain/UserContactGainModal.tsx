import React, { useEffect, useState } from 'react';
import { adminAuthApi, GainedContactItem } from '../../api/adminAuthApi';
import { Hugeicon } from '../common/Hugeicon';
import { GlobalLoadingState } from '../common/GlobalLoadingState';

interface UserContactGainModalProps {
  userId: string;
  onClose: () => void;
}

export const UserContactGainModal: React.FC<UserContactGainModalProps> = ({ userId, onClose }) => {
  const [loading, setLoading] = useState<boolean>(true);
  const [userData, setUserData] = useState<any>(null);
  const [capacity, setCapacity] = useState<any>(null);
  const [gainedContacts, setGainedContacts] = useState<GainedContactItem[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    adminAuthApi
      .getUserContactGainDetail(userId)
      .then((res) => {
        setUserData(res.user);
        setCapacity(res.capacity);
        setGainedContacts(res.gained_contacts || []);
      })
      .catch((err) => {
        console.error('Failed to load user contact gain details:', err);
        setError(err.message || 'Failed to load user contact gain details.');
      })
      .finally(() => setLoading(false));
  }, [userId]);

  return (
    <div className="modal-backdrop" onClick={onClose} role="dialog" aria-modal="true">
      <div className="modal fade-up" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 640 }}>
        <div className="modal-header">
          <span className="modal-title flex items-center gap-2">
            <Hugeicon name="contacts" size={18} state="active" />
            Contact Gain Inspection: {userData?.full_name || 'User'}
          </span>
          <button type="button" className="modal-close" onClick={onClose} aria-label="Close dialog">
            <Hugeicon name="close" size={14} />
          </button>
        </div>

        <div className="modal-body flex flex-col gap-4">
          {loading ? (
            <GlobalLoadingState message="Fetching user Contact Gain history & reciprocal status…" />
          ) : error ? (
            <div className="alert alert-error">
              <Hugeicon name="error" state="error" size={16} />
              <span>{error}</span>
            </div>
          ) : (
            <>
              {/* Capacity Summary */}
              <div className="grid-3 gap-3">
                <div className="metric-card">
                  <div className="metric-label">Network Population</div>
                  <div className="metric-value text-base">{capacity?.network_size}</div>
                </div>
                <div className="metric-card">
                  <div className="metric-label">10% Weekly Target</div>
                  <div className="metric-value text-base font-mono">{capacity?.minimum_target_10_pct}</div>
                </div>
                <div className="metric-card">
                  <div className="metric-label">Total Contacts Gained</div>
                  <div className="metric-value text-base font-mono" style={{ color: 'var(--brand-green)' }}>
                    {capacity?.contacts_gained_total}
                  </div>
                </div>
              </div>

              {/* Gained Contacts List */}
              <div>
                <div className="text-xs text-secondary font-bold uppercase mb-2">
                  Gained Contacts & Reciprocal Verification
                </div>

                {gainedContacts.length === 0 ? (
                  <div className="text-center p-6 text-secondary text-xs">
                    No contacts have been gained by this user yet.
                  </div>
                ) : (
                  <div className="flex flex-col gap-2 max-h-80 overflow-y-auto">
                    {gainedContacts.map((c) => (
                      <div
                        key={c.relationship_id}
                        style={{
                          background: 'var(--bg-elevated)',
                          border: '1px solid var(--border)',
                          borderRadius: 'var(--radius-sm)',
                          padding: '0.75rem',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          gap: '0.75rem',
                        }}
                      >
                        <div className="flex items-center gap-3">
                          <div
                            style={{
                              width: 36,
                              height: 36,
                              borderRadius: '50%',
                              background: 'linear-gradient(135deg, var(--brand-blue), var(--brand-green))',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              color: '#fff',
                              fontWeight: 800,
                              fontSize: 14,
                              flexShrink: 0,
                            }}
                          >
                            {c.partner_name.charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <div className="font-bold text-sm">{c.partner_name}</div>
                            <div className="text-xs text-secondary">{c.partner_business || c.partner_primary_offer}</div>
                            <div className="text-xs text-tertiary mt-0.5">
                              Reason: {c.match_reason || 'Matching supply profile'}
                            </div>
                          </div>
                        </div>

                        <div className="flex flex-col items-end gap-1">
                          {c.is_reciprocal_verified ? (
                            <span className="badge badge-green flex items-center gap-1 text-xs">
                              <Hugeicon name="check" size={10} />
                              Reciprocal Verified (A ↔ B)
                            </span>
                          ) : (
                            <span className="badge badge-yellow text-xs">Unidirectional</span>
                          )}

                          <span className={`badge ${c.sync_status === 'SYNCED' ? 'badge-blue' : 'badge-gray'} text-xs`}>
                            Sync: {c.sync_status}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </>
          )}
        </div>

        <div className="modal-footer">
          <button type="button" className="btn btn-secondary" onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
};
