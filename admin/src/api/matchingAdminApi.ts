const API_BASE_URL = 'http://localhost:8080/api/v1/matching';

export interface MatchingAnalyticsData {
  activeNetworkSize: number;
  totalCycles: number;
  totalContactsAllocated: number;
  tierDistribution: {
    tier1: number;
    tier2: number;
    tier3: number;
  };
  totalCompetitorExclusions: number;
  avgDurationMs: number;
  topSupplyCategories: {
    niche: string;
    count: number;
  }[];
  mostExposedSuppliers: {
    userId: string;
    businessName: string;
    primaryOffer: string;
    connections: number;
  }[];
  recentCycles: {
    id: string;
    cycleNumber: number;
    batchDate: string;
    networkSize: number;
    targetPerUser: number;
    status: string;
    usersProcessed: number;
    usersFilled: number;
    usersUnderfilled: number;
    totalAllocations: number;
    tier1Count: number;
    tier2Count: number;
    tier3Count: number;
    competitorExclusionsCount: number;
    executionDurationMs: number;
    createdAt: string;
  }[];
}

// ─── Mock data (used when backend is offline) ──────────────────────────────

const MOCK_ANALYTICS: MatchingAnalyticsData = {
  activeNetworkSize: 14285,
  totalCycles: 8,
  totalContactsAllocated: 102340,
  tierDistribution: { tier1: 71638, tier2: 20468, tier3: 10234 },
  totalCompetitorExclusions: 3210,
  avgDurationMs: 342,
  topSupplyCategories: [
    { niche: 'Fashion & Apparel', count: 1842 },
    { niche: 'Food & Beverages', count: 1560 },
    { niche: 'Digital Services', count: 1380 },
    { niche: 'Beauty & Wellness', count: 1190 },
    { niche: 'Real Estate', count: 980 },
    { niche: 'Auto & Transport', count: 760 },
  ],
  mostExposedSuppliers: [
    { userId: 'usr_i9j0', businessName: 'Ngozi Eze Couture', primaryOffer: 'Bridal Fashion', connections: 1428 },
    { userId: 'usr_a1b2', businessName: 'Amara Fresh Organic', primaryOffer: 'Organic Produce', connections: 1285 },
    { userId: 'usr_c3d4', businessName: 'Kehinde Digital Hub', primaryOffer: 'Web Design', connections: 1140 },
  ],
  recentCycles: [
    {
      id: 'cyc_001', cycleNumber: 8, batchDate: '2026-08-10', networkSize: 14285, targetPerUser: 1428,
      status: 'SUCCESS', usersProcessed: 14285, usersFilled: 13902, usersUnderfilled: 383,
      totalAllocations: 19823040, tier1Count: 13892, tier2Count: 280, tier3Count: 113,
      competitorExclusionsCount: 412, executionDurationMs: 338, createdAt: '2026-08-10T00:00:43Z',
    },
    {
      id: 'cyc_002', cycleNumber: 7, batchDate: '2026-08-03', networkSize: 13820, targetPerUser: 1382,
      status: 'SUCCESS', usersProcessed: 13820, usersFilled: 13410, usersUnderfilled: 410,
      totalAllocations: 18530040, tier1Count: 13300, tier2Count: 260, tier3Count: 260,
      competitorExclusionsCount: 388, executionDurationMs: 321, createdAt: '2026-08-03T00:00:31Z',
    },
    {
      id: 'cyc_003', cycleNumber: 6, batchDate: '2026-07-27', networkSize: 13340, targetPerUser: 1334,
      status: 'SUCCESS', usersProcessed: 13340, usersFilled: 12980, usersUnderfilled: 360,
      totalAllocations: 17316520, tier1Count: 12800, tier2Count: 380, tier3Count: 160,
      competitorExclusionsCount: 356, executionDurationMs: 304, createdAt: '2026-07-27T00:00:28Z',
    },
  ],
};

// ─── API Client ────────────────────────────────────────────────────────────

export const matchingAdminApi = {
  async getAnalytics(): Promise<MatchingAnalyticsData> {
    try {
      const res = await fetch(`${API_BASE_URL}/analytics`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json();
      return json.data ?? json;
    } catch {
      // Gracefully fall back to mock data when backend is offline
      return MOCK_ANALYTICS;
    }
  },

  async runWeeklyCycle(): Promise<any> {
    try {
      const res = await fetch(`${API_BASE_URL}/cycles/run`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });
      return res.json();
    } catch {
      throw new Error('Backend is offline. Cannot run matching cycle.');
    }
  },

  async getCycleDetails(cycleId: string): Promise<any> {
    try {
      const res = await fetch(`${API_BASE_URL}/cycles/${cycleId}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json();
      return json.data ?? json;
    } catch {
      // Return mock cycle detail
      const cycle = MOCK_ANALYTICS.recentCycles.find(c => c.id === cycleId) ?? MOCK_ANALYTICS.recentCycles[0];
      return {
        cycle: { ...cycle, cycle_number: cycle.cycleNumber },
        userSummaries: Array.from({ length: 5 }, (_, i) => ({
          business_name: ['Ngozi Eze Couture', 'Amara Fresh Organic', 'Kehinde Digital Hub', 'Tunde AutoGlass', 'Babatunde Prints'][i],
          allocated_count: cycle.targetPerUser - i * 2,
          target_count: cycle.targetPerUser,
          tier_1_allocated: cycle.targetPerUser - i * 3,
          tier_2_allocated: i,
          tier_3_allocated: Math.max(0, i - 1),
          allocation_status: i < 4 ? 'FILLED' : 'UNDERFILLED',
          underfill_reason: i >= 4 ? 'Insufficient cross-niche candidates' : null,
        })),
      };
    }
  },

  async getUserMatchHistory(userId: string): Promise<any[]> {
    try {
      const res = await fetch(`${API_BASE_URL}/users/${userId}/matches`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json();
      return json.data ?? json;
    } catch {
      return [];
    }
  },
};
