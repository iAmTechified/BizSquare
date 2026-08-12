import React, { useState } from 'react';
import { adminAuthApi, MediaRecordItem } from '../../api/adminAuthApi';
import { Hugeicon } from '../common/Hugeicon';
import { useToast } from '../../context/ToastContext';

interface MediaInspectionCardProps {
  mediaUrl?: string | null;
  mediaRecord?: MediaRecordItem | null;
  onRefresh?: () => void;
}

export const MediaInspectionCard: React.FC<MediaInspectionCardProps> = ({
  mediaUrl,
  mediaRecord,
  onRefresh,
}) => {
  const { showToast } = useToast();
  const [retrying, setRetrying] = useState<boolean>(false);
  const [imageError, setImageError] = useState<boolean>(false);

  const displayUrl = mediaUrl || (mediaRecord ? `/api/v1/media/${mediaRecord.id}` : null);

  if (!displayUrl && !mediaRecord) {
    return null;
  }

  const handleRetryProcessing = async () => {
    if (!mediaRecord) return;
    setRetrying(true);
    try {
      const res = await adminAuthApi.retryMediaProcessing(mediaRecord.id);
      showToast({ type: 'success', title: 'Processing Retried', message: res.message });
      if (onRefresh) onRefresh();
    } catch (err: any) {
      showToast({ type: 'error', title: 'Retry Failed', message: err.message || 'Could not retry media processing.' });
    } finally {
      setRetrying(false);
    }
  };

  return (
    <div
      style={{
        background: 'var(--bg-elevated)',
        border: '1px solid var(--border)',
        borderRadius: 'var(--radius-md)',
        padding: '0.85rem',
      }}
      className="flex flex-col gap-2 mt-3"
    >
      <div className="flex items-center justify-between">
        <span className="text-xs text-secondary font-bold uppercase flex items-center gap-1.5">
          <Hugeicon name="media" size={14} state="active" />
          Attached Spotlight Media Pipeline
        </span>

        {mediaRecord && (
          <span
            className={`badge ${
              mediaRecord.status === 'READY'
                ? 'badge-green'
                : mediaRecord.status === 'PROCESSING'
                ? 'badge-yellow'
                : 'badge-red'
            } text-xs`}
          >
            {mediaRecord.status} • {mediaRecord.processing_status}
          </span>
        )}
      </div>

      {/* Media Preview Container */}
      <div
        style={{
          width: '100%',
          maxHeight: 240,
          background: '#090b10',
          borderRadius: 'var(--radius-sm)',
          overflow: 'hidden',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          border: '1px solid var(--border)',
        }}
      >
        {imageError ? (
          <div className="p-6 text-center text-xs text-tertiary flex flex-col items-center gap-1">
            <Hugeicon name="error" size={24} state="error" />
            Media preview failed to load or access expired.
          </div>
        ) : mediaRecord?.media_type === 'VIDEO' ? (
          <video
            src={displayUrl || undefined}
            controls
            preload="metadata"
            style={{ maxWidth: '100%', maxHeight: 240 }}
          />
        ) : (
          <img
            src={displayUrl || undefined}
            alt="Spotlight Attached Media"
            onError={() => setImageError(true)}
            style={{ maxWidth: '100%', maxHeight: 240, objectFit: 'contain' }}
          />
        )}
      </div>

      {/* Metadata Bar */}
      {mediaRecord && (
        <div className="flex justify-between items-center text-xs text-tertiary font-mono pt-1" style={{ borderTop: '1px solid var(--border)' }}>
          <span>
            Type: {mediaRecord.mime_type} ({(mediaRecord.file_size / (1024 * 1024)).toFixed(2)} MB)
          </span>
          {mediaRecord.width && (
            <span>
              {mediaRecord.width} × {mediaRecord.height} px
            </span>
          )}
          {mediaRecord.duration_seconds && <span>{mediaRecord.duration_seconds} sec</span>}
        </div>
      )}

      {/* Retry Action if Failed */}
      {mediaRecord?.status === 'FAILED' && (
        <div className="flex justify-end pt-1">
          <button
            type="button"
            className="btn btn-xs btn-secondary"
            onClick={handleRetryProcessing}
            disabled={retrying}
          >
            <Hugeicon name="refresh" className={retrying ? 'animate-spin' : ''} size={12} />
            Retry Media Processing
          </button>
        </div>
      )}
    </div>
  );
};
