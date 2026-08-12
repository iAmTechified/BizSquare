import React from 'react';
import { Hugeicon } from './Hugeicon';

export interface BreadcrumbItem {
  label: string;
  href?: string;
  onClick?: () => void;
}

export interface BreadcrumbsProps {
  items: BreadcrumbItem[];
}

export const Breadcrumbs: React.FC<BreadcrumbsProps> = ({ items }) => {
  return (
    <nav className="topbar-breadcrumb" aria-label="Breadcrumb">
      <span className="topbar-breadcrumb-root flex items-center gap-1">
        <Hugeicon name="shield" size={13} variant="muted" />
        Admin
      </span>

      {items.map((item, idx) => {
        const isLast = idx === items.length - 1;
        return (
          <React.Fragment key={idx}>
            <span className="topbar-breadcrumb-sep">
              <Hugeicon name="chevronRight" size={12} variant="muted" />
            </span>
            {isLast || !item.onClick ? (
              <span className="topbar-breadcrumb-current">{item.label}</span>
            ) : (
              <button
                type="button"
                onClick={item.onClick}
                className="topbar-breadcrumb-root"
                style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: 0 }}
              >
                {item.label}
              </button>
            )}
          </React.Fragment>
        );
      })}
    </nav>
  );
};
