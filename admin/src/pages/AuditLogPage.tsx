import React, { useEffect, useState, useCallback } from 'react';
import { adminAuthApi, AuditLogItem } from '../api/adminAuthApi';
import { GlobalLoadingState } from '../components/common/GlobalLoadingState';
import { GlobalErrorState } from '../components/common/GlobalErrorState';
import { GlobalEmptyState } from '../components/common/GlobalEmptyState';
import { Hugeicon } from '../components/common/Hugeicon';
import { useToast } from '../context/ToastContext';

export const AuditLogPage: React.FC = () => {
  const { showToast } = useToast();
  const [logs, setLogs] = useState<AuditLogItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [filterAction, setFilterAction] = useState<string>('');

  const fetchAuditLogs = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await adminAuthApi.getAuditLogs(100, 0);
      setLogs(res.logs || []);
    } catch (err: any) {
      console.error('Failed to fetch audit logs:', err);
      setError(err.message || 'Failed to fetch administrative audit logs.');
      showToast({
        type: 'error',
        title: 'Audit Logs Fetch Error',
        message: err.message || 'Unable to query audit logs from database.',
      });
    } finally {
      setLoading(false);
    }
  }, [showToast]);

  useEffect(() => {
    fetchAuditLogs();
  }, [fetchAuditLogs]);

  const filteredLogs = logs.filter((log) => {
    if (!filterAction) return true;
    return log.action.toLowerCase().includes(filterAction.toLowerCase()) ||
           log.admin_name.toLowerCase().includes(filterAction.toLowerCase()) ||
           log.resource_type.toLowerCase().includes(filterAction.toLowerCase());
  });

  if (loading) {
    return <GlobalLoadingState type="page" message="Loading administrative audit trail from database…" />;
  }

  if (error) {
    return (
      <GlobalErrorState
        type="page"
        title="Could Not Load Audit Trail"
        message={error}
        onRetry={fetchAuditLogs}
      />
    );
  }

  return (
    <div className="flex flex-col gap-6 fade-up">
      {/* Header */}
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">Administrative Audit Log</h1>
          <p className="page-subtitle">
            Immutable audit record of administrative access, authentication events, and system changes.
          </p>
        </div>
        <button type="button" className="btn btn-secondary" onClick={fetchAuditLogs}>
          <Hugeicon name="refresh" size={14} />
          Refresh Log
        </button>
      </div>

      {/* Audit Logs Table Card */}
      <div className="card">
        <div className="card-header">
          <span className="card-title">
            <Hugeicon name="audit" size={16} state="active" />
            Audit Events
            <span className="badge badge-blue">{filteredLogs.length} events</span>
          </span>

          <div className="search-bar" style={{ width: 240 }}>
            <Hugeicon name="search" size={14} variant="muted" />
            <input
              type="text"
              placeholder="Filter action, admin, resource…"
              value={filterAction}
              onChange={(e) => setFilterAction(e.target.value)}
            />
          </div>
        </div>

        {filteredLogs.length === 0 ? (
          <GlobalEmptyState
            icon="audit"
            title={filterAction ? "No matching audit events" : "No Audit Logs Recorded"}
            description={
              filterAction
                ? `No audit event matched filter query "${filterAction}".`
                : "No administrative audit events have been recorded in PostgreSQL audit_logs table yet."
            }
            actionLabel={filterAction ? "Clear Filter" : "Refresh Audit Log"}
            onAction={() => {
              if (filterAction) setFilterAction('');
              else fetchAuditLogs();
            }}
          />
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Timestamp</th>
                  <th>Admin Identity</th>
                  <th>Action</th>
                  <th>Resource</th>
                  <th>IP Address</th>
                  <th>Result</th>
                </tr>
              </thead>
              <tbody>
                {filteredLogs.map((log) => (
                  <tr key={log.id}>
                    <td className="text-sm font-mono" style={{ color: 'var(--text-secondary)' }}>
                      {new Date(log.created_at).toLocaleString('en-GB', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                        second: '2-digit',
                      })}
                    </td>
                    <td>
                      <div className="font-bold text-sm">{log.admin_name || 'Admin'}</div>
                      <div className="text-xs text-tertiary font-mono">{log.admin_phone}</div>
                    </td>
                    <td>
                      <span className="badge badge-blue font-mono">{log.action}</span>
                    </td>
                    <td>
                      <span className="text-sm">{log.resource_type}</span>
                      {log.resource_id && (
                        <div className="text-xs text-tertiary font-mono">{log.resource_id}</div>
                      )}
                    </td>
                    <td className="text-sm font-mono">{log.ip_address || '127.0.0.1'}</td>
                    <td>
                      <span className={`badge ${log.result === 'success' ? 'badge-green' : 'badge-red'}`}>
                        {log.result === 'success' ? '✓ Success' : '✕ Failure'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};
