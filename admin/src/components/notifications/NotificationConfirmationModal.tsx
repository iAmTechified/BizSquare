import React from 'react';
import { AdminNotificationBroadcastPayload } from '../../api/adminAuthApi';
import { Hugeicon } from '../common/Hugeicon';

interface NotificationConfirmationModalProps {
  payload: AdminNotificationBroadcastPayload;
  estimatedRecipients: number;
  submitting: boolean;
  onClose: () => void;
  onConfirm: () => void;
}

export const NotificationConfirmationModal: React.FC<NotificationConfirmationModalProps> = ({
  payload,
  estimatedRecipients,
  submitting,
  onClose,
  onConfirm,
}) => {
  const isScheduled = Boolean(payload.scheduled_at);

  return (
    <div className="modal-backdrop" onClick={onClose} role="dialog" aria-modal="true">
      <div className="modal fade-up" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 520 }}>
        <div className="modal-header">
          <span className="modal-title flex items-center gap-2">
            <Hugeicon name="send" size={18} state="active" />
            Confirm Broadcast Delivery
          </span>
          <button type="button" className="modal-close" onClick={onClose} disabled={submitting} aria-label="Close dialog">
            <Hugeicon name="close" size={14} />
          </button>
        </div>

        <div className="modal-body flex flex-col gap-4">
          <div className={`alert ${isScheduled ? 'alert-info' : 'alert-warning'}`}>
            <Hugeicon name={isScheduled ? 'schedule' : 'warning'} size={16} />
            <span>
              {isScheduled
                ? `You are scheduling this broadcast for ${new Date(payload.scheduled_at!).toLocaleString('en-GB')}.`
                : `You are about to send a live broadcast to ${estimatedRecipients} estimated active recipients across the BizSquare network.`}
            </span>
          </div>

          <div
            style={{
              background: 'var(--bg-elevated)',
              border: '1px solid var(--border)',
              borderRadius: 'var(--radius-md)',
              padding: '1rem',
            }}
            className="flex flex-col gap-2 text-xs"
          >
            <div className="flex justify-between items-center pb-2" style={{ borderBottom: '1px solid var(--border)' }}>
              <span className="text-secondary font-bold">Target Audience:</span>
              <span className="badge badge-blue font-bold">{payload.audience_type} ({estimatedRecipients} recipients)</span>
            </div>

            <div className="flex justify-between items-center py-1">
              <span className="text-secondary">Category & Variant:</span>
              <span className="badge badge-gray font-mono">{payload.category} • {payload.visual_variant}</span>
            </div>

            <div className="flex justify-between items-center py-1">
              <span className="text-secondary">Deep Link Destination:</span>
              <span className="font-mono text-tertiary">{payload.destination}</span>
            </div>

            <div className="pt-2" style={{ borderTop: '1px solid var(--border)' }}>
              <div className="text-secondary font-bold mb-1">Notification Content:</div>
              <div className="font-bold text-sm text-primary mb-0.5">{payload.title}</div>
              <p className="text-xs text-secondary line-clamp-3">{payload.body}</p>
            </div>
          </div>
        </div>

        <div className="modal-footer">
          <button type="button" className="btn btn-secondary" onClick={onClose} disabled={submitting}>
            Cancel
          </button>
          <button type="button" className="btn btn-primary" onClick={onConfirm} disabled={submitting}>
            {submitting ? (
              <>
                <Hugeicon name="refresh" className="animate-spin" size={14} />
                {isScheduled ? 'Scheduling Broadcast…' : 'Sending Broadcast…'}
              </>
            ) : (
              isScheduled ? 'Confirm Schedule' : 'Confirm Broadcast Send'
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
