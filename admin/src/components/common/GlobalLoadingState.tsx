import React from 'react';
import { Hugeicon } from './Hugeicon';

export interface GlobalLoadingStateProps {
  type?: 'page' | 'section' | 'table' | 'spinner';
  message?: string;
  rows?: number;
}

export const GlobalLoadingState: React.FC<GlobalLoadingStateProps> = ({
  type = 'page',
  message = 'Loading administrative data…',
  rows = 5,
}) => {
  if (type === 'spinner') {
    return (
      <div className="flex items-center gap-2 text-secondary text-sm" style={{ padding: '1rem' }}>
        <Hugeicon name="refresh" className="animate-spin" size={16} state="active" />
        <span>{message}</span>
      </div>
    );
  }

  if (type === 'table') {
    return (
      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              <th style={{ width: '25%' }}><div className="skeleton skeleton-text" /></th>
              <th style={{ width: '35%' }}><div className="skeleton skeleton-text" /></th>
              <th style={{ width: '20%' }}><div className="skeleton skeleton-text" /></th>
              <th style={{ width: '20%' }}><div className="skeleton skeleton-text" /></th>
            </tr>
          </thead>
          <tbody>
            {Array.from({ length: rows }).map((_, i) => (
              <tr key={i}>
                <td><div className="skeleton skeleton-text" /></td>
                <td><div className="skeleton skeleton-text" /></td>
                <td><div className="skeleton skeleton-text" /></td>
                <td><div className="skeleton skeleton-text" /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }

  if (type === 'section') {
    return (
      <div className="card fade-up" style={{ padding: '1.5rem' }}>
        <div className="skeleton skeleton-text" style={{ width: '30%', height: 24, marginBottom: 16 }} />
        <div className="skeleton skeleton-text" style={{ width: '80%', height: 16, marginBottom: 8 }} />
        <div className="skeleton skeleton-text" style={{ width: '60%', height: 16 }} />
      </div>
    );
  }

  // Full page skeleton loading state
  return (
    <div className="page-content fade-up" style={{ padding: '2rem' }}>
      <div className="flex justify-between items-center mb-4">
        <div>
          <div className="skeleton skeleton-text" style={{ width: 220, height: 28, marginBottom: 8 }} />
          <div className="skeleton skeleton-text" style={{ width: 340, height: 16 }} />
        </div>
        <div className="skeleton" style={{ width: 100, height: 36, borderRadius: 8 }} />
      </div>

      <div className="stat-grid mb-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="stat-card">
            <div className="stat-top">
              <div className="skeleton skeleton-text" style={{ width: 80 }} />
              <div className="skeleton" style={{ width: 28, height: 28, borderRadius: 6 }} />
            </div>
            <div className="skeleton skeleton-stat" />
          </div>
        ))}
      </div>

      <div className="card">
        <div className="card-header">
          <div className="skeleton skeleton-text" style={{ width: 160 }} />
        </div>
        <div className="card-body">
          <div className="skeleton skeleton-row mb-4" />
          <div className="skeleton skeleton-row mb-4" />
          <div className="skeleton skeleton-row" />
        </div>
      </div>
    </div>
  );
};
