import React, { useState } from 'react';
import { adminAuthApi, AdminSpotlightTurnItem } from '../../api/adminAuthApi';
import { Hugeicon } from '../common/Hugeicon';
import { useToast } from '../../context/ToastContext';

interface DisapproveSubmissionModalProps {
  submission: AdminSpotlightTurnItem;
  onClose: () => void;
  onSuccess: () => void;
}

const PREDEFINED_REASONS = [
  'Policy Violation',
  'Incorrect Submission Format',
  'Spam or Misleading Offer',
  'Unsafe / Inappropriate Content',
  'Duplicate Campaign Submission',
  'Other Reason',
];

export const DisapproveSubmissionModal: React.FC<DisapproveSubmissionModalProps> = ({
  submission,
  onClose,
  onSuccess,
}) => {
  const { showToast } = useToast();
  const [selectedReason, setSelectedReason] = useState<string>(PREDEFINED_REASONS[0]);
  const [note, setNote] = useState<string>('');
  const [submitting, setSubmitting] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    setSubmitting(true);
    try {
      const res = await adminAuthApi.disapproveSpotlightSubmission(
        submission.id,
        selectedReason,
        note.trim() || undefined
      );

      showToast({
        type: 'success',
        title: 'Submission Disapproved',
        message: res.message || 'Spotlight submission has been disapproved.',
      });
      onSuccess();
      onClose();
    } catch (err: any) {
      console.error('Disapprove error:', err);
      setError(err.message || 'Failed to disapprove submission.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="modal-backdrop" onClick={onClose} role="dialog" aria-modal="true">
      <div className="modal fade-up" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 460 }}>
        <div className="modal-header">
          <span className="modal-title flex items-center gap-2">
            <Hugeicon name="error" size={18} state="error" />
            Disapprove Spotlight Submission
          </span>
          <button type="button" className="modal-close" onClick={onClose} disabled={submitting} aria-label="Close dialog">
            <Hugeicon name="close" size={14} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body flex flex-col gap-4">
            <div
              style={{
                background: 'var(--bg-elevated)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-sm)',
                padding: '0.75rem',
              }}
            >
              <div className="text-xs text-secondary font-bold uppercase mb-1">Target Submission</div>
              <div className="font-bold text-sm">{submission.title}</div>
              <div className="text-xs text-tertiary">Submitted by: {submission.full_name}</div>
            </div>

            {/* Predefined Reason Dropdown */}
            <div className="form-group">
              <label className="form-label">Moderation Reason</label>
              <select
                className="form-control"
                value={selectedReason}
                onChange={(e) => setSelectedReason(e.target.value)}
                disabled={submitting}
              >
                {PREDEFINED_REASONS.map((r) => (
                  <option key={r} value={r}>
                    {r}
                  </option>
                ))}
              </select>
            </div>

            {/* Additional Note */}
            <div className="form-group">
              <label className="form-label">Optional Admin Note</label>
              <textarea
                className="form-control"
                placeholder="Additional feedback for the audit log..."
                value={note}
                onChange={(e) => setNote(e.target.value)}
                disabled={submitting}
                rows={2}
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
            <button type="submit" className="btn btn-danger" disabled={submitting}>
              {submitting ? (
                <>
                  <Hugeicon name="refresh" className="animate-spin" size={14} />
                  Disapproving…
                </>
              ) : (
                'Confirm Disapproval'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
