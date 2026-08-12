import React, { useEffect, useState, useCallback } from 'react';
import { adminApi, type AdminUser } from '../api/adminApi';
import {
  Search, ShieldOff, ShieldCheck, RefreshCw,
  Coins, MoreHorizontal, UserX, CheckCircle2, XCircle
} from 'lucide-react';

// ─── Award Points Modal ────────────────────────────────────────────────────

interface AwardModalProps {
  user: AdminUser;
  onClose: () => void;
  onDone: () => void;
}

const AwardPointsModal: React.FC<AwardModalProps> = ({ user, onClose, onDone }) => {
  const [amount, setAmount] = useState('');
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const pts = parseInt(amount);
    if (!pts || pts === 0) return setError('Enter a non-zero amount (negative to deduct).');
    if (!reason.trim()) return setError('Reason is required.');
    setLoading(true);
    try {
      await adminApi.adjustPoints(user.id, pts, reason);
      onDone();
      onClose();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <span className="modal-title flex items-center gap-2">
            <Coins size={18} color="var(--warning)" /> Adjust Points — {user.full_name}
          </span>
          <button className="modal-close" onClick={onClose}><XCircle size={15} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body flex flex-col gap-4">
            <div className="form-group">
              <label className="form-label">Current Balance</label>
              <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--warning)' }}>
                {user.akawo_points.toLocaleString()} pts
              </div>
            </div>
            <div className="form-group">
              <label className="form-label">Point Adjustment (negative to deduct)</label>
              <input
                className="form-control"
                type="number"
                placeholder="e.g. 100 or -50"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">Reason / Note</label>
              <textarea
                className="form-control"
                placeholder="Admin reason for this adjustment..."
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                required
              />
            </div>
            {error && <div className="alert alert-error">{error}</div>}
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn btn-primary" disabled={loading}>
              {loading ? <RefreshCw size={14} className="animate-spin" /> : <CheckCircle2 size={14} />}
              Apply Adjustment
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// ─── Main User Management Component ───────────────────────────────────────

export const UserManagement: React.FC = () => {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [awardTarget, setAwardTarget] = useState<AdminUser | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const loadUsers = useCallback(async () => {
    setLoading(true);
    try {
      const data = await adminApi.getUsers({ limit: 100 });
      setUsers(data);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadUsers(); }, [loadUsers]);

  const handleToggleSuspend = async (user: AdminUser) => {
    const willSuspend = user.is_active;
    if (!window.confirm(`${willSuspend ? 'Suspend' : 'Reinstate'} ${user.full_name}?`)) return;
    setActionLoading(user.id);
    try {
      await adminApi.suspendUser(user.id, willSuspend);
      setUsers(prev => prev.map(u => u.id === user.id ? { ...u, is_active: !willSuspend } : u));
      setSuccessMsg(`${user.full_name} has been ${willSuspend ? 'suspended' : 'reinstated'}.`);
      setTimeout(() => setSuccessMsg(null), 3000);
    } catch (err: any) {
      alert(`Failed: ${err.message}`);
    } finally {
      setActionLoading(null);
    }
  };

  const filtered = users.filter(u =>
    u.full_name.toLowerCase().includes(search.toLowerCase()) ||
    u.phone_number.includes(search) ||
    u.id.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <>
      {awardTarget && (
        <AwardPointsModal
          user={awardTarget}
          onClose={() => setAwardTarget(null)}
          onDone={loadUsers}
        />
      )}

      <div className="card fade-up-delay-1">
        <div className="card-header">
          <span className="card-title">
            User Registry
            <span className="badge badge-blue">{users.length} users</span>
          </span>
          <div className="flex items-center gap-2">
            <div className="search-bar" style={{ width: 240 }}>
              <Search size={14} color="var(--text-tertiary)" />
              <input
                placeholder="Search name, phone, ID…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <button className="btn btn-secondary btn-sm" onClick={loadUsers}>
              <RefreshCw size={13} />
            </button>
          </div>
        </div>

        {successMsg && (
          <div style={{ padding: '0.75rem 1.25rem', borderBottom: '1px solid var(--border)' }}>
            <div className="alert alert-success">
              <CheckCircle2 size={14} /> {successMsg}
            </div>
          </div>
        )}

        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Phone</th>
                <th>Akawo Points</th>
                <th>Level</th>
                <th>Status</th>
                <th>Last Login</th>
                <th>Joined</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i}>
                    {Array.from({ length: 8 }).map((_, j) => (
                      <td key={j}><div className="skeleton skeleton-text" /></td>
                    ))}
                  </tr>
                ))
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={8}>
                    <div className="empty-state">
                      <div className="empty-state-icon"><UserX size={22} /></div>
                      <div className="empty-state-title">No users found</div>
                      <p className="empty-state-desc">Try adjusting your search query.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((user) => (
                  <tr key={user.id}>
                    <td>
                      <div className="flex items-center gap-2">
                        <div style={{
                          width: 30, height: 30, borderRadius: '50%',
                          background: `linear-gradient(135deg, var(--brand-blue), var(--brand-green))`,
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                          fontSize: 11, fontWeight: 800, color: '#fff', flexShrink: 0,
                        }}>
                          {user.full_name.charAt(0)}
                        </div>
                        <div>
                          <div style={{ fontWeight: 600, fontSize: 13 }}>{user.full_name}</div>
                          <div className="text-xs" style={{ color: 'var(--text-tertiary)', fontFamily: 'monospace' }}>
                            {user.id.slice(0, 12)}…
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="font-mono text-sm">{user.phone_number}</td>
                    <td>
                      <span style={{ fontWeight: 700, color: 'var(--warning)' }}>
                        {user.akawo_points.toLocaleString()}
                      </span>
                    </td>
                    <td>
                      <span className="badge badge-gray">{user.access_level}</span>
                    </td>
                    <td>
                      <span className={`badge ${user.is_active ? 'badge-green' : 'badge-red'}`}>
                        {user.is_active ? '● active' : '○ suspended'}
                      </span>
                    </td>
                    <td className="text-sm" style={{ color: 'var(--text-secondary)' }}>
                      {user.last_login
                        ? new Date(user.last_login).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: '2-digit' })
                        : <span style={{ color: 'var(--text-tertiary)' }}>Never</span>}
                    </td>
                    <td className="text-sm" style={{ color: 'var(--text-secondary)' }}>
                      {new Date(user.created_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: '2-digit' })}
                    </td>
                    <td>
                      <div className="flex items-center gap-1">
                        <button
                          className="btn btn-xs btn-secondary"
                          title="Adjust Points"
                          onClick={() => setAwardTarget(user)}
                        >
                          <Coins size={11} />
                        </button>
                        <button
                          className={`btn btn-xs ${user.is_active ? 'btn-danger' : 'btn-success'}`}
                          onClick={() => handleToggleSuspend(user)}
                          disabled={actionLoading === user.id}
                          title={user.is_active ? 'Suspend' : 'Reinstate'}
                        >
                          {actionLoading === user.id ? (
                            <RefreshCw size={11} className="animate-spin" />
                          ) : user.is_active ? (
                            <ShieldOff size={11} />
                          ) : (
                            <ShieldCheck size={11} />
                          )}
                          {user.is_active ? 'Suspend' : 'Reinstate'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
};
