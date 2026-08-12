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
