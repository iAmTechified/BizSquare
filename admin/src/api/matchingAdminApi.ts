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

export const matchingAdminApi = {
  async getAnalytics(): Promise<MatchingAnalyticsData> {
    const res = await fetch(`${API_BASE_URL}/analytics`);
    const json = await res.json();
    return json.data;
  },

  async runWeeklyCycle(): Promise<any> {
    const res = await fetch(`${API_BASE_URL}/cycles/run`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    });
    return res.json();
  },

  async getCycleDetails(cycleId: string): Promise<any> {
    const res = await fetch(`${API_BASE_URL}/cycles/${cycleId}`);
    const json = await res.json();
    return json.data;
  },

  async getUserMatchHistory(userId: string): Promise<any[]> {
    const res = await fetch(`${API_BASE_URL}/users/${userId}/matches`);
    const json = await res.json();
    return json.data;
  },
};
