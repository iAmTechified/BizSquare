import React, { useEffect, useState, useCallback } from 'react';
import { adminAuthApi, SetupCodeItem } from '../api/adminAuthApi';
import { useAdminAuth } from '../context/AdminAuthContext';
import { useToast } from '../context/ToastContext';
import { useConfirmation } from '../context/ConfirmationContext';
import { GlobalLoadingState } from '../components/common/GlobalLoadingState';
import { GlobalErrorState } from '../components/common/GlobalErrorState';
import { GlobalEmptyState } from '../components/common/GlobalEmptyState';
import { Hugeicon } from '../components/common/Hugeicon';
import { GenerateSetupCodeModal } from '../components/setup_codes/GenerateSetupCodeModal';

type SortOption = 'newest' | 'oldest' | 'expires_soon';

export const SetupCodesPage: React.FC = () => {
  const { hasPermission } = useAdminAuth();
  const { showToast } = useToast();
  const { confirm } = useConfirmation();

  const canManage = hasPermission('system.manage');

  const [codes, setCodes] = useState<SetupCodeItem[]>([]);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Search & Filter state
  const [search, setSearch] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [assignmentFilter, setAssignmentFilter] = useState<string>('all');
  const [sortOption, setSortOption] = useState<SortOption>('newest');

  // Pagination
  const [limit] = useState<number>(20);
  const [offset, setOffset] = useState<number>(0);

  // Modal & Copy feedback state
  const [showGenerateModal, setShowGenerateModal] = useState<boolean>(false);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const fetchCodes = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await adminAuthApi.getSetupCodes({
        search: search.trim() || undefined,
        status: statusFilter !== 'all' ? statusFilter : undefined,
        assignment: assignmentFilter !== 'all' ? assignmentFilter : undefined,
        sort: sortOption,
        limit,
        offset,
      });
      setCodes(res.codes || []);
      setTotalCount(res.total_count || 0);
    } catch (err: any) {
      console.error('Failed to fetch setup codes:', err);
      setError(err.message || 'Failed to fetch setup codes from database.');
      showToast({
        type: 'error',
        title: 'Fetch Error',
        message: err.message || 'Could not query setup codes.',
      });
    } finally {
      setLoading(false);
    }
  }, [search, statusFilter, assignmentFilter, sortOption, limit, offset, showToast]);

  useEffect(() => {
    fetchCodes();
  }, [fetchCodes]);

  const handleCopyCode = (codeStr: string, id: string) => {
    navigator.clipboard.writeText(codeStr);
    setCopiedId(id);
    showToast({ type: 'info', title: 'Code Copied', message: `Copied ${codeStr} to clipboard.` });
    setTimeout(() => setCopiedId(null), 2000);
  };

  const handleRevokeCode = (codeObj: SetupCodeItem) => {
    confirm({
      title: `Revoke Setup Code: ${codeObj.code}`,
      description: `Are you sure you want to revoke setup code ${codeObj.code}?`,
      consequence: 'This setup code will be permanently invalidated and will no longer be accepted during mobile onboarding.',
      isDestructive: true,
      confirmLabel: 'Yes, Revoke Code',
      onConfirm: async () => {
        const res = await adminAuthApi.revokeSetupCode(codeObj.id, 'Administrative revocation');
        showToast({
          type: 'success',
          title: 'Code Revoked',
          message: res.message,
        });
        fetchCodes();
      },
    });
  };

  const totalPages = Math.ceil(totalCount / limit) || 1;
  const currentPage = Math.floor(offset / limit) + 1;

  if (loading && codes.length === 0 && !search) {
    return <GlobalLoadingState type="page" message="Loading setup codes from database…" />;
  }

  if (error && codes.length === 0) {
    return (
      <GlobalErrorState
        type="page"
        title="Could Not Load Setup Codes"
        message={error}
        onRetry={fetchCodes}
      />
    );
  }

  return (
    <div className="flex flex-col gap-6 fade-up">
      {/* Generate Modal */}
      {showGenerateModal && (
        <GenerateSetupCodeModal
          onClose={() => setShowGenerateModal(false)}
          onSuccess={fetchCodes}
        />
      )}

      {/* Page Header */}
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">Setup Codes</h1>
          <p className="page-subtitle">Generate and manage codes used to complete BizSquare setup.</p>
        </div>

        {canManage && (
          <button
            type="button"
            className="btn btn-primary"
            onClick={() => setShowGenerateModal(true)}
          >
            <Hugeicon name="lock" size={14} />
            Generate Setup Code
          </button>
        )}
      </div>

      {/* Search & Filters Toolbar */}
      <div className="card" style={{ padding: '1.25rem' }}>
        <div className="flex flex-col gap-3">
          <div className="flex justify-between items-center flex-wrap gap-3">
            {/* Search Input */}
            <div className="search-bar" style={{ width: 340, maxWidth: '100%' }}>
              <Hugeicon name="search" size={14} variant="muted" />
              <input
                type="text"
                placeholder="Search code, user name, ID…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
              {search && (
                <button
                  type="button"
                  onClick={() => setSearch('')}
                  style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
                >
                  <Hugeicon name="close" size={12} variant="muted" />
                </button>
              )}
            </div>

            {/* Sort Select */}
            <div className="flex items-center gap-2">
              <span className="text-xs text-secondary font-bold">Sort:</span>
              <select
                className="form-control text-xs font-bold"
                style={{ width: 160, padding: '0.4rem 0.6rem' }}
                value={sortOption}
                onChange={(e) => setSortOption(e.target.value as SortOption)}
              >
                <option value="newest">Newest Generated</option>
                <option value="oldest">Oldest Generated</option>
                <option value="expires_soon">Expires Soonest</option>
              </select>
            </div>
          </div>

          {/* Filters Row */}
          <div className="flex items-center justify-between flex-wrap gap-3 pt-2" style={{ borderTop: '1px solid var(--border)' }}>
            <div className="flex items-center gap-3 flex-wrap text-xs">
              <span className="text-secondary font-bold">Filters:</span>

              <select
                className="form-control text-xs"
                style={{ width: 140, padding: '0.3rem 0.5rem' }}
                value={statusFilter}
                onChange={(e) => { setStatusFilter(e.target.value); setOffset(0); }}
              >
                <option value="all">All Statuses</option>
                <option value="available">Available Only</option>
                <option value="used">Used Only</option>
                <option value="expired">Expired Only</option>
                <option value="revoked">Revoked Only</option>
              </select>

              <select
                className="form-control text-xs"
                style={{ width: 150, padding: '0.3rem 0.5rem' }}
                value={assignmentFilter}
                onChange={(e) => { setAssignmentFilter(e.target.value); setOffset(0); }}
              >
                <option value="all">All Assignments</option>
                <option value="assigned">Assigned User Only</option>
                <option value="unassigned">Unassigned Only</option>
              </select>
            </div>

            {(statusFilter !== 'all' || assignmentFilter !== 'all' || search) && (
              <button
                type="button"
                className="btn btn-xs btn-secondary"
                onClick={() => {
                  setSearch('');
                  setStatusFilter('all');
                  setAssignmentFilter('all');
                  setOffset(0);
                }}
              >
                <Hugeicon name="close" size={12} />
                Clear Filters
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Setup Codes Data Table Card */}
      <div className="card">
        <div className="card-header flex justify-between items-center">
          <span className="card-title">
            <Hugeicon name="lock" size={16} state="active" />
            Generated Setup Codes
            <span className="badge badge-blue">{totalCount.toLocaleString()} total</span>
          </span>

          <button type="button" className="btn btn-xs btn-secondary" onClick={fetchCodes}>
            <Hugeicon name="refresh" className={loading ? 'animate-spin' : ''} size={12} />
            Refresh
          </button>
        </div>

        {codes.length === 0 ? (
          <GlobalEmptyState
            icon="lock"
            title={search || statusFilter !== 'all' ? 'No Matching Setup Codes' : 'No Setup Codes Generated'}
            description={
              search || statusFilter !== 'all'
                ? 'No setup codes matched your active search or filter criteria.'
                : 'Create a setup code when you are ready to onboard a user.'
            }
            actionLabel={canManage ? 'Generate Setup Code' : 'Refresh List'}
            onAction={canManage ? () => setShowGenerateModal(true) : fetchCodes}
          />
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Code Identifier</th>
                  <th>Status</th>
                  <th>Created</th>
                  <th>Expires</th>
                  <th>Assigned User</th>
                  <th>Used By</th>
                  <th>Created By</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {codes.map((c) => {
                  const isEligibleForRevocation = c.status === 'AVAILABLE' && !c.is_used && !c.is_revoked;

                  return (
                    <tr key={c.id}>
                      {/* Code */}
                      <td>
                        <div className="flex items-center gap-2">
                          <span
                            style={{
                              fontFamily: 'monospace',
                              fontWeight: 800,
                              fontSize: '0.95rem',
                              color: 'var(--brand-blue)',
                              background: 'var(--bg-elevated)',
                              padding: '0.25rem 0.6rem',
                              borderRadius: 'var(--radius-sm)',
                              border: '1px solid var(--border)',
                            }}
                          >
                            {c.code}
                          </span>
                        </div>
                      </td>

                      {/* Status Badge */}
                      <td>
                        <span
                          className={`badge ${
                            c.status === 'AVAILABLE'
                              ? 'badge-green'
                              : c.status === 'USED'
                              ? 'badge-blue'
                              : c.status === 'EXPIRED'
                              ? 'badge-yellow'
                              : 'badge-red'
                          }`}
                        >
                          {c.status}
                        </span>
                      </td>

                      {/* Created */}
                      <td className="text-xs text-secondary">
                        {new Date(c.created_at).toLocaleDateString('en-GB', {
                          day: 'numeric',
                          month: 'short',
                          year: '2-digit',
                        })}
                      </td>

                      {/* Expires */}
                      <td className="text-xs text-secondary font-mono">
                        {new Date(c.expires_at).toLocaleDateString('en-GB', {
                          day: 'numeric',
                          month: 'short',
                          year: '2-digit',
                        })}
                      </td>

                      {/* Assigned User */}
                      <td className="text-xs">
                        {c.intended_user_name ? (
                          <span className="font-bold">{c.intended_user_name}</span>
                        ) : (
                          <span className="text-tertiary">Unassigned (Generic)</span>
                        )}
                      </td>

                      {/* Used By */}
                      <td className="text-xs">
                        {c.used_by_name ? (
                          <div>
                            <div className="font-bold">{c.used_by_name}</div>
                            {c.used_at && (
                              <div className="text-tertiary font-mono">
                                {new Date(c.used_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}
                              </div>
                            )}
                          </div>
                        ) : (
                          <span className="text-tertiary">—</span>
                        )}
                      </td>

                      {/* Created By */}
                      <td className="text-xs text-tertiary">
                        {c.created_by_name || 'Admin'}
                      </td>

                      {/* Actions */}
                      <td style={{ textAlign: 'right' }}>
                        <div className="flex items-center justify-end gap-1">
                          <button
                            type="button"
                            className="btn btn-xs btn-secondary"
                            onClick={() => handleCopyCode(c.code, c.id)}
                          >
                            <Hugeicon name="audit" size={12} />
                            {copiedId === c.id ? 'Copied' : 'Copy'}
                          </button>

                          {canManage && isEligibleForRevocation && (
                            <button
                              type="button"
                              className="btn btn-xs btn-danger"
                              title="Revoke setup code"
                              onClick={() => handleRevokeCode(c)}
                            >
                              <Hugeicon name="close" size={12} />
                              Revoke
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination Footer */}
        {totalCount > 0 && (
          <div
            style={{
              padding: '0.75rem 1.25rem',
              borderTop: '1px solid var(--border)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              background: 'var(--bg-elevated)',
            }}
          >
            <div className="text-xs text-secondary font-mono">
              Showing {offset + 1}–{Math.min(offset + limit, totalCount)} of {totalCount.toLocaleString()} setup codes
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                className="btn btn-xs btn-secondary"
                disabled={offset === 0 || loading}
                onClick={() => setOffset((o) => Math.max(0, o - limit))}
              >
                <Hugeicon name="chevronLeft" size={12} />
                Previous
              </button>
              <span className="text-xs text-secondary font-bold">
                Page {currentPage} of {totalPages}
              </span>
              <button
                type="button"
                className="btn btn-xs btn-secondary"
                disabled={offset + limit >= totalCount || loading}
                onClick={() => setOffset((o) => o + limit)}
              >
                Next
                <Hugeicon name="chevronRight" size={12} />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
