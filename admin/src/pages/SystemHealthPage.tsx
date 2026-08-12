import React, { useEffect, useState, useCallback } from 'react';
import { adminAuthApi, SystemHealthData } from '../api/adminAuthApi';
import { GlobalLoadingState } from '../components/common/GlobalLoadingState';
import { GlobalErrorState } from '../components/common/GlobalErrorState';
import { Hugeicon } from '../components/common/Hugeicon';
import { useToast } from '../context/ToastContext';

export const SystemHealthPage: React.FC = () => {
  const { showToast } = useToast();
  const [data, setData] = useState<SystemHealthData | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const fetchHealth = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await adminAuthApi.getSystemHealth();
      setData(res);
    } catch (err: any) {
      console.error('Failed to fetch system health:', err);
      setError(err.message || 'Failed to fetch system health status.');
      showToast({
        type: 'error',
        title: 'System Health Check Failed',
        message: err.message || 'Could not connect to backend server.',
      });
    } finally {
      setLoading(false);
    }
  }, [showToast]);

  useEffect(() => {
    fetchHealth();
  }, [fetchHealth]);

  if (loading) {
    return <GlobalLoadingState type="page" message="Querying system health and database status…" />;
  }

  if (error || !data) {
    return (
      <GlobalErrorState
        type="network"
        title="System Health Check Failed"
        message={error || 'Unable to connect to backend system health monitoring endpoint.'}
        onRetry={fetchHealth}
      />
    );
  }

  const isHealthy = data.status === 'healthy' && data.database.status === 'connected';

  return (
    <div className="flex flex-col gap-6 fade-up">
      {/* Header */}
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">System Health & Infrastructure</h1>
          <p className="page-subtitle">
            Real-time status of database connectivity, server uptime, and Node.js environment.
          </p>
        </div>
        <button type="button" className="btn btn-secondary" onClick={fetchHealth}>
          <Hugeicon name="refresh" size={14} />
          Refresh Check
        </button>
      </div>

      {/* System Status Banner */}
      <div
        className="card"
        style={{
          background: isHealthy ? 'var(--brand-green-dim)' : 'var(--danger-dim)',
          border: `1px solid ${isHealthy ? 'rgba(90, 255, 0, 0.25)' : 'rgba(255, 68, 68, 0.25)'}`,
          padding: '1.25rem 1.5rem',
        }}
      >
        <div className="flex items-center justify-between flex-wrap gap-4">
          <div className="flex items-center gap-3">
            <div
              style={{
                width: 40,
                height: 40,
                borderRadius: 10,
                background: isHealthy ? 'rgba(90, 255, 0, 0.2)' : 'rgba(255, 68, 68, 0.2)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Hugeicon
                name={isHealthy ? 'check' : 'warning'}
                state={isHealthy ? 'success' : 'error'}
                size={22}
              />
            </div>
            <div>
              <div className="flex items-center gap-2 mb-1">
                <span className="font-bold text-base">
                  {isHealthy ? 'All Systems Operational' : 'System Degraded'}
                </span>
                <span className={`badge ${isHealthy ? 'badge-green' : 'badge-red'}`}>
                  {data.status.toUpperCase()}
                </span>
              </div>
              <p className="text-xs text-secondary margin-0">
                Last checked: {new Date(data.timestamp).toLocaleString()}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Metrics Grid */}
      <div className="stat-grid">
        <div className="stat-card">
          <div className="stat-top">
            <span className="stat-label">Database Connection</span>
            <div className="stat-icon">
              <Hugeicon
                name="system"
                size={14}
                state={data.database.status === 'connected' ? 'success' : 'error'}
              />
            </div>
          </div>
          <div className="stat-value" style={{ fontSize: '1.4rem' }}>
            {data.database.status === 'connected' ? 'Connected' : 'Disconnected'}
          </div>
          <div className="stat-change text-secondary">
            PostgreSQL Latency: {data.database.latency_ms} ms
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-top">
            <span className="stat-label">Server Uptime</span>
            <div className="stat-icon">
              <Hugeicon name="refresh" size={14} state="active" />
            </div>
          </div>
          <div className="stat-value" style={{ fontSize: '1.4rem' }}>
            {Math.floor(data.uptime_seconds / 3600)}h {Math.floor((data.uptime_seconds % 3600) / 60)}m
          </div>
          <div className="stat-change text-secondary">
            Process uptime ({data.uptime_seconds}s)
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-top">
            <span className="stat-label">Node Memory (Heap)</span>
            <div className="stat-icon">
              <Hugeicon name="analytics" size={14} />
            </div>
          </div>
          <div className="stat-value" style={{ fontSize: '1.4rem' }}>
            {data.memory.heap_used_mb} MB
          </div>
          <div className="stat-change text-secondary">
            Heap Total: {data.memory.heap_total_mb} MB | RSS: {data.memory.rss_mb} MB
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-top">
            <span className="stat-label">Environment</span>
            <div className="stat-icon">
              <Hugeicon name="info" size={14} />
            </div>
          </div>
          <div className="stat-value" style={{ fontSize: '1.4rem' }}>
            {data.environment}
          </div>
          <div className="stat-change text-secondary">
            Node Version: {data.node_version}
          </div>
        </div>
      </div>
    </div>
  );
};
