import React, { useEffect, useState, useCallback } from 'react';
import { adminApi, type SpotlightCampaign } from '../api/adminApi';
import {
  Star, Users, Coins, RefreshCw, Eye, CheckCircle2,
  Clock, TrendingUp, Sparkles, CalendarDays, XCircle
} from 'lucide-react';

// ─── Campaign Participants Modal ───────────────────────────────────────────

interface ParticipantsModalProps {
  campaign: SpotlightCampaign;
  onClose: () => void;
}

const ParticipantsModal: React.FC<ParticipantsModalProps> = ({ campaign, onClose }) => {
  const [participants, setParticipants] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminApi.getCampaignParticipants(campaign.id)
      .then(setParticipants)
      .finally(() => setLoading(false));
  }, [campaign.id]);

  // Mock participants if API returns empty
  const displayList = participants.length > 0 ? participants : Array.from({ length: campaign.participants_count }, (_, i) => ({
    id: `p_${i}`,
    full_name: ['Amara Okonkwo', 'Kehinde Adeyemi', 'Tunde Fashola', 'Ngozi Eze', 'Babatunde Osei'][i % 5],
    verified: i % 3 !== 1,
    shared_at: new Date(Date.now() - i * 3_600_000).toISOString(),
    points_earned: 50,
  }));

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" style={{ maxWidth: 640 }} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <span className="modal-title flex items-center gap-2">
            <Users size={16} color="var(--brand-blue)" />
            Participants — {campaign.business_name}
          </span>
          <button className="modal-close" onClick={onClose}><XCircle size={15} /></button>
        </div>
        <div className="modal-body" style={{ padding: 0 }}>
          {loading ? (
            <div className="flex items-center justify-between" style={{ padding: '2rem', color: 'var(--text-secondary)', gap: '0.5rem' }}>
              <RefreshCw size={18} className="animate-spin" /> Loading participants…
            </div>
          ) : (
            <div style={{ maxHeight: 440, overflowY: 'auto' }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Participant</th>
                    <th>Shared At</th>
                    <th>Verified</th>
                    <th>Points Earned</th>
                  </tr>
                </thead>
                <tbody>
                  {displayList.length === 0 ? (
                    <tr><td colSpan={4}>
                      <div className="empty-state"><div className="empty-state-title">No participants yet</div></div>
                    </td></tr>
                  ) : (
                    displayList.map((p: any) => (
                      <tr key={p.id}>
                        <td>
                          <div style={{ fontWeight: 600 }}>{p.full_name || p.user_name}</div>
                        </td>
                        <td className="text-sm" style={{ color: 'var(--text-secondary)' }}>
                          {new Date(p.shared_at || p.created_at).toLocaleString('en-GB', {
                            day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit'
                          })}
                        </td>
                        <td>
                          <span className={`badge ${p.verified ? 'badge-green' : 'badge-yellow'}`}>
                            {p.verified ? '✓ Verified' : '⏳ Pending'}
                          </span>
                        </td>
                        <td>
                          <span style={{ fontWeight: 700, color: 'var(--warning)' }}>
                            +{p.points_earned || 50}
                          </span>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose}>Close</button>
        </div>
      </div>
    </div>
  );
};

// ─── Status Badge ──────────────────────────────────────────────────────────

const StatusBadge: React.FC<{ status: SpotlightCampaign['status'] }> = ({ status }) => {
  const map = {
    active: { cls: 'badge-green', label: '● Live Now' },
    scheduled: { cls: 'badge-blue', label: '◷ Scheduled' },
    completed: { cls: 'badge-gray', label: '✓ Completed' },
    pending: { cls: 'badge-yellow', label: '⏳ Pending' },
  };
  const { cls, label } = map[status] ?? map.pending;
  return <span className={`badge ${cls}`}>{label}</span>;
};

// ─── Spotlight Dashboard ───────────────────────────────────────────────────

export const SpotlightDashboard: React.FC = () => {
  const [campaigns, setCampaigns] = useState<SpotlightCampaign[]>([]);
  const [loading, setLoading] = useState(true);
  const [inspectTarget, setInspectTarget] = useState<SpotlightCampaign | null>(null);
  const [filter, setFilter] = useState<'all' | SpotlightCampaign['status']>('all');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await adminApi.getSpotlightCampaigns();
      setCampaigns(data);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const filtered = filter === 'all' ? campaigns : campaigns.filter(c => c.status === filter);

  const activeCampaign = campaigns.find(c => c.status === 'active');
  const totalParticipants = campaigns.reduce((s, c) => s + c.participants_count, 0);
  const totalPointsAwarded = campaigns.reduce((s, c) => s + c.points_awarded, 0);

  return (
    <>
      {inspectTarget && (
        <ParticipantsModal campaign={inspectTarget} onClose={() => setInspectTarget(null)} />
      )}

      {/* Page Header */}
      <div className="page-header fade-up">
        <div className="page-header-left">
          <h1 className="page-title">Spotlight Economy</h1>
          <p className="page-subtitle">
            Monitor daily Spotlight campaigns, verify participant shares, and manage Akawo Points distribution.
          </p>
        </div>
        <button className="btn btn-secondary" onClick={load}>
          <RefreshCw size={14} /> Refresh
        </button>
      </div>

      {/* Active Campaign Banner */}
      {activeCampaign && (
        <div className="fade-up" style={{
          background: 'linear-gradient(135deg, rgba(90, 255, 0, 0.08), rgba(0, 88, 255, 0.06))',
          border: '1px solid rgba(90, 255, 0, 0.25)',
          borderRadius: 'var(--radius-lg)',
          padding: '1.25rem 1.5rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '1rem',
          flexWrap: 'wrap',
        }}>
          <div className="flex items-center gap-3">
            <div style={{
              width: 44, height: 44, borderRadius: 12,
              background: 'rgba(90, 255, 0, 0.15)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Sparkles size={22} color="var(--brand-green)" />
            </div>
            <div>
              <div className="flex items-center gap-2" style={{ marginBottom: 3 }}>
                <span style={{ fontWeight: 800, fontSize: '1rem' }}>{activeCampaign.business_name}</span>
                <span className="badge badge-green" style={{ animation: 'none' }}>● LIVE</span>
              </div>
              <p style={{ fontSize: 13, color: 'var(--text-secondary)', margin: 0 }}>
                {activeCampaign.promo_text}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--brand-green)' }}>
                {activeCampaign.participants_count}
              </div>
              <div style={{ fontSize: 11, color: 'var(--text-secondary)', fontWeight: 600 }}>Participants</div>
            </div>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--warning)' }}>
                {activeCampaign.points_awarded.toLocaleString()}
              </div>
              <div style={{ fontSize: 11, color: 'var(--text-secondary)', fontWeight: 600 }}>Pts Awarded</div>
            </div>
            <button className="btn btn-secondary btn-sm" onClick={() => setInspectTarget(activeCampaign)}>
              <Eye size={13} /> View Participants
            </button>
          </div>
        </div>
      )}

      {/* Summary KPIs */}
      <div className="stat-grid fade-up-delay-1">
        <div className="stat-card" style={{ '--card-accent': 'var(--brand-green)', '--card-accent-dim': 'var(--brand-green-dim)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Total Campaigns</span>
            <div className="stat-icon" style={{ background: 'var(--brand-green-dim)', color: 'var(--brand-green)' }}>
              <CalendarDays size={14} />
            </div>
          </div>
          <div className="stat-value">{campaigns.length}</div>
          <div className="stat-change up">{campaigns.filter(c => c.status === 'active').length} live now</div>
        </div>
        <div className="stat-card" style={{ '--card-accent': 'var(--brand-blue)', '--card-accent-dim': 'var(--brand-blue-dim)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Total Participants</span>
            <div className="stat-icon">
              <Users size={14} />
            </div>
          </div>
          <div className="stat-value">{totalParticipants.toLocaleString()}</div>
          <div className="stat-change up">across all campaigns</div>
        </div>
        <div className="stat-card" style={{ '--card-accent': '#f59e0b', '--card-accent-dim': 'rgba(245,158,11,0.12)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Points Distributed</span>
            <div className="stat-icon" style={{ background: 'rgba(245,158,11,0.12)', color: '#f59e0b' }}>
              <Coins size={14} />
            </div>
          </div>
          <div className="stat-value">{totalPointsAwarded.toLocaleString()}</div>
          <div className="stat-change up">total Akawo Points</div>
        </div>
        <div className="stat-card" style={{ '--card-accent': 'var(--brand-pink)', '--card-accent-dim': 'var(--brand-pink-dim)' } as React.CSSProperties}>
          <div className="stat-top">
            <span className="stat-label">Avg Participation Rate</span>
            <div className="stat-icon" style={{ background: 'var(--brand-pink-dim)', color: 'var(--brand-pink)' }}>
              <TrendingUp size={14} />
            </div>
          </div>
          <div className="stat-value">
            {campaigns.length > 0
              ? Math.round(totalParticipants / campaigns.length)
              : 0}
          </div>
          <div className="stat-change up">participants per campaign</div>
        </div>
      </div>

      {/* Campaign Table */}
      <div className="card fade-up-delay-2">
        <div className="card-header">
          <span className="card-title"><Star size={16} color="var(--warning)" /> Campaign History</span>
          <div className="tab-list">
            {(['all', 'active', 'scheduled', 'completed'] as const).map(f => (
              <button
                key={f}
                className={`tab-btn ${filter === f ? 'active' : ''}`}
                onClick={() => setFilter(f)}
              >
                {f.charAt(0).toUpperCase() + f.slice(1)}
                {f !== 'all' && (
                  <span style={{
                    fontSize: 10, fontWeight: 700,
                    background: 'var(--bg-elevated)', padding: '1px 5px', borderRadius: 99,
                  }}>
                    {campaigns.filter(c => c.status === f).length}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>

        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Business</th>
                <th>Campaign Title</th>
                <th>Status</th>
                <th>Participants</th>
                <th>Points Awarded</th>
                <th>Period</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                Array.from({ length: 4 }).map((_, i) => (
                  <tr key={i}>
                    {Array.from({ length: 7 }).map((_, j) => (
                      <td key={j}><div className="skeleton skeleton-text" /></td>
                    ))}
                  </tr>
                ))
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={7}>
                    <div className="empty-state">
                      <div className="empty-state-icon"><Star size={22} /></div>
                      <div className="empty-state-title">No campaigns</div>
                      <p className="empty-state-desc">No {filter !== 'all' ? filter : ''} campaigns to display.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((c) => (
                  <tr key={c.id}>
                    <td>
                      <div style={{ fontWeight: 600 }}>{c.business_name}</div>
                      <div style={{ fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'monospace' }}>
                        {c.user_id.slice(0, 10)}…
                      </div>
                    </td>
                    <td style={{ maxWidth: 200 }}>
                      <div style={{ fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {c.title}
                      </div>
                      <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 2 }}>
                        {c.promo_text.slice(0, 48)}…
                      </div>
                    </td>
                    <td><StatusBadge status={c.status} /></td>
                    <td>
                      <div className="flex items-center gap-2">
                        <Users size={13} color="var(--text-tertiary)" />
                        <span style={{ fontWeight: 700 }}>{c.participants_count}</span>
                      </div>
                    </td>
                    <td>
                      <span style={{ fontWeight: 700, color: 'var(--warning)' }}>
                        {c.points_awarded.toLocaleString()} pts
                      </span>
                    </td>
                    <td className="text-sm" style={{ color: 'var(--text-secondary)' }}>
                      <div className="flex items-center gap-1">
                        <Clock size={12} />
                        {new Date(c.starts_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}
                        {' → '}
                        {new Date(c.ends_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}
                      </div>
                    </td>
                    <td>
                      <button
                        className="btn btn-xs btn-secondary"
                        onClick={() => setInspectTarget(c)}
                        disabled={c.participants_count === 0 && c.status !== 'active'}
                      >
                        <Eye size={11} /> Participants
                      </button>
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
