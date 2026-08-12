import React, { useEffect, useState } from 'react';
import { fetchNetworkStats, type NetworkStats } from '../api/adminApi';
import { Users, Activity, Coins } from 'lucide-react';

export const NetworkOverview: React.FC = () => {
  const [stats, setStats] = useState<NetworkStats | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    const loadStats = async () => {
      try {
        const data = await fetchNetworkStats();
        setStats(data);
      } catch (error) {
        console.error('Failed to load stats', error);
      } finally {
        setLoading(false);
      }
    };
    loadStats();
  }, []);

  return (
    <section className="animate-fade-in">
      <h2 className="section-title">
        <Activity size={24} color="var(--accent-primary)" />
        Network Overview
      </h2>
      <div className="overview-grid">
        <div className="stat-card">
          <div className="stat-icon-wrapper">
            <Users size={28} />
          </div>
          <div className="stat-content">
            <span className="stat-label">Active Users</span>
            {loading ? (
              <div className="skeleton skeleton-stat"></div>
            ) : (
              <span className="stat-value">{stats?.activeUsers.toLocaleString()}</span>
            )}
          </div>
        </div>

        <div className="stat-card delay-100">
          <div className="stat-icon-wrapper" style={{ background: 'rgba(139, 92, 246, 0.1)', color: 'var(--accent-secondary)' }}>
            <Activity size={28} />
          </div>
          <div className="stat-content">
            <span className="stat-label">Total Matches</span>
            {loading ? (
              <div className="skeleton skeleton-stat"></div>
            ) : (
              <span className="stat-value">{stats?.totalMatches.toLocaleString()}</span>
            )}
          </div>
        </div>

        <div className="stat-card delay-200">
          <div className="stat-icon-wrapper" style={{ background: 'rgba(56, 189, 248, 0.1)', color: '#38bdf8' }}>
            <Coins size={28} />
          </div>
          <div className="stat-content">
            <span className="stat-label">Points in Circulation</span>
            {loading ? (
              <div className="skeleton skeleton-stat"></div>
            ) : (
              <span className="stat-value">{stats?.pointsInCirculation.toLocaleString()}</span>
            )}
          </div>
        </div>
      </div>
    </section>
  );
};
