import React, { useEffect, useState, useCallback } from 'react';
import { adminAuthApi, AdminUserListItem } from '../api/adminAuthApi';
import { useAdminAuth } from '../context/AdminAuthContext';
import { useToast } from '../context/ToastContext';
import { useConfirmation } from '../context/ConfirmationContext';
import { GlobalLoadingState } from '../components/common/GlobalLoadingState';
import { GlobalErrorState } from '../components/common/GlobalErrorState';
import { GlobalEmptyState } from '../components/common/GlobalEmptyState';
import { Hugeicon } from '../components/common/Hugeicon';
import { AdjustPointsModal } from '../components/users/AdjustPointsModal';

interface UserManagementPageProps {
  onSelectUser: (userId: string) => void;
}

type SortOption = 'newest' | 'oldest' | 'recently_active' | 'name_asc' | 'name_desc';

export const UserManagementPage: React.FC<UserManagementPageProps> = ({ onSelectUser }) => {
  const { hasPermission } = useAdminAuth();
  const { showToast } = useToast();
  const { confirm } = useConfirmation();

  const canManage = hasPermission('users.manage');

  const [users, setUsers] = useState<AdminUserListItem[]>([]);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Search state (with typing/debouncing indicator)
  const [searchInput, setSearchInput] = useState<string>('');
  const [debouncedSearch, setDebouncedSearch] = useState<string>('');
  const [isTyping, setIsTyping] = useState<boolean>(false);

  // Filter states
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [setupFilter, setSetupFilter] = useState<string>('all');
  const [spotlightFilter, setSpotlightFilter] = useState<string>('all');
  const [syncFilter, setSyncFilter] = useState<string>('all');

  // Sorting & Pagination
  const [sortOption, setSortOption] = useState<SortOption>('newest');
  const [limit] = useState<number>(20);
  const [offset, setOffset] = useState<number>(0);

  // Points Modal selection state
  const [adjustPointsUser, setAdjustPointsUser] = useState<AdminUserListItem | null>(null);

  // Debounce search input (500ms)
  useEffect(() => {
    setIsTyping(true);
    const handler = setTimeout(() => {
      setDebouncedSearch(searchInput);
      setIsTyping(false);
      setOffset(0);
    }, 500);

    return () => clearTimeout(handler);
  }, [searchInput]);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await adminAuthApi.getUsersRegistry({
        search: debouncedSearch.trim() || undefined,
        status: statusFilter !== 'all' ? statusFilter : undefined,
        setup_status: setupFilter !== 'all' ? setupFilter : undefined,
        spotlight_status: spotlightFilter !== 'all' ? spotlightFilter : undefined,
        contact_sync_status: syncFilter !== 'all' ? syncFilter : undefined,
        sort: sortOption,
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
  }, [debouncedSearch, statusFilter, setupFilter, spotlightFilter, syncFilter, sortOption, limit, offset, showToast]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const handleClearFilters = () => {
    setSearchInput('');
    setDebouncedSearch('');
    setStatusFilter('all');
    setSetupFilter('all');
    setSpotlightFilter('all');
    setSyncFilter('all');
    setSortOption('newest');
    setOffset(0);
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
        fetchUsers();
      },
    });
  };

  const activeFiltersCount =
    (statusFilter !== 'all' ? 1 : 0) +
    (setupFilter !== 'all' ? 1 : 0) +
    (spotlightFilter !== 'all' ? 1 : 0) +
    (syncFilter !== 'all' ? 1 : 0) +
    (debouncedSearch ? 1 : 0);

  const totalPages = Math.ceil(totalCount / limit) || 1;
  const currentPage = Math.floor(offset / limit) + 1;

  if (loading && users.length === 0 && !debouncedSearch) {
    return <GlobalLoadingState type="page" message="Loading production user registry from database…" />;
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
      {/* Points Modal */}
      {adjustPointsUser && (
        <AdjustPointsModal
          user={adjustPointsUser}
          onClose={() => setAdjustPointsUser(null)}
          onSuccess={fetchUsers}
        />
      )}

      {/* Page Header */}
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">Users</h1>
          <p className="page-subtitle">Find and manage BizSquare users.</p>
        </div>
        <button type="button" className="btn btn-secondary" onClick={fetchUsers}>
          <Hugeicon name="refresh" className={loading ? 'animate-spin' : ''} size={14} />
          Refresh Users
        </button>
      </div>

      {/* Search & Filters Toolbar */}
      <div className="card" style={{ padding: '1.25rem' }}>
        <div className="flex flex-col gap-3">
          {/* Top Row: Search Input + Sorting */}
          <div className="flex justify-between items-center flex-wrap gap-3">
            <div className="search-bar" style={{ width: 340, maxWidth: '100%' }}>
              <Hugeicon name="search" size={14} variant="muted" />
              <input
                type="text"
                placeholder="Search name, phone, username, business, ID…"
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
              />
              {isTyping && <Hugeicon name="refresh" className="animate-spin" size={12} variant="muted" />}
              {searchInput && !isTyping && (
                <button
                  type="button"
                  onClick={() => setSearchInput('')}
                  style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
                >
                  <Hugeicon name="close" size={12} variant="muted" />
                </button>
              )}
            </div>

            <div className="flex items-center gap-2">
              <span className="text-xs text-secondary font-bold">Sort By:</span>
              <select
                className="form-control font-bold text-xs"
                style={{ width: 170, padding: '0.4rem 0.6rem' }}
                value={sortOption}
                onChange={(e) => {
                  setSortOption(e.target.value as SortOption);
                  setOffset(0);
                }}
              >
                <option value="newest">Newest Joined</option>
                <option value="oldest">Oldest Joined</option>
                <option value="recently_active">Recently Active</option>
                <option value="name_asc">Name (A–Z)</option>
                <option value="name_desc">Name (Z–A)</option>
              </select>
            </div>
          </div>

          {/* Bottom Row: Server-Backed Filters */}
          <div className="flex items-center justify-between flex-wrap gap-3 pt-2" style={{ borderTop: '1px solid var(--border)' }}>
            <div className="flex items-center gap-3 flex-wrap text-xs">
              <span className="text-secondary font-bold">Filters:</span>

              {/* Account Status Filter */}
              <select
                className="form-control text-xs"
                style={{ width: 140, padding: '0.3rem 0.5rem' }}
                value={statusFilter}
                onChange={(e) => { setStatusFilter(e.target.value); setOffset(0); }}
              >
                <option value="all">All Account States</option>
                <option value="active">Active Only</option>
                <option value="suspended">Suspended Only</option>
              </select>

              {/* Setup Status Filter */}
              <select
                className="form-control text-xs"
                style={{ width: 140, padding: '0.3rem 0.5rem' }}
                value={setupFilter}
                onChange={(e) => { setSetupFilter(e.target.value); setOffset(0); }}
              >
                <option value="all">All Setup States</option>
                <option value="complete">Complete Setup</option>
                <option value="incomplete">Incomplete Setup</option>
              </select>

              {/* Spotlight Status Filter */}
              <select
                className="form-control text-xs"
                style={{ width: 150, padding: '0.3rem 0.5rem' }}
                value={spotlightFilter}
                onChange={(e) => { setSpotlightFilter(e.target.value); setOffset(0); }}
              >
                <option value="all">All Spotlight States</option>
                <option value="active">Active Turn</option>
                <option value="pending">Pending Review</option>
                <option value="none">Not Participating</option>
              </select>
            </div>

            {activeFiltersCount > 0 && (
              <button
                type="button"
                className="btn btn-xs btn-secondary"
                onClick={handleClearFilters}
              >
                <Hugeicon name="close" size={12} />
                Clear All Filters ({activeFiltersCount})
              </button>
            )}
          </div>
        </div>
      </div>

      {/* User Registry Data Table Card */}
      <div className="card">
        <div className="card-header flex justify-between items-center">
          <span className="card-title">
            <Hugeicon name="users" size={16} state="active" />
            BizSquare User Accounts
            <span className="badge badge-blue">{totalCount.toLocaleString()} matching</span>
          </span>

          {loading && (
            <span className="text-xs text-secondary flex items-center gap-1">
              <Hugeicon name="refresh" className="animate-spin" size={12} />
              Querying database…
            </span>
          )}
        </div>

        {users.length === 0 ? (
          <GlobalEmptyState
            icon="users"
            title={activeFiltersCount > 0 ? 'No Users Match Current Filters' : 'No User Accounts Found'}
            description={
              activeFiltersCount > 0
                ? 'No production users match your active search terms or filter criteria.'
                : 'No user accounts recorded in PostgreSQL database.'
            }
            actionLabel={activeFiltersCount > 0 ? 'Clear Filters' : 'Refresh Users'}
            onAction={activeFiltersCount > 0 ? handleClearFilters : fetchUsers}
          />
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>User Identity</th>
                  <th>Primary Offer / Niche</th>
                  <th>Account Status</th>
                  <th>Setup Status</th>
                  <th>Spotlight</th>
                  <th>Contact Sync</th>
                  <th>Joined Date</th>
                  <th>Last Active</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map((u) => (
                  <tr
                    key={u.id}
                    style={{ cursor: 'pointer' }}
                    onClick={() => onSelectUser(u.id)}
                  >
                    {/* 1. User Identity */}
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
                          <div className="font-bold text-sm text-primary flex items-center gap-1">
                            {u.full_name}
                            {u.username && <span className="text-xs text-tertiary font-mono">(@{u.username})</span>}
                          </div>
                          <div className="text-xs text-tertiary font-mono">{u.id.slice(0, 12)}…</div>
                        </div>
                      </div>
                    </td>

                    {/* 2. Primary Offer / Niche */}
                    <td>
                      <div>
                        <div className="font-bold text-xs" style={{ color: 'var(--text-primary)' }}>
                          {u.primary_offer || u.business_name || 'Not specified'}
                        </div>
                        {u.secondary_offers_count && u.secondary_offers_count > 0 ? (
                          <div className="text-xs text-secondary mt-0.5">
                            +{u.secondary_offers_count} secondary offer{u.secondary_offers_count > 1 ? 's' : ''}
                          </div>
                        ) : null}
                      </div>
                    </td>

                    {/* 3. Account Status */}
                    <td>
                      <span className={`badge ${u.is_active ? 'badge-green' : 'badge-red'}`}>
                        {u.is_active ? '● Active' : '✕ Suspended'}
                      </span>
                    </td>

                    {/* 4. Setup Status */}
                    <td>
                      <span className={`badge ${u.onboarding_completed ? 'badge-blue' : 'badge-yellow'}`}>
                        {u.onboarding_completed ? 'Complete' : 'Incomplete'}
                      </span>
                    </td>

                    {/* 5. Spotlight Status */}
                    <td>
                      <span className="badge badge-gray">
                        {u.spotlight_status === 'active'
                          ? 'Current Turn'
                          : u.spotlight_status === 'pending'
                          ? 'Pending Review'
                          : 'Not Participating'}
                      </span>
                    </td>

                    {/* 6. Contact Sync Status */}
                    <td>
                      <span
                        className={`badge ${
                          u.contact_sync_status === 'SYNCED'
                            ? 'badge-green'
                            : u.contact_sync_status === 'FAILED'
                            ? 'badge-red'
                            : 'badge-gray'
                        }`}
                      >
                        {u.contact_sync_status || 'Eligible'}
                      </span>
                    </td>

                    {/* 7. Joined Date */}
                    <td className="text-xs text-secondary">
                      {new Date(u.created_at).toLocaleDateString('en-GB', {
                        day: 'numeric',
                        month: 'short',
                        year: '2-digit',
                      })}
                    </td>

                    {/* 8. Last Active */}
                    <td className="text-xs font-mono text-secondary">
                      {u.last_login
                        ? new Date(u.last_login).toLocaleDateString('en-GB', {
                            day: 'numeric',
                            month: 'short',
                          })
                        : 'Never'}
                    </td>

                    {/* 9. Actions */}
                    <td style={{ textAlign: 'right' }} onClick={(e) => e.stopPropagation()}>
                      <div className="flex items-center justify-end gap-1">
                        <button
                          type="button"
                          className="btn btn-xs btn-secondary"
                          title="Inspect Detailed Profile"
                          onClick={() => onSelectUser(u.id)}
                        >
                          <Hugeicon name="search" size={12} />
                          Inspect
                        </button>

                        {canManage && (
                          <>
                            <button
                              type="button"
                              className="btn btn-xs btn-secondary"
                              title="Adjust Akawo Points Balance"
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
