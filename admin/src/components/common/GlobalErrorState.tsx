import React from 'react';
import { Hugeicon } from './Hugeicon';

export interface GlobalErrorStateProps {
  type?: 'page' | 'authorization' | 'session_expired' | 'network' | 'action';
  title?: string;
  message?: string;
  onRetry?: () => void;
  onAction?: () => void;
  actionLabel?: string;
}

export const GlobalErrorState: React.FC<GlobalErrorStateProps> = ({
  type = 'page',
  title,
  message,
  onRetry,
  onAction,
  actionLabel,
}) => {
  let iconName: any = 'error';
  let iconState: any = 'error';
  let defaultTitle = 'Something went wrong';
  let defaultMessage = "We couldn't load this information right now.";

  if (type === 'authorization') {
    iconName = 'lock';
    iconState = 'warning';
    defaultTitle = 'Access Denied';
    defaultMessage = "You don't have permission to access this area or perform this action.";
  } else if (type === 'session_expired') {
    iconName = 'userProfile';
    iconState = 'warning';
    defaultTitle = 'Session Expired';
    defaultMessage = 'Your administrative session has expired. Please sign in again to continue.';
  } else if (type === 'network') {
    iconName = 'warning';
    iconState = 'error';
    defaultTitle = 'Connection Error';
    defaultMessage = "You're offline or the backend API server is currently unreachable.";
  } else if (type === 'action') {
    iconName = 'error';
    iconState = 'error';
    defaultTitle = "Couldn't complete this action";
    defaultMessage = 'An unexpected error occurred while performing this operation.';
  }

  const resolvedTitle = title || defaultTitle;
  const resolvedMessage = message || defaultMessage;

  return (
    <div
      className="card fade-up"
      style={{
        padding: '3rem 2rem',
        margin: '2rem auto',
        maxWidth: 520,
        textAlign: 'center',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: '1rem',
      }}
      role="alert"
    >
      <div
        style={{
          width: 56,
          height: 56,
          borderRadius: 16,
          background: type === 'authorization' ? 'var(--warning-dim)' : 'var(--danger-dim)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <Hugeicon name={iconName} state={iconState} size={28} />
      </div>

      <div>
        <h3
          style={{
            fontSize: '1.125rem',
            fontWeight: 800,
            color: 'var(--text-primary)',
            marginBottom: '0.375rem',
          }}
        >
          {resolvedTitle}
        </h3>
        <p
          style={{
            fontSize: '0.875rem',
            color: 'var(--text-secondary)',
            lineHeight: 1.5,
            margin: 0,
          }}
        >
          {resolvedMessage}
        </p>
      </div>

      <div className="flex gap-2" style={{ marginTop: '0.5rem' }}>
        {onRetry && (
          <button type="button" className="btn btn-primary" onClick={onRetry}>
            <Hugeicon name="refresh" size={14} />
            Try Again
          </button>
        )}

        {onAction && (
          <button type="button" className="btn btn-secondary" onClick={onAction}>
            {actionLabel || 'Continue'}
          </button>
        )}
      </div>
    </div>
  );
};
