import React from 'react';
import { Hugeicon, HugeiconName } from './Hugeicon';

export interface GlobalEmptyStateProps {
  icon?: HugeiconName;
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
  badge?: string;
  style?: React.CSSProperties;
}

export const GlobalEmptyState: React.FC<GlobalEmptyStateProps> = ({
  icon = 'audit',
  title,
  description,
  actionLabel,
  onAction,
  badge,
  style = {},
}) => {
  return (
    <div className="empty-state fade-up" style={style}>
      <div className="empty-state-icon">
        <Hugeicon name={icon} size={24} variant="muted" />
      </div>

      {badge && <span className="badge badge-gray" style={{ marginBottom: 4 }}>{badge}</span>}

      <div className="empty-state-title">{title}</div>
      <p className="empty-state-desc">{description}</p>

      {actionLabel && onAction && (
        <button
          type="button"
          className="btn btn-secondary btn-sm"
          onClick={onAction}
          style={{ marginTop: '0.5rem' }}
        >
          {actionLabel}
        </button>
      )}
    </div>
  );
};
