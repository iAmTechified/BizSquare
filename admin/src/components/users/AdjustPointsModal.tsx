import React, { useState } from 'react';
import { adminAuthApi, AdminUserListItem } from '../../api/adminAuthApi';
import { Hugeicon } from '../common/Hugeicon';
import { useToast } from '../../context/ToastContext';

interface AdjustPointsModalProps {
  user: AdminUserListItem;
  onClose: () => void;
  onSuccess: () => void;
}

export const AdjustPointsModal: React.FC<AdjustPointsModalProps> = ({
  user,
  onClose,
  onSuccess,
}) => {
  const { showToast } = useToast();
  const [amount, setAmount] = useState<string>('');
  const [reason, setReason] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    const pts = parseInt(amount, 10);
    if (isNaN(pts) || pts === 0) {
      setError('Please enter a non-zero integer point adjustment amount (e.g. 100 or -50).');
      return;
    }

    if (!reason.trim()) {
      setError('An administrative reason is required for points adjustment audit trail.');
      return;
    }

    setLoading(true);
    try {
      const res = await adminAuthApi.adjustUserPoints(user.id, pts, reason.trim());
      showToast({
        type: 'success',
        title: 'Points Adjusted',
        message: res.message || `Successfully adjusted points for ${user.full_name}.`,
      });
      onSuccess();
      onClose();
    } catch (err: any) {
      console.error('Points adjustment error:', err);
      setError(err.message || 'Failed to adjust points balance.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-backdrop" onClick={onClose} role="dialog" aria-modal="true">
      <div className="modal fade-up" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 460 }}>
        <div className="modal-header">
          <span className="modal-title flex items-center gap-2">
            <Hugeicon name="audit" size={18} state="warning" />
            Adjust Akawo Points — {user.full_name}
          </span>
          <button type="button" className="modal-close" onClick={onClose} disabled={loading} aria-label="Close dialog">
            <Hugeicon name="close" size={14} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body flex flex-col gap-4">
            <div className="form-group">
              <label className="form-label">Current Points Balance</label>
              <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--warning)' }}>
                {user.akawo_points.toLocaleString()} pts
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Point Adjustment Amount</label>
              <input
                type="number"
                className="form-control font-mono"
                placeholder="e.g. 100 or -50"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                required
                disabled={loading}
                autoFocus
              />
              <span className="text-xs text-tertiary">
                Enter positive integer to award points, negative to deduct.
              </span>
            </div>

            <div className="form-group">
              <label className="form-label">Administrative Reason / Audit Note</label>
              <textarea
                className="form-control"
                placeholder="Reason for this point adjustment (recorded in audit logs)..."
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                required
                disabled={loading}
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
            <button type="button" className="btn btn-secondary" onClick={onClose} disabled={loading}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary" disabled={loading}>
              {loading ? (
                <>
                  <Hugeicon name="refresh" className="animate-spin" size={14} />
                  Updating Balance…
                </>
              ) : (
                'Apply Adjustment'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
