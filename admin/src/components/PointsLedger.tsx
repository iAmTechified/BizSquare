import React, { useEffect, useState, useCallback } from 'react';
import { adminApi, type LedgerEntry } from '../api/adminApi';
import {
  Coins, Bot, UserCheck, RefreshCw, Search, TrendingDown, TrendingUp, ChevronDown
} from 'lucide-react';

export const PointsLedger: React.FC = () => {
  const [entries, setEntries] = useState<LedgerEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filterDir, setFilterDir] = useState<'all' | 'credits' | 'debits'>('all');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await adminApi.getLedger({ limit: 200 });
      setEntries(data);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const filtered = entries.filter(e => {
    const matchesSearch =
      (e.user_name || e.user_id).toLowerCase().includes(search.toLowerCase()) ||
      e.reason.toLowerCase().includes(search.toLowerCase());
    const matchesDir =
      filterDir === 'all' ||
      (filterDir === 'credits' && e.points_awarded > 0) ||
      (filterDir === 'debits' && e.points_awarded < 0);
    return matchesSearch && matchesDir;
  });

  const totalCredits = entries.filter(e => e.points_awarded > 0).reduce((s, e) => s + e.points_awarded, 0);
  const totalDebits = entries.filter(e => e.points_awarded < 0).reduce((s, e) => s + e.points_awarded, 0);
  const botVerified = entries.filter(e => e.verified_by_bot && e.points_awarded > 0).length;

  return (
    <>
      <div className="page-header fade-up">
        <div className="page-header-left">
          <h1 className="page-title">Points Ledger</h1>
          <p className="page-subtitle">
            Full audit log of all Akawo Points awarded and deducted across the network.
          </p>
        </div>
        <button className="btn btn-secondary" onClick={load}>
          <RefreshCw size={14} /> Refresh
        </button>
      </div>

      {/* Summary Cards */}
      <div className="stat-grid fade-up-delay-1">
        <div className="stat-card" style={{ '--card-accent': '#f59e0b', '--card-accent-dim': 'rgba(245,158,11,0.12)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Total Transactions</span>
            <div className="stat-icon" style={{ background: 'rgba(245,158,11,0.12)', color: '#f59e0b' }}>
              <Coins size={14} />
            </div>
          </div>
          <div className="stat-value">{entries.length}</div>
          <div className="stat-change">Ledger entries</div>
        </div>
        <div className="stat-card" style={{ '--card-accent': 'var(--success)', '--card-accent-dim': 'var(--success-dim)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Total Credits</span>
            <div className="stat-icon" style={{ background: 'var(--success-dim)', color: 'var(--success)' }}>
              <TrendingUp size={14} />
            </div>
          </div>
          <div className="stat-value" style={{ color: 'var(--success)' }}>+{totalCredits.toLocaleString()}</div>
          <div className="stat-change up">Points awarded</div>
        </div>
        <div className="stat-card" style={{ '--card-accent': 'var(--danger)', '--card-accent-dim': 'var(--danger-dim)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Total Debits</span>
            <div className="stat-icon" style={{ background: 'var(--danger-dim)', color: 'var(--danger)' }}>
              <TrendingDown size={14} />
            </div>
          </div>
          <div className="stat-value" style={{ color: 'var(--danger)' }}>{totalDebits.toLocaleString()}</div>
          <div className="stat-change down">Points deducted</div>
        </div>
        <div className="stat-card" style={{ '--card-accent': 'var(--brand-blue)', '--card-accent-dim': 'var(--brand-blue-dim)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Bot-Verified Credits</span>
            <div className="stat-icon">
              <Bot size={14} />
            </div>
          </div>
          <div className="stat-value">{botVerified}</div>
          <div className="stat-change up">Spotlight verifications</div>
        </div>
      </div>

      {/* Ledger Table */}
      <div className="card fade-up-delay-2">
        <div className="card-header">
          <span className="card-title">
            <Coins size={16} color="var(--warning)" /> Transaction Log
          </span>
          <div className="flex items-center gap-2">
            <div className="tab-list">
              {(['all', 'credits', 'debits'] as const).map(f => (
                <button
                  key={f}
                  className={`tab-btn ${filterDir === f ? 'active' : ''}`}
                  onClick={() => setFilterDir(f)}
                >
                  {f.charAt(0).toUpperCase() + f.slice(1)}
                </button>
              ))}
            </div>
            <div className="search-bar" style={{ width: 220 }}>
              <Search size={13} color="var(--text-tertiary)" />
              <input
                placeholder="Search user, reason…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
          </div>
        </div>

        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Amount</th>
                <th>Reason</th>
                <th>Source</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i}>
                    {Array.from({ length: 5 }).map((_, j) => (
                      <td key={j}><div className="skeleton skeleton-text" /></td>
                    ))}
                  </tr>
                ))
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={5}>
                    <div className="empty-state">
                      <div className="empty-state-icon"><Coins size={22} /></div>
                      <div className="empty-state-title">No transactions found</div>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((entry) => {
                  const isCredit = entry.points_awarded > 0;
                  return (
                    <tr key={entry.id}>
                      <td>
                        <div style={{ fontWeight: 600 }}>{entry.user_name || entry.user_id.slice(0, 12) + '…'}</div>
                        <div style={{ fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'monospace' }}>
                          {entry.user_id.slice(0, 12)}…
                        </div>
                      </td>
                      <td>
                        <span style={{
                          fontSize: 15, fontWeight: 800,
                          color: isCredit ? 'var(--success)' : 'var(--danger)',
                        }}>
                          {isCredit ? '+' : ''}{entry.points_awarded}
                        </span>
                        <span style={{ fontSize: 11, color: 'var(--text-secondary)', marginLeft: 4 }}>pts</span>
                      </td>
                      <td style={{ maxWidth: 280 }}>
                        <span style={{ fontSize: 13, color: 'var(--text-primary)' }}>
                          {entry.reason}
                        </span>
                      </td>
                      <td>
                        {entry.verified_by_bot ? (
                          <span className="badge badge-blue">
                            <Bot size={10} /> Bot
                          </span>
                        ) : (
                          <span className="badge badge-gray">
                            <UserCheck size={10} /> Admin
                          </span>
                        )}
                      </td>
                      <td className="text-sm" style={{ color: 'var(--text-secondary)' }}>
                        {new Date(entry.created_at).toLocaleString('en-GB', {
                          day: 'numeric', month: 'short', year: '2-digit',
                          hour: '2-digit', minute: '2-digit',
                        })}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        <div style={{
          padding: '0.625rem 1.25rem',
          borderTop: '1px solid var(--border)',
          display: 'flex',
          alignItems: 'center',
          gap: '0.5rem',
          color: 'var(--text-tertiary)',
          fontSize: 12,
        }}>
          <ChevronDown size={13} />
          Showing {filtered.length} of {entries.length} transactions
        </div>
      </div>
    </>
  );
};
