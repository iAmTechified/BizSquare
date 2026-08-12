const BASE = 'http://localhost:8080/api/v1';

// ─── Auth Token Management ─────────────────────────────────────────────────

let _token: string | null = localStorage.getItem('admin_token');

export const setToken = (tok: string) => {
  _token = tok;
  localStorage.setItem('admin_token', tok);
};

export const clearToken = () => {
  _token = null;
  localStorage.removeItem('admin_token');
};

export const getToken = () => _token;

// ─── Core Fetch Helper ─────────────────────────────────────────────────────

async function apiFetch<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(opts.headers as Record<string, string>),
  };

  if (_token) headers['Authorization'] = `Bearer ${_token}`;

  const res = await fetch(`${BASE}${path}`, { ...opts, headers });

  if (res.status === 401) {
    clearToken();
    window.location.reload();
    throw new Error('Unauthorized');
  }

  const json = await res.json();

  if (!res.ok) {
    throw new Error(json.error || `Request failed (${res.status})`);
  }

  return json as T;
}

// ─── Types ─────────────────────────────────────────────────────────────────

export interface NetworkStats {
  activeUsers: number;
  totalMatches: number;
  pointsInCirculation: number;
}

export interface AdminUser {
  id: string;
  full_name: string;
  phone_number: string;
  akawo_points: number;
  access_level: string;
  is_active: boolean;
  last_login: string | null;
  created_at: string;
}

export interface LedgerEntry {
  id: string;
  user_id: string;
  points_awarded: number;
  reason: string;
  verified_by_bot: boolean;
  created_at: string;
  user_name?: string;
}

export interface SpotlightCampaign {
  id: string;
  user_id: string;
  business_name: string;
  title: string;
  promo_text: string;
  flyer_url: string | null;
  status: 'active' | 'scheduled' | 'completed' | 'pending';
  participants_count: number;
  points_awarded: number;
  starts_at: string;
  ends_at: string;
  created_at: string;
}

// ─── Network Analytics ─────────────────────────────────────────────────────

export const adminApi = {
  async getNetworkStats(): Promise<NetworkStats> {
    try {
      const data = await apiFetch<{
        active_users: number;
        total_matches: number;
        total_points_in_circulation: number;
      }>('/admin/analytics/network');
      return {
        activeUsers: data.active_users,
        totalMatches: data.total_matches,
        pointsInCirculation: data.total_points_in_circulation,
      };
    } catch {
      // Fallback mock while backend is running without auth
      return { activeUsers: 14285, totalMatches: 89340, pointsInCirculation: 1250000 };
    }
  },

  // ─── Users ────────────────────────────────────────────────────────────────

  async getUsers(params?: { limit?: number; offset?: number; search?: string }): Promise<AdminUser[]> {
    const qs = new URLSearchParams();
    if (params?.limit) qs.set('limit', String(params.limit));
    if (params?.offset) qs.set('offset', String(params.offset));
    try {
      const data = await apiFetch<{ users: AdminUser[] }>(`/admin/users?${qs}`);
      return data.users;
    } catch {
      return MOCK_USERS;
    }
  },

  async suspendUser(id: string, suspend: boolean): Promise<void> {
    await apiFetch(`/admin/users/${id}/suspend`, {
      method: 'POST',
      body: JSON.stringify({ suspend }),
    });
  },

  async adjustPoints(userId: string, points: number, reason: string): Promise<void> {
    await apiFetch('/admin/points/award', {
      method: 'POST',
      body: JSON.stringify({ userId, points, reason }),
    });
  },

  // ─── Points Ledger ────────────────────────────────────────────────────────

  async getLedger(params?: { userId?: string; limit?: number }): Promise<LedgerEntry[]> {
    const qs = new URLSearchParams();
    if (params?.userId) qs.set('userId', params.userId);
    if (params?.limit) qs.set('limit', String(params.limit));
    try {
      const data = await apiFetch<{ entries: LedgerEntry[] }>(`/admin/ledger?${qs}`);
      return data.entries;
    } catch {
      return MOCK_LEDGER;
    }
  },

  // ─── Spotlight ────────────────────────────────────────────────────────────

  async getSpotlightCampaigns(): Promise<SpotlightCampaign[]> {
    try {
      const data = await apiFetch<{ campaigns: SpotlightCampaign[] }>('/admin/spotlight/campaigns');
      return data.campaigns;
    } catch {
      return MOCK_CAMPAIGNS;
    }
  },

  async getCampaignParticipants(campaignId: string) {
    try {
      const data = await apiFetch<{ data: any[] }>(`/spotlight/campaign/${campaignId}/participants`);
      return data.data;
    } catch {
      return [];
    }
  },
};

// ─── Mock Data (graceful fallback when API not connected) ──────────────────

const MOCK_USERS: AdminUser[] = [
  { id: 'usr_a1b2', full_name: 'Amara Okonkwo', phone_number: '+2348012345678', akawo_points: 840, access_level: 'user', is_active: true, last_login: '2026-08-11T14:32:00Z', created_at: '2026-01-15T10:00:00Z' },
  { id: 'usr_c3d4', full_name: 'Kehinde Adeyemi', phone_number: '+2348087654321', akawo_points: 1200, access_level: 'user', is_active: true, last_login: '2026-08-10T09:00:00Z', created_at: '2026-02-20T08:30:00Z' },
  { id: 'usr_e5f6', full_name: 'Funmi Balogun', phone_number: '+2348065432100', akawo_points: 0, access_level: 'user', is_active: false, last_login: null, created_at: '2026-03-01T11:15:00Z' },
  { id: 'usr_g7h8', full_name: 'Tunde Fashola', phone_number: '+2349011223344', akawo_points: 560, access_level: 'user', is_active: true, last_login: '2026-08-12T07:00:00Z', created_at: '2026-04-10T13:00:00Z' },
  { id: 'usr_i9j0', full_name: 'Ngozi Eze', phone_number: '+2348055667788', akawo_points: 2100, access_level: 'user', is_active: true, last_login: '2026-08-11T20:15:00Z', created_at: '2026-05-05T09:45:00Z' },
  { id: 'usr_k1l2', full_name: 'Babatunde Osei', phone_number: '+2348099887766', akawo_points: 340, access_level: 'user', is_active: true, last_login: '2026-08-09T16:00:00Z', created_at: '2026-06-18T14:30:00Z' },
];

const MOCK_LEDGER: LedgerEntry[] = [
  { id: 'led_1', user_id: 'usr_i9j0', points_awarded: 50, reason: 'Spotlight share verified', verified_by_bot: true, created_at: '2026-08-12T06:30:00Z', user_name: 'Ngozi Eze' },
  { id: 'led_2', user_id: 'usr_a1b2', points_awarded: 50, reason: 'Spotlight share verified', verified_by_bot: true, created_at: '2026-08-12T06:28:00Z', user_name: 'Amara Okonkwo' },
  { id: 'led_3', user_id: 'usr_c3d4', points_awarded: 100, reason: 'Weekly batch bonus — top network contributor', verified_by_bot: false, created_at: '2026-08-11T18:00:00Z', user_name: 'Kehinde Adeyemi' },
  { id: 'led_4', user_id: 'usr_g7h8', points_awarded: -100, reason: 'Admin deduction — ToS violation', verified_by_bot: false, created_at: '2026-08-10T12:00:00Z', user_name: 'Tunde Fashola' },
  { id: 'led_5', user_id: 'usr_k1l2', points_awarded: 50, reason: 'Spotlight share verified', verified_by_bot: true, created_at: '2026-08-10T08:45:00Z', user_name: 'Babatunde Osei' },
  { id: 'led_6', user_id: 'usr_i9j0', points_awarded: 200, reason: 'Referral bonus — 4 active signups', verified_by_bot: false, created_at: '2026-08-09T14:30:00Z', user_name: 'Ngozi Eze' },
];

const MOCK_CAMPAIGNS: SpotlightCampaign[] = [
  { id: 'cmp_1', user_id: 'usr_i9j0', business_name: 'Ngozi Eze Couture', title: 'Custom Ankara Bridal Gowns', promo_text: 'Bespoke bridal fashion for your dream day.', flyer_url: null, status: 'active', participants_count: 47, points_awarded: 2350, starts_at: '2026-08-12T00:00:00Z', ends_at: '2026-08-13T00:00:00Z', created_at: '2026-08-11T22:00:00Z' },
  { id: 'cmp_2', user_id: 'usr_c3d4', business_name: 'Kehinde Digital Hub', title: 'Affordable Website Design', promo_text: '1-page landing sites from ₦25,000.', flyer_url: null, status: 'scheduled', participants_count: 0, points_awarded: 0, starts_at: '2026-08-13T00:00:00Z', ends_at: '2026-08-14T00:00:00Z', created_at: '2026-08-10T09:00:00Z' },
  { id: 'cmp_3', user_id: 'usr_a1b2', business_name: 'Amara Fresh Organic', title: 'Premium Farm-to-Table Baskets', promo_text: 'Weekly organic produce delivery in Lagos.', flyer_url: null, status: 'completed', participants_count: 61, points_awarded: 3050, starts_at: '2026-08-11T00:00:00Z', ends_at: '2026-08-12T00:00:00Z', created_at: '2026-08-09T18:00:00Z' },
  { id: 'cmp_4', user_id: 'usr_g7h8', business_name: 'Tunde AutoGlass', title: 'Same-Day Windscreen Repair', promo_text: 'Mobile windscreen repair service. We come to you.', flyer_url: null, status: 'completed', participants_count: 38, points_awarded: 1900, starts_at: '2026-08-10T00:00:00Z', ends_at: '2026-08-11T00:00:00Z', created_at: '2026-08-08T12:00:00Z' },
];
