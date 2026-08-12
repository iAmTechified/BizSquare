import React from 'react';

export type HugeiconName =
  | 'overview'
  | 'users'
  | 'contacts'
  | 'spotlight'
  | 'interests'
  | 'content'
  | 'notifications'
  | 'analytics'
  | 'system'
  | 'admins'
  | 'audit'
  | 'search'
  | 'userProfile'
  | 'logout'
  | 'chevronRight'
  | 'chevronDown'
  | 'chevronLeft'
  | 'menu'
  | 'close'
  | 'check'
  | 'warning'
  | 'error'
  | 'info'
  | 'lock'
  | 'refresh'
  | 'filter'
  | 'shield';

export type HugeiconVariant = 'outline' | 'filled' | 'strong' | 'muted' | 'disabled';
export type HugeiconState = 'default' | 'active' | 'success' | 'warning' | 'error' | 'disabled';

export interface HugeiconProps {
  name: HugeiconName;
  variant?: HugeiconVariant;
  state?: HugeiconState;
  size?: number;
  color?: string;
  className?: string;
  style?: React.CSSProperties;
}

/**
 * Hugeicons Centralized Icon Component for BizSquare Admin Dashboard.
 * Encapsulates Hugeicons design principles and communicates UI state via stroke, fill, and color.
 */
export const Hugeicon: React.FC<HugeiconProps> = ({
  name,
  variant = 'outline',
  state = 'default',
  size = 20,
  color,
  className = '',
  style = {},
}) => {
  // Determine stroke width and fill based on variant and state
  let strokeWidth = 1.5;
  let fill = 'none';

  if (variant === 'strong' || state === 'active') {
    strokeWidth = 2.2;
  } else if (variant === 'muted' || state === 'disabled') {
    strokeWidth = 1.2;
  } else if (variant === 'filled') {
    strokeWidth = 1.5;
    fill = 'currentColor';
  }

  // Determine state-communicating colors
  let resolvedColor = color || 'currentColor';
  if (!color) {
    switch (state) {
      case 'active':
        resolvedColor = 'var(--brand-blue)';
        break;
      case 'success':
        resolvedColor = 'var(--brand-green)';
        break;
      case 'warning':
        resolvedColor = 'var(--warning)';
        break;
      case 'error':
        resolvedColor = 'var(--danger)';
        break;
      case 'disabled':
        resolvedColor = 'var(--text-tertiary)';
        break;
      default:
        resolvedColor = 'currentColor';
    }
  }

  // SVG Path rendering based on Hugeicon name
  const renderPath = () => {
    switch (name) {
      case 'overview':
        return (
          <>
            <rect x="3" y="3" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <rect x="14" y="3" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <rect x="14" y="14" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <rect x="3" y="14" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
          </>
        );

      case 'users':
        return (
          <>
            <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" fill="none" />
            <circle cx="8.5" cy="7" r="4" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <path d="M23 21v-2a4 4 0 0 0-3-3.87" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <path d="M16 3.13a4 4 0 0 1 0 7.75" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
          </>
        );

      case 'contacts':
        return (
          <>
            <rect x="3" y="4" width="18" height="16" rx="3" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <line x1="8" y1="9" x2="16" y2="9" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <line x1="8" y1="13" x2="13" y2="13" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
          </>
        );

      case 'spotlight':
        return (
          <polygon
            points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"
            stroke="currentColor"
            strokeWidth={strokeWidth}
            strokeLinejoin="round"
            fill={fill === 'none' && state === 'active' ? 'var(--brand-green-dim)' : fill}
          />
        );

      case 'interests':
        return (
          <>
            <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
          </>
        );

      case 'content':
        return (
          <>
            <polygon points="12 2 2 7 12 12 22 7 12 2" stroke="currentColor" strokeWidth={strokeWidth} strokeLinejoin="round" fill={fill} />
            <polyline points="2 17 12 22 22 17" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />
            <polyline points="2 12 12 17 22 12" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />
          </>
        );

      case 'notifications':
        return (
          <>
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" fill={fill} />
            <path d="M13.73 21a2 2 0 0 1-3.46 0" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
          </>
        );

      case 'analytics':
        return (
          <>
            <line x1="18" y1="20" x2="18" y2="10" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <line x1="12" y1="20" x2="12" y2="4" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <line x1="6" y1="20" x2="6" y2="14" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
          </>
        );

      case 'system':
        return (
          <>
            <rect x="2" y="2" width="20" height="8" rx="2" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <rect x="2" y="14" width="20" height="8" rx="2" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <line x1="6" y1="6" x2="6.01" y2="6" stroke="currentColor" strokeWidth={strokeWidth + 0.5} strokeLinecap="round" />
            <line x1="6" y1="18" x2="6.01" y2="18" stroke="currentColor" strokeWidth={strokeWidth + 0.5} strokeLinecap="round" />
          </>
        );

      case 'admins':
        return (
          <>
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" stroke="currentColor" strokeWidth={strokeWidth} strokeLinejoin="round" fill={fill} />
            <circle cx="12" cy="10" r="2.5" stroke="currentColor" strokeWidth={strokeWidth} />
          </>
        );

      case 'audit':
        return (
          <>
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" stroke="currentColor" strokeWidth={strokeWidth} strokeLinejoin="round" fill={fill} />
            <polyline points="14 2 14 8 20 8" stroke="currentColor" strokeWidth={strokeWidth} strokeLinejoin="round" />
            <line x1="16" y1="13" x2="8" y2="13" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <line x1="16" y1="17" x2="8" y2="17" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <polyline points="10 9 9 9 8 9" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
          </>
        );

      case 'search':
        return (
          <>
            <circle cx="11" cy="11" r="8" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <line x1="21" y1="21" x2="16.65" y2="16.65" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
          </>
        );

      case 'userProfile':
        return (
          <>
            <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <circle cx="12" cy="10" r="3" stroke="currentColor" strokeWidth={strokeWidth} />
            <path d="M7 18.5c1.2-1.8 3-2.5 5-2.5s3.8.7 5 2.5" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
          </>
        );

      case 'logout':
        return (
          <>
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />
            <polyline points="16 17 21 12 16 7" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />
            <line x1="21" y1="12" x2="9" y2="12" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />
          </>
        );

      case 'chevronRight':
        return <polyline points="9 18 15 12 9 6" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />;

      case 'chevronDown':
        return <polyline points="6 9 12 15 18 9" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />;

      case 'chevronLeft':
        return <polyline points="15 18 9 12 15 6" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />;

      case 'menu':
        return (
          <>
            <line x1="3" y1="12" x2="21" y2="12" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <line x1="3" y1="6" x2="21" y2="6" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <line x1="3" y1="18" x2="21" y2="18" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
          </>
        );

      case 'close':
        return (
          <>
            <line x1="18" y1="6" x2="6" y2="18" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <line x1="6" y1="6" x2="18" y2="18" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
          </>
        );

      case 'check':
        return <polyline points="20 6 9 17 4 12" stroke="currentColor" strokeWidth={strokeWidth + 0.5} strokeLinecap="round" strokeLinejoin="round" />;

      case 'warning':
        return (
          <>
            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" stroke="currentColor" strokeWidth={strokeWidth} strokeLinejoin="round" fill={fill} />
            <line x1="12" y1="9" x2="12" y2="13" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <line x1="12" y1="17" x2="12.01" y2="17" stroke="currentColor" strokeWidth={strokeWidth + 0.5} strokeLinecap="round" />
          </>
        );

      case 'error':
        return (
          <>
            <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <line x1="15" y1="9" x2="9" y2="15" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <line x1="9" y1="9" x2="15" y2="15" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
          </>
        );

      case 'info':
        return (
          <>
            <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <line x1="12" y1="16" x2="12" y2="12" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
            <line x1="12" y1="8" x2="12.01" y2="8" stroke="currentColor" strokeWidth={strokeWidth + 0.5} strokeLinecap="round" />
          </>
        );

      case 'lock':
        return (
          <>
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2" stroke="currentColor" strokeWidth={strokeWidth} fill={fill} />
            <path d="M7 11V7a5 5 0 0 1 10 0v4" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" />
          </>
        );

      case 'refresh':
        return (
          <>
            <polyline points="23 4 23 10 17 10" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />
            <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />
          </>
        );

      case 'filter':
        return <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" stroke="currentColor" strokeWidth={strokeWidth} strokeLinejoin="round" fill={fill} />;

      case 'shield':
        return <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" stroke="currentColor" strokeWidth={strokeWidth} strokeLinejoin="round" fill={fill} />;

      default:
        return <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth={strokeWidth} />;
    }
  };

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      style={{ color: resolvedColor, display: 'inline-block', verticalAlign: 'middle', flexShrink: 0, ...style }}
      className={`hugeicon hugeicon-${name} hugeicon-state-${state} ${className}`}
      aria-hidden="true"
    >
      {renderPath()}
    </svg>
  );
};
