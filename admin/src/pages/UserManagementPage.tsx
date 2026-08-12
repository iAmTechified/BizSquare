import React, { useEffect, useState, useCallback } from 'react';
import { adminAuthApi, AdminUserListItem } from '../api/adminAuthApi';
import { useAdminAuth } from '../context/AdminAuthContext';
import { useToast } from '../context/ToastContext';
import { useConfirmation } from '../context/ConfirmationContext';
import { GlobalLoadingState } from '../components/common/GlobalLoadingState';
import { GlobalErrorState } from '../components/common/GlobalErrorState';
import { GlobalEmptyState } from '../components/common/GlobalEmptyState';
import { Hugeicon } from '../components/common/Hugeicon';
import { UserInspectionDrawer } from '../components/users/UserInspectionDrawer';
import { AdjustPointsModal } from '../components/users/AdjustPointsModal';

type StatusFilter = 'all' | 'active' | 'suspended';

export const UserManagementPage: React.FC = () => {
  const { hasPermission } = useAdminAuth();
  const { showToast } = useToast();
  const { confirm } = useConfirmation();

  const canManage = hasPermission('users.manage');

  const [users, setUsers] = useState<AdminUserListItem[]>([]);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Filters & Pagination state
  const [search, setSearch] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [limit] = useState<number>(20);
  const [offset, setOffset] = useState<number>(0);

  // Drawer & Modal selection state
  const [inspectUser, setInspectUser] = useState<AdminUserListItem | null>(null);
  const [adjustPointsUser, setAdjustPointsUser] = useState<AdminUserListItem | null>(null);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await adminAuthApi.getUsersRegistry({
        search: search.trim() || undefined,
        status: statusFilter !== 'all' ? statusFilter : undefined,
        limit,
        offset,
      });
      setUsers(res.users || []);
      setTotalCount(res.total_count || 0);
    } catch (err: any) {
      console.error('Failed to fetch user registry:', err);
      setError(err.message || 'Failed to fetch user registry from database.');
      showToast({
        type: 'error',
        title: 'Registry Fetch Error',
        message: err.message || 'Could not query user records from database.',
      });
    } finally {
      setLoading(false);
    }
  }, [search, statusFilter, limit, offset, showToast]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setOffset(0);
    fetchUsers();
  };

  const handleToggleSuspend = (targetUser: AdminUserListItem) => {
    const isSuspending = targetUser.is_active;

    confirm({
      title: `${isSuspending ? 'Suspend' : 'Reinstate'} User Account`,
      description: `Are you sure you want to ${isSuspending ? 'suspend' : 'reinstate'} access for ${targetUser.full_name} (${targetUser.phone_number})?`,
      consequence: isSuspending
        ? 'Suspended accounts will immediately be denied administrative & mobile app access.'
        : 'Reinstated accounts will regain normal network participation rights.',
      isDestructive: isSuspending,
      confirmLabel: isSuspending ? 'Yes, Suspend Account' : 'Yes, Reinstate Account',
      onConfirm: async () => {
        const res = await adminAuthApi.suspendUserAccount(targetUser.id, isSuspending);
        showToast({
          type: 'success',
          title: `Account ${isSuspending ? 'Suspended' : 'Reinstated'}`,
          message: res.message,
        });
        if (inspectUser?.id === targetUser.id) {
          setInspectUser(null);
        }
        fetchUsers();
      },
    });
  };

  const totalPages = Math.ceil(totalCount / limit) || 1;
  const currentPage = Math.floor(offset / limit) + 1;

  if (loading && users.length === 0) {
    return <GlobalLoadingState type="page" message="Loading real user registry from database…" />;
  }

  if (error && users.length === 0) {
    return (
      <GlobalErrorState
        type="page"
        title="Could Not Load User Registry"
        message={error}
        onRetry={fetchUsers}
      />
    );
  }

  return (
    <div className="flex flex-col gap-6 fade-up">
      {/* Drawer & Modals */}
      {inspectUser && (
        <UserInspectionDrawer
          user={inspectUser}
          onClose={() => setInspectUser(null)}
          onOpenPointsModal={(u) => setAdjustPointsUser(u)}
          onToggleSuspend={handleToggleSuspend}
          canManageUsers={canManage}
        />
      )}

      {adjustPointsUser && (
        <AdjustPointsModal
          user={adjustPointsUser}
          onClose={() => setAdjustPointsUser(null)}
          onSuccess={fetchUsers}
        />
      )}

      {/* Header */}
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">User Registry & Account Management</h1>
          <p className="page-subtitle">
            Manage real user identities, inspect profiles, adjust Akawo Points, and suspend/reinstate accounts.
          </p>
        </div>
        <button type="button" className="btn btn-secondary" onClick={fetchUsers}>
          <Hugeicon name="refresh" className={loading ? 'animate-spin' : ''} size={14} />
          Refresh Registry
        </button>
      </div>

      {/* Registry Table Card */}
      <div className="card">
        <div className="card-header flex justify-between items-center flex-wrap gap-3">
          <div className="flex items-center gap-2">
            <span className="card-title">
              <Hugeicon name="users" size={16} state="active" />
              User Accounts
              <span className="badge badge-blue">{totalCount.toLocaleString()} total</span>
            </span>
          </div>

          <div className="flex items-center gap-3">
            {/* Status Filter Tabs */}
            <div className="tab-list">
              <button
                type="button"
                className={`tab-btn ${statusFilter === 'all' ? 'active' : ''}`}
                onClick={() => { setStatusFilter('all'); setOffset(0); }}
              >
                All Users
              </button>
              <button
                type="button"
                className={`tab-btn ${statusFilter === 'active' ? 'active' : ''}`}
                onClick={() => { setStatusFilter('active'); setOffset(0); }}
              >
                Active
              </button>
              <button
                type="button"
                className={`tab-btn ${statusFilter === 'suspended' ? 'active' : ''}`}
                onClick={() => { setStatusFilter('suspended'); setOffset(0); }}
              >
                Suspended
              </button>
            </div>

            {/* Search Input Form */}
            <form onSubmit={handleSearchSubmit} className="search-bar" style={{ width: 240 }}>
              <Hugeicon name="search" size={14} variant="muted" />
              <input
                type="text"
                placeholder="Search name, phone, ID…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
              {search && (
                <button
                  type="button"
                  onClick={() => { setSearch(''); setOffset(0); }}
                  style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
                >
                  <Hugeicon name="close" size={12} variant="muted" />
                </button>
              )}
            </form>
          </div>
        </div>

        {/* User Table Body */}
        {users.length === 0 ? (
          <GlobalEmptyState
            icon="users"
            title={search || statusFilter !== 'all' ? 'No Matching Users Found' : 'No User Accounts Recorded'}
            description={
              search || statusFilter !== 'all'
                ? `No user records matched query "${search}" with filter status "${statusFilter}".`
                : 'No user accounts found in PostgreSQL database.'
            }
            actionLabel={search || statusFilter !== 'all' ? 'Clear Filters' : 'Refresh Users'}
            onAction={() => {
              setSearch('');
              setStatusFilter('all');
              setOffset(0);
              fetchUsers();
            }}
          />
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>User Identity</th>
                  <th>Phone Number</th>
                  <th>Points</th>
                  <th>Access Level</th>
                  <th>Status</th>
                  <th>Last Login</th>
                  <th>Joined Date</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map((u) => (
                  <tr key={u.id}>
                    <td>
                      <div className="flex items-center gap-2">
                        <div
                          style={{
                            width: 32,
                            height: 32,
                            borderRadius: '50%',
                            background: 'linear-gradient(135deg, var(--brand-blue), var(--brand-green))',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: '#fff',
                            fontWeight: 800,
                            fontSize: 12,
                            flexShrink: 0,
                          }}
                        >
                          {u.full_name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div className="font-bold text-sm">{u.full_name}</div>
                          <div className="text-xs text-tertiary font-mono">{u.id.slice(0, 12)}…</div>
                        </div>
                      </div>
                    </td>
                    <td className="font-mono text-sm">{u.phone_number}</td>
                    <td>
                      <span className="font-bold" style={{ color: 'var(--warning)' }}>
                        {u.akawo_points.toLocaleString()} pts
                      </span>
                    </td>
                    <td>
                      <span className="badge badge-gray">{u.access_level}</span>
                    </td>
                    <td>
                      <span className={`badge ${u.is_active ? 'badge-green' : 'badge-red'}`}>
                        {u.is_active ? '● Active' : '✕ Suspended'}
                      </span>
                    </td>
                    <td className="text-sm text-secondary font-mono">
                      {u.last_login
                        ? new Date(u.last_login).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })
                        : 'Never'}
                    </td>
                    <td className="text-sm text-secondary">
                      {new Date(u.created_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: '2-digit' })}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div className="flex items-center justify-end gap-1">
                        <button
                          type="button"
                          className="btn btn-xs btn-secondary"
                          title="Inspect User Details"
                          onClick={() => setInspectUser(u)}
                        >
                          <Hugeicon name="search" size={12} />
                          Inspect
                        </button>

                        {canManage && (
                          <>
                            <button
                              type="button"
                              className="btn btn-xs btn-secondary"
                              title="Adjust Akawo Points"
                              onClick={() => setAdjustPointsUser(u)}
                            >
                              <Hugeicon name="audit" size={12} />
                              Points
                            </button>
                            <button
                              type="button"
                              className={`btn btn-xs ${u.is_active ? 'btn-danger' : 'btn-success'}`}
                              title={u.is_active ? 'Suspend Account' : 'Reinstate Account'}
                              onClick={() => handleToggleSuspend(u)}
                            >
                              <Hugeicon name={u.is_active ? 'lock' : 'check'} size={12} />
                              {u.is_active ? 'Suspend' : 'Reinstate'}
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Server-Side Pagination Footer */}
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
              Showing {offset + 1}–{Math.min(offset + limit, totalCount)} of {totalCount.toLocaleString()} users
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                className="btn btn-xs btn-secondary"
                disabled={offset === 0}
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
                disabled={offset + limit >= totalCount}
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
