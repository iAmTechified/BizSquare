import { useState, useEffect } from 'react';
import { matchingAdminApi } from '../api/matchingAdminApi';
import type { MatchingAnalyticsData } from '../api/matchingAdminApi';
import { 
  Network, 
  Zap, 
  ShieldCheck, 
  Clock, 
  CheckCircle2, 
  Layers, 
  RefreshCw,
  Search,
  Eye,
  TrendingUp,
  Award
} from 'lucide-react';

export function MatchingEngineDashboard() {
  const [data, setData] = useState<MatchingAnalyticsData | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [runningCycle, setRunningCycle] = useState<boolean>(false);
  const [selectedCycleId, setSelectedCycleId] = useState<string | null>(null);
  const [cycleDetails, setCycleDetails] = useState<any | null>(null);
  const [searchUserId, setSearchUserId] = useState<string>('');
  const [userMatches, setUserMatches] = useState<any[] | null>(null);
  const [searchingMatches, setSearchingMatches] = useState<boolean>(false);

  const fetchAnalytics = async () => {
    try {
      setLoading(true);
      const res = await matchingAdminApi.getAnalytics();
      setData(res);
    } catch (err) {
      console.error('Failed to load matching analytics:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAnalytics();
  }, []);

  const handleRunCycle = async () => {
    if (!window.confirm('Are you sure you want to run the weekly matching cycle for all eligible users now?')) return;
    try {
      setRunningCycle(true);
      const res = await matchingAdminApi.runWeeklyCycle();
      alert(`Weekly Matching Cycle #${res.data?.cycleNumber || ''} completed!\nTotal Contacts Allocated: ${res.data?.totalAllocations || 0}\nTier 1: ${res.data?.tier1Count || 0} | Tier 2: ${res.data?.tier2Count || 0} | Tier 3: ${res.data?.tier3Count || 0}`);
      await fetchAnalytics();
    } catch (err: any) {
      alert(`Matching cycle execution failed: ${err.message}`);
    } finally {
      setRunningCycle(false);
    }
  };

  const handleViewCycle = async (cycleId: string) => {
    setSelectedCycleId(cycleId);
    try {
      const res = await matchingAdminApi.getCycleDetails(cycleId);
      setCycleDetails(res);
    } catch (err) {
      console.error('Failed to load cycle details:', err);
    }
  };

  const handleSearchUserMatches = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchUserId.trim()) return;
    try {
      setSearchingMatches(true);
      const matches = await matchingAdminApi.getUserMatchHistory(searchUserId.trim());
      setUserMatches(matches);
    } catch (err) {
      console.error('Failed to fetch user match history:', err);
    } finally {
      setSearchingMatches(false);
    }
  };

  if (loading && !data) {
    return (
      <div style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-secondary)' }}>
        <RefreshCw className="animate-spin" size={32} style={{ margin: '0 auto 1rem' }} />
        <p>Loading Matching Engine & Contact Gain Analytics...</p>
      </div>
    );
  }

  const targetPerUser = data ? Math.max(1, Math.floor(data.activeNetworkSize * 0.10)) : 0;
  const totalTierSum = data ? (data.tierDistribution.tier1 + data.tierDistribution.tier2 + data.tierDistribution.tier3) || 1 : 1;
  const tier1Pct = data ? Math.round((data.tierDistribution.tier1 / totalTierSum) * 100) : 0;
  const tier2Pct = data ? Math.round((data.tierDistribution.tier2 / totalTierSum) * 100) : 0;
  const tier3Pct = data ? Math.round((data.tierDistribution.tier3 / totalTierSum) * 100) : 0;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
      {/* Top Banner & Run Action */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        background: 'linear-gradient(135deg, rgba(0, 88, 255, 0.12), rgba(90, 255, 0, 0.08))',
        padding: '1.5rem 2rem',
        borderRadius: '16px',
        border: '1px solid rgba(0, 88, 255, 0.25)',
      }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginBottom: '0.3rem' }}>
            <Zap size={22} color="#0058FF" />
            <h2 style={{ fontSize: '1.3rem', fontWeight: 800, margin: 0, color: 'var(--text-primary)' }}>
              Weekly Matching Engine & Contact Gain
            </h2>
          </div>
          <p style={{ margin: 0, fontSize: '13px', color: 'var(--text-secondary)' }}>
            Automatically introduces reciprocal contacts (A ↔ B) every week based on staged demand & supply with strict competitor protection.
          </p>
        </div>

        <button
          onClick={handleRunCycle}
          disabled={runningCycle}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.6rem',
            background: 'linear-gradient(135deg, #0058FF, #0045CC)',
            color: '#FFFFFF',
            padding: '0.8rem 1.6rem',
            borderRadius: '10px',
            border: 'none',
            fontWeight: 800,
            fontSize: '14px',
            cursor: runningCycle ? 'not-allowed' : 'pointer',
            boxShadow: '0 4px 14px rgba(0, 88, 255, 0.35)',
            opacity: runningCycle ? 0.7 : 1,
            transition: 'all 0.2s ease',
          }}
        >
          {runningCycle ? (
            <>
              <RefreshCw className="animate-spin" size={18} />
              Executing Matching Cycle...
            </>
          ) : (
            <>
              <Zap size={18} />
              Run Weekly Matching Cycle ⚡
            </>
          )}
        </button>
      </div>

      {/* KPI Cards */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: '1.2rem',
      }}>
        <div style={{
          background: 'var(--surface-color)',
          padding: '1.2rem 1.5rem',
          borderRadius: '12px',
          border: '1px solid var(--border-color)',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)', fontSize: '12px', fontWeight: 600 }}>
            <span>ELIGIBLE NETWORK</span>
            <Network size={16} color="#0058FF" />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: 'var(--text-primary)', marginTop: '0.4rem' }}>
            {data?.activeNetworkSize || 0}
          </div>
          <span style={{ fontSize: '11px', color: '#5AFF00', fontWeight: 600 }}>Active onboarded users</span>
        </div>

        <div style={{
          background: 'var(--surface-color)',
          padding: '1.2rem 1.5rem',
          borderRadius: '12px',
          border: '1px solid var(--border-color)',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)', fontSize: '12px', fontWeight: 600 }}>
            <span>10% TARGET CAP</span>
            <TrendingUp size={16} color="#5AFF00" />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#5AFF00', marginTop: '0.4rem' }}>
            {targetPerUser} <span style={{ fontSize: '14px', fontWeight: 500, color: 'var(--text-secondary)' }}>contacts/user</span>
          </div>
          <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>Floor(10% of network)</span>
        </div>

        <div style={{
          background: 'var(--surface-color)',
          padding: '1.2rem 1.5rem',
          borderRadius: '12px',
          border: '1px solid var(--border-color)',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)', fontSize: '12px', fontWeight: 600 }}>
            <span>CONTACTS ALLOCATED</span>
            <CheckCircle2 size={16} color="#0058FF" />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: 'var(--text-primary)', marginTop: '0.4rem' }}>
            {data?.totalContactsAllocated || 0}
          </div>
          <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>Across {data?.totalCycles || 0} weekly cycles</span>
        </div>

        <div style={{
          background: 'var(--surface-color)',
          padding: '1.2rem 1.5rem',
          borderRadius: '12px',
          border: '1px solid var(--border-color)',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)', fontSize: '12px', fontWeight: 600 }}>
            <span>COMPETITOR EXCLUSIONS</span>
            <ShieldCheck size={16} color="#FF00A6" />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#FF00A6', marginTop: '0.4rem' }}>
            {data?.totalCompetitorExclusions || 0}
          </div>
          <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>Primary collisions blocked</span>
        </div>

        <div style={{
          background: 'var(--surface-color)',
          padding: '1.2rem 1.5rem',
          borderRadius: '12px',
          border: '1px solid var(--border-color)',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)', fontSize: '12px', fontWeight: 600 }}>
            <span>AVG CYCLE SPEED</span>
            <Clock size={16} color="#0058FF" />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: 'var(--text-primary)', marginTop: '0.4rem' }}>
            {data?.avgDurationMs || 0} <span style={{ fontSize: '14px', fontWeight: 500, color: 'var(--text-secondary)' }}>ms</span>
          </div>
          <span style={{ fontSize: '11px', color: '#5AFF00' }}>Transactional speed</span>
        </div>
      </div>

      {/* Tier Distribution & Supply/Exposure Balance */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
        {/* Tier Priority Quality Distribution */}
        <div style={{
          background: 'var(--surface-color)',
          padding: '1.5rem',
          borderRadius: '14px',
          border: '1px solid var(--border-color)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1.2rem' }}>
            <Layers size={18} color="#0058FF" />
            <h3 style={{ fontSize: '14px', fontWeight: 700, margin: 0 }}>Match Tier Quality Breakdown</h3>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', marginBottom: '0.3rem' }}>
                <span style={{ fontWeight: 600, color: '#0058FF' }}>Tier 1: Primary Supply Matches</span>
                <span>{data?.tierDistribution.tier1 || 0} ({tier1Pct}%)</span>
              </div>
              <div style={{ height: '8px', background: 'rgba(255,255,255,0.08)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: `${tier1Pct}%`, height: '100%', background: '#0058FF' }} />
              </div>
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', marginBottom: '0.3rem' }}>
                <span style={{ fontWeight: 600, color: '#5AFF00' }}>Tier 2: Secondary Supply Matches</span>
                <span>{data?.tierDistribution.tier2 || 0} ({tier2Pct}%)</span>
              </div>
              <div style={{ height: '8px', background: 'rgba(255,255,255,0.08)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: `${tier2Pct}%`, height: '100%', background: '#5AFF00' }} />
              </div>
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', marginBottom: '0.3rem' }}>
                <span style={{ fontWeight: 600, color: '#FF00A6' }}>Tier 3: Fallback Network Expansion</span>
                <span>{data?.tierDistribution.tier3 || 0} ({tier3Pct}%)</span>
              </div>
              <div style={{ height: '8px', background: 'rgba(255,255,255,0.08)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: `${tier3Pct}%`, height: '100%', background: '#FF00A6' }} />
              </div>
            </div>
          </div>
        </div>

        {/* Top Supply & Balancing */}
        <div style={{
          background: 'var(--surface-color)',
          padding: '1.5rem',
          borderRadius: '14px',
          border: '1px solid var(--border-color)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1.2rem' }}>
            <Award size={18} color="#5AFF00" />
            <h3 style={{ fontSize: '14px', fontWeight: 700, margin: 0 }}>Top Network Supply Niches</h3>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.8rem' }}>
            {data?.topSupplyCategories.map((cat, idx) => (
              <div key={idx} style={{
                background: 'rgba(255, 255, 255, 0.04)',
                padding: '0.7rem 1rem',
                borderRadius: '8px',
                border: '1px solid var(--border-color)',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}>
                <span style={{ fontSize: '13px', fontWeight: 600 }}>{cat.niche}</span>
                <span style={{
                  fontSize: '11px',
                  fontWeight: 700,
                  background: 'rgba(0, 88, 255, 0.15)',
                  color: '#0058FF',
                  padding: '2px 8px',
                  borderRadius: '12px',
                }}>
                  {cat.count} suppliers
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Weekly Cycle History Table */}
      <div style={{
        background: 'var(--surface-color)',
        borderRadius: '14px',
        border: '1px solid var(--border-color)',
        overflow: 'hidden',
      }}>
        <div style={{
          padding: '1.2rem 1.5rem',
          borderBottom: '1px solid var(--border-color)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}>
          <h3 style={{ fontSize: '15px', fontWeight: 700, margin: 0 }}>Weekly Matching Cycle History</h3>
          <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
            Showing {data?.recentCycles.length || 0} batches
          </span>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
            <thead>
              <tr style={{ background: 'rgba(255, 255, 255, 0.02)', textAlign: 'left', color: 'var(--text-secondary)' }}>
                <th style={{ padding: '0.8rem 1.2rem' }}>CYCLE #</th>
                <th style={{ padding: '0.8rem 1.2rem' }}>BATCH DATE</th>
                <th style={{ padding: '0.8rem 1.2rem' }}>NETWORK</th>
                <th style={{ padding: '0.8rem 1.2rem' }}>TARGET CAP</th>
                <th style={{ padding: '0.8rem 1.2rem' }}>FILLED / UNDERFILLED</th>
                <th style={{ padding: '0.8rem 1.2rem' }}>TIER 1/2/3</th>
                <th style={{ padding: '0.8rem 1.2rem' }}>TOTAL ALLOCATED</th>
                <th style={{ padding: '0.8rem 1.2rem' }}>DURATION</th>
                <th style={{ padding: '0.8rem 1.2rem' }}>STATUS</th>
                <th style={{ padding: '0.8rem 1.2rem' }}>ACTIONS</th>
              </tr>
            </thead>
            <tbody>
              {data?.recentCycles.length === 0 ? (
                <tr>
                  <td colSpan={10} style={{ padding: '2rem', textAlign: 'center', color: 'var(--text-secondary)' }}>
                    No matching cycles executed yet. Click "Run Weekly Matching Cycle" above to run the first batch.
                  </td>
                </tr>
              ) : (
                data?.recentCycles.map((c) => (
                  <tr key={c.id} style={{ borderTop: '1px solid var(--border-color)' }}>
                    <td style={{ padding: '0.8rem 1.2rem', fontWeight: 700 }}>#{c.cycleNumber}</td>
                    <td style={{ padding: '0.8rem 1.2rem' }}>{new Date(c.batchDate).toLocaleDateString()}</td>
                    <td style={{ padding: '0.8rem 1.2rem' }}>{c.networkSize}</td>
                    <td style={{ padding: '0.8rem 1.2rem', color: '#5AFF00', fontWeight: 600 }}>{c.targetPerUser}</td>
                    <td style={{ padding: '0.8rem 1.2rem' }}>
                      <span style={{ color: '#5AFF00' }}>{c.usersFilled} filled</span> / <span style={{ color: c.usersUnderfilled > 0 ? '#FF00A6' : 'var(--text-secondary)' }}>{c.usersUnderfilled} underfilled</span>
                    </td>
                    <td style={{ padding: '0.8rem 1.2rem' }}>
                      <span style={{ color: '#0058FF' }}>{c.tier1Count}</span> / <span style={{ color: '#5AFF00' }}>{c.tier2Count}</span> / <span style={{ color: '#FF00A6' }}>{c.tier3Count}</span>
                    </td>
                    <td style={{ padding: '0.8rem 1.2rem', fontWeight: 700 }}>{c.totalAllocations}</td>
                    <td style={{ padding: '0.8rem 1.2rem', color: 'var(--text-secondary)' }}>{c.executionDurationMs}ms</td>
                    <td style={{ padding: '0.8rem 1.2rem' }}>
                      <span style={{
                        background: 'rgba(90, 255, 0, 0.15)',
                        color: '#5AFF00',
                        padding: '2px 8px',
                        borderRadius: '4px',
                        fontSize: '11px',
                        fontWeight: 700,
                      }}>
                        {c.status}
                      </span>
                    </td>
                    <td style={{ padding: '0.8rem 1.2rem' }}>
                      <button
                        onClick={() => handleViewCycle(c.id)}
                        style={{
                          background: 'transparent',
                          border: '1px solid var(--border-color)',
                          color: 'var(--text-primary)',
                          padding: '4px 8px',
                          borderRadius: '6px',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '4px',
                          fontSize: '11px',
                        }}
                      >
                        <Eye size={12} /> Inspect
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Cycle Details Modal / Inspector */}
      {selectedCycleId && cycleDetails && (
        <div style={{
          background: 'var(--surface-color)',
          padding: '1.5rem',
          borderRadius: '14px',
          border: '1px solid #0058FF',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <h3 style={{ fontSize: '15px', fontWeight: 700, margin: 0 }}>
              Cycle #{cycleDetails.cycle.cycle_number} User Allocation Summaries
            </h3>
            <button
              onClick={() => { setSelectedCycleId(null); setCycleDetails(null); }}
              style={{ background: 'transparent', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', fontWeight: 700 }}
            >
              Close ✕
            </button>
          </div>

          <div style={{ maxHeight: '300px', overflowY: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '12px' }}>
              <thead>
                <tr style={{ textAlign: 'left', color: 'var(--text-secondary)' }}>
                  <th style={{ padding: '6px 8px' }}>User</th>
                  <th style={{ padding: '6px 8px' }}>Allocated / Target</th>
                  <th style={{ padding: '6px 8px' }}>Tier 1 / 2 / 3</th>
                  <th style={{ padding: '6px 8px' }}>Status</th>
                  <th style={{ padding: '6px 8px' }}>Reason</th>
                </tr>
              </thead>
              <tbody>
                {cycleDetails.userSummaries.map((s: any, idx: number) => (
                  <tr key={idx} style={{ borderTop: '1px solid var(--border-color)' }}>
                    <td style={{ padding: '6px 8px', fontWeight: 600 }}>{s.business_name}</td>
                    <td style={{ padding: '6px 8px' }}>{s.allocated_count} / {s.target_count}</td>
                    <td style={{ padding: '6px 8px' }}>{s.tier_1_allocated} / {s.tier_2_allocated} / {s.tier_3_allocated}</td>
                    <td style={{ padding: '6px 8px' }}>
                      <span style={{
                        color: s.allocation_status === 'FILLED' ? '#5AFF00' : '#FF00A6',
                        fontWeight: 700
                      }}>
                        {s.allocation_status}
                      </span>
                    </td>
                    <td style={{ padding: '6px 8px', color: 'var(--text-secondary)' }}>{s.underfill_reason || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* User Match & Explainability Inspector */}
      <div style={{
        background: 'var(--surface-color)',
        padding: '1.5rem',
        borderRadius: '14px',
        border: '1px solid var(--border-color)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
          <Search size={18} color="#0058FF" />
          <h3 style={{ fontSize: '14px', fontWeight: 700, margin: 0 }}>Individual User Match & Explainability Inspector</h3>
        </div>

        <form onSubmit={handleSearchUserMatches} style={{ display: 'flex', gap: '0.8rem', marginBottom: '1.2rem' }}>
          <input
            type="text"
            placeholder="Enter User UUID..."
            value={searchUserId}
            onChange={(e) => setSearchUserId(e.target.value)}
            style={{
              flex: 1,
              background: 'rgba(255, 255, 255, 0.05)',
              border: '1px solid var(--border-color)',
              color: 'var(--text-primary)',
              padding: '0.6rem 1rem',
              borderRadius: '8px',
              fontSize: '13px',
            }}
          />
          <button
            type="submit"
            disabled={searchingMatches}
            style={{
              background: '#0058FF',
              color: '#FFFFFF',
              border: 'none',
              borderRadius: '8px',
              padding: '0.6rem 1.4rem',
              fontWeight: 700,
              fontSize: '13px',
              cursor: 'pointer',
            }}
          >
            Inspect Matches
          </button>
        </form>

        {userMatches && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem' }}>
            {userMatches.length === 0 ? (
              <p style={{ color: 'var(--text-secondary)', fontSize: '13px', textAlign: 'center' }}>
                No match history found for this user.
              </p>
            ) : (
              userMatches.map((m, idx) => (
                <div key={idx} style={{
                  background: 'rgba(255, 255, 255, 0.02)',
                  border: '1px solid var(--border-color)',
                  padding: '1rem',
                  borderRadius: '8px',
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.4rem' }}>
                    <span style={{ fontWeight: 700, fontSize: '14px', color: 'var(--text-primary)' }}>
                      #{m.allocation_position} {m.candidate_business_name} ({m.candidate_primary_offer})
                    </span>
                    <span style={{
                      fontSize: '11px',
                      fontWeight: 700,
                      color: m.tier === 'TIER_1' ? '#0058FF' : m.tier === 'TIER_2' ? '#5AFF00' : '#FF00A6',
                      background: 'rgba(255,255,255,0.06)',
                      padding: '2px 8px',
                      borderRadius: '4px',
                    }}>
                      {m.tier} • Score: {m.score}
                    </span>
                  </div>
                  <p style={{ margin: '0 0 0.4rem', fontSize: '13px', color: 'var(--text-secondary)' }}>
                    {m.explanation_text}
                  </p>
                  <div style={{ display: 'flex', gap: '1rem', fontSize: '11px', color: 'var(--text-secondary)' }}>
                    <span>Reason: <strong>{m.match_reason}</strong></span>
                    {m.interest_used && <span>Interest: <strong>{m.interest_used}</strong> ({(m.interest_weight * 100).toFixed(1)}%)</span>}
                    {m.mutual_match && <span style={{ color: '#5AFF00', fontWeight: 700 }}>✓ Mutual Demand Match</span>}
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </div>
    </div>
  );
}
