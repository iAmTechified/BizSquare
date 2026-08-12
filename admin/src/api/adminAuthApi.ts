const API_BASE = 'http://localhost:8080/api/v1';

export interface AdminUser {
  id: string;
  full_name: string;
  phone_number: string;
  access_level: 'super_admin' | 'admin' | 'support_admin';
  permissions: string[];
  created_at: string;
}

export interface SystemHealthData {
  status: 'healthy' | 'degraded';
  timestamp: string;
  uptime_seconds: number;
  node_version: string;
  environment: string;
  database: {
    status: 'connected' | 'disconnected' | 'error';
    latency_ms: number;
  };
  memory: {
    rss_mb: number;
    heap_used_mb: number;
    heap_total_mb: number;
  };
}

export interface AuditLogItem {
  id: string;
  admin_user_id: string;
  admin_name: string;
  admin_phone: string;
  action: string;
  resource_type: string;
  resource_id: string | null;
  metadata: Record<string, any>;
  ip_address: string;
  result: 'success' | 'failure';
  created_at: string;
}

export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

let _token: string | null = localStorage.getItem('bizsquare_admin_token');

export const setAdminToken = (token: string) => {
  _token = token;
  localStorage.setItem('bizsquare_admin_token', token);
};

export const clearAdminToken = () => {
  _token = null;
  localStorage.removeItem('bizsquare_admin_token');
};

export const getAdminToken = () => _token;

async function adminFetch<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (_token) {
    headers['Authorization'] = `Bearer ${_token}`;
  }

  try {
    const res = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
    const json = await res.json().catch(() => ({}));

    if (!res.ok) {
      const errorMessage = json.error || `HTTP ${res.status}: Request failed`;
      throw new ApiError(errorMessage, res.status);
    }

    return json as T;
  } catch (error: any) {
    if (error instanceof ApiError) {
      throw error;
    }
    // Network / Offline failure
    throw new ApiError(error.message || 'Network connection failure. Backend API server unreachable.', 0);
  }
}

export interface OverviewData {
  success: boolean;
  timestamp: string;
  range: 'today' | '7d' | '30d';
  users: {
    total_users: number;
    active_users: number;
    suspended_users: number;
    new_users_in_period: number;
  };
  contactGain: {
    latest_cycle: {
      id: string;
      cycle_number: number;
      batch_date: string;
      status: string;
      users_processed: number;
      total_allocations: number;
      users_underfilled: number;
    } | null;
    contacts_gained_in_period: number;
    sync_failures: number;
  };
  spotlight: {
    active_campaign: {
      id: string;
      business_name: string;
      title: string;
      owner_name: string;
      status: string;
      participants_count: number;
    } | null;
    pending_reviews_count: number;
  };
  notifications: {
    sent_in_period: number;
    failed_in_period: number;
    scheduled: number;
  };
  attentionItems: Array<{
    id: string;
    severity: 'critical' | 'high' | 'medium' | 'informational';
    title: string;
    description: string;
    sourceModule: string;
    actionRoute?: string;
    timestamp: string;
  }>;
  recentActivity: Array<{
    id: string;
    action: string;
    resource_type: string;
    admin_name: string;
    result: string;
    created_at: string;
  }>;
  systemHealth: {
    status: 'healthy' | 'degraded';
    db_status: 'connected' | 'disconnected' | 'error';
    db_latency_ms: number;
    uptime_seconds: number;
    memory_used_mb: number;
  };
}

export interface AdminUserListItem {
  id: string;
  phone_number: string;
  full_name: string;
  business_name: string | null;
  username: string | null;
  avatar_id: number;
  akawo_points: number;
  access_level: string;
  is_active: boolean;
  onboarding_completed: boolean;
  verification_status: string;
  last_login: string | null;
  created_at: string;
  primary_offer?: string | null;
  secondary_offers_count?: number;
  spotlight_status?: string | null;
  contact_sync_status?: string | null;
}

export interface UserDetailsResponse {
  success: boolean;
  user: AdminUserListItem;
  offers: {
    primary: { micro_niche_name: string; category_name?: string; is_primary?: boolean } | null;
    secondary: Array<{ micro_niche_id: string; micro_niche_name: string; category_name?: string }>;
  };
  interests: {
    baseline: Array<{ interest_id: string; interest_name: string; slug: string }>;
    dynamic: Array<{ interest_id: string; interest_name: string; score: number; recency_decay_factor: number; updated_at: string }>;
  };
  contactGain: {
    contacts_count: number;
    last_sync_status: string;
    pending_sync_count: number;
    failed_sync_count: number;
  };
  spotlight: {
    active_campaign: { id: string; business_name: string; title: string; status: string; submission_status?: string; participants_count: number } | null;
    campaigns_count: number;
    submission_status: string;
  };
  points_history: Array<{
    id: string;
    points_awarded: number;
    transaction_type: string;
    verified_by_bot: boolean;
    created_at: string;
  }>;
}

export interface UserActivityItem {
  id: string;
  action: string;
  resource_type: string;
  resource_id: string;
  metadata: Record<string, any>;
  result: string;
  created_at: string;
  event_source: string;
}

export const adminAuthApi = {
  /**
   * Real Admin Authentication
   */
  async login(phone_number: string, access_code?: string): Promise<{ token: string; user: AdminUser }> {
    const res = await adminFetch<{ success: boolean; token: string; user: AdminUser }>('/admin/auth/login', {
      method: 'POST',
      body: JSON.stringify({ phone_number, access_code }),
    });
    setAdminToken(res.token);
    return res;
  },

  /**
   * Verifies current session token with backend and retrieves user profile & permissions.
   */
  async verifySession(): Promise<{ user: AdminUser; session: { valid: boolean } }> {
    return adminFetch<{ success: boolean; user: AdminUser; session: { valid: boolean } }>('/admin/auth/me');
  },

  /**
   * Real Admin Logout
   */
  async logout(): Promise<void> {
    try {
      await adminFetch('/admin/auth/logout', { method: 'POST' });
    } finally {
      clearAdminToken();
    }
  },

  /**
   * Fetches real operational overview metrics from PostgreSQL database
   */
  async getOverview(range: 'today' | '7d' | '30d' = 'today'): Promise<OverviewData> {
    return adminFetch<OverviewData>(`/admin/overview?range=${range}`);
  },

  /**
   * Fetches real user registry from PostgreSQL database with server-backed search, filters, sorting, and pagination
   */
  async getUsersRegistry(params: {
    search?: string;
    status?: string;
    setup_status?: string;
    spotlight_status?: string;
    contact_sync_status?: string;
    sort?: string;
    limit?: number;
    offset?: number;
  } = {}): Promise<{
    success: boolean;
    users: AdminUserListItem[];
    total_count: number;
    limit: number;
    offset: number;
    sort: string;
    filters: Record<string, string>;
  }> {
    const query = new URLSearchParams();
    if (params.search) query.append('search', params.search);
    if (params.status) query.append('status', params.status);
    if (params.setup_status) query.append('setup_status', params.setup_status);
    if (params.spotlight_status) query.append('spotlight_status', params.spotlight_status);
    if (params.contact_sync_status) query.append('contact_sync_status', params.contact_sync_status);
    if (params.sort) query.append('sort', params.sort);
    if (params.limit) query.append('limit', params.limit.toString());
    if (params.offset) query.append('offset', params.offset.toString());

    return adminFetch(`/admin/users?${query.toString()}`);
  },

  /**
   * Fetches comprehensive user inspection details & transaction history
   */
  async getUserDetails(userId: string): Promise<UserDetailsResponse> {
    return adminFetch<UserDetailsResponse>(`/admin/users/${userId}`);
  },

  /**
   * Fetches real activity timeline for a user
   */
  async getUserActivity(userId: string): Promise<{ success: boolean; activity: UserActivityItem[] }> {
    return adminFetch<{ success: boolean; activity: UserActivityItem[] }>(`/admin/users/${userId}/activity`);
  },

  /**
   * Suspends or reinstates a user account
   */
  async suspendUserAccount(userId: string, suspend: boolean, reason?: string): Promise<{ success: boolean; message: string }> {
    return adminFetch<{ success: boolean; message: string }>(`/admin/users/${userId}/suspend`, {
      method: 'POST',
      body: JSON.stringify({ suspend, reason }),
    });
  },

  /**
   * Adjusts Akawo Points balance for a user account
   */
  async adjustUserPoints(userId: string, amount: number, reason: string): Promise<{ success: boolean; message: string; updated_balance: number }> {
    return adminFetch<{ success: boolean; message: string; updated_balance: number }>(`/admin/users/${userId}/adjust-points`, {
      method: 'POST',
      body: JSON.stringify({ amount, reason }),
    });
  },

  /**
   * Fetches real System Health & database connection metrics
   */
  async getSystemHealth(): Promise<SystemHealthData> {
    return adminFetch<SystemHealthData>('/admin/system/health');
  },

  /**
   * Fetches real Administrative Audit Logs from PostgreSQL
   */
  async getAuditLogs(limit = 50, offset = 0): Promise<{ success: boolean; logs: AuditLogItem[] }> {
    return adminFetch<{ success: boolean; logs: AuditLogItem[] }>(`/admin/audit-logs?limit=${limit}&offset=${offset}`);
  },

  /**
   * Fetches real Notification unread count for header entry point
   */
  async getUnreadNotificationsCount(): Promise<{ unread_count: number }> {
    return adminFetch<{ unread_count: number }>('/admin/notifications/unread-count');
  },
};
