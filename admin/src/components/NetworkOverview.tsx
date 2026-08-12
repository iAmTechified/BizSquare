import React, { useEffect, useState } from 'react';
import { adminApi, type NetworkStats } from '../api/adminApi';
import { Users, GitMerge, Coins, TrendingUp, UserCheck, Zap } from 'lucide-react';

const STAT_DEFS = [
  {
    key: 'activeUsers' as const,
    label: 'Active Users',
    icon: Users,
    format: (v: number) => v.toLocaleString(),
    accentBlue: true,
    change: '+12% this week',
    changeDir: 'up' as const,
    css: { '--card-accent': 'var(--brand-blue)', '--card-accent-dim': 'var(--brand-blue-dim)' } as React.CSSProperties,
  },
  {
    key: 'totalMatches' as const,
    label: 'Total Matches',
    icon: GitMerge,
    format: (v: number) => v.toLocaleString(),
    change: '+2,340 last cycle',
    changeDir: 'up' as const,
    css: { '--card-accent': 'var(--brand-green)', '--card-accent-dim': 'var(--brand-green-dim)' } as React.CSSProperties,
  },
  {
    key: 'pointsInCirculation' as const,
    label: 'Points in Circulation',
    icon: Coins,
    format: (v: number) => v >= 1_000_000 ? `${(v / 1_000_000).toFixed(2)}M` : v.toLocaleString(),
    change: '+50K from Spotlight',
    changeDir: 'up' as const,
    css: { '--card-accent': '#f59e0b', '--card-accent-dim': 'rgba(245,158,11,0.12)' } as React.CSSProperties,
  },
];

export const NetworkOverview: React.FC = () => {
  const [stats, setStats] = useState<NetworkStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminApi.getNetworkStats().then(setStats).finally(() => setLoading(false));
  }, []);

  return (
    <div className="stat-grid fade-up">
      {STAT_DEFS.map(({ key, label, icon: Icon, format, change, changeDir, css }) => (
        <div className="stat-card" style={css} key={key}>
          <div className="stat-top">
            <span className="stat-label">{label}</span>
            <div className="stat-icon">
              <Icon size={15} />
            </div>
          </div>
          {loading ? (
            <div className="skeleton skeleton-stat" />
          ) : (
            <div className="stat-value">{stats ? format(stats[key]) : '—'}</div>
          )}
          <div className={`stat-change ${changeDir}`}>
            <TrendingUp size={10} style={{ display: 'inline', marginRight: 3 }} />
            {change}
          </div>
        </div>
      ))}

      {/* Extra derived cards */}
      <div className="stat-card" style={{ '--card-accent': 'var(--brand-pink)', '--card-accent-dim': 'var(--brand-pink-dim)' } as React.CSSProperties}>
        <div className="stat-top">
          <span className="stat-label">Avg Points / User</span>
          <div className="stat-icon" style={{ background: 'var(--brand-pink-dim)', color: 'var(--brand-pink)' }}>
            <UserCheck size={15} />
          </div>
        </div>
        {loading ? (
          <div className="skeleton skeleton-stat" />
        ) : (
          <div className="stat-value">
            {stats ? Math.round(stats.pointsInCirculation / Math.max(stats.activeUsers, 1)) : '—'}
          </div>
        )}
        <div className="stat-change up">↑ Healthy economy</div>
      </div>

      <div className="stat-card" style={{ '--card-accent': '#a78bfa', '--card-accent-dim': 'rgba(167,139,250,0.12)' } as React.CSSProperties}>
        <div className="stat-top">
          <span className="stat-label">Match Rate / User</span>
          <div className="stat-icon" style={{ background: 'rgba(167,139,250,0.12)', color: '#a78bfa' }}>
            <Zap size={15} />
          </div>
        </div>
        {loading ? (
          <div className="skeleton skeleton-stat" />
        ) : (
          <div className="stat-value">
            {stats ? (stats.totalMatches / Math.max(stats.activeUsers, 1)).toFixed(1) : '—'}
          </div>
        )}
        <div className="stat-change up">avg matches per user</div>
      </div>
    </div>
  );
};
