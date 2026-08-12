const API_BASE = (import.meta.env.VITE_API_BASE_URL as string) || 'https://bizsquare-backend.onrender.com/api/v1';

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

export interface SetupCodeItem {
  id: string;
  code: string;
  is_used: boolean;
  used_at: string | null;
  expires_at: string;
  created_at: string;
  is_revoked: boolean;
  revoked_at: string | null;
  intended_user_id: string | null;
  used_by: string | null;
  created_by: string | null;
  status: 'AVAILABLE' | 'USED' | 'EXPIRED' | 'REVOKED';
  intended_user_name?: string | null;
  intended_user_phone?: string | null;
  used_by_name?: string | null;
  used_by_phone?: string | null;
  created_by_name?: string | null;
}

export interface AdminSpotlightTurnItem {
  id: string;
  user_id: string;
  title: string;
  promo_text: string;
  caption: string;
  flyer_url?: string | null;
  start_date: string;
  end_date: string;
  target_participants: number;
  is_active: boolean;
  status: string;
  submission_status: string;
  rejection_reason?: string | null;
  cycle_number?: number;
  is_override?: boolean;
  override_reason?: string | null;
  created_at: string;
  full_name: string;
  business_name?: string | null;
  phone_number?: string | null;
  username?: string | null;
  avatar_id: number;
  primary_offer: string;
  participant_count: number;
  turn_status_label?: string;
}

export interface UpcomingSpotlightUser {
  id: string;
  full_name: string;
  business_name?: string | null;
  avatar_id: number;
  phone_number?: string | null;
  primary_offer: string;
  last_spotlight_at?: string | null;
  eligibility_status?: string;
  is_currently_active?: boolean;
}

export interface ContactGainCycleItem {
  id: string;
  cycle_number: number;
  batch_date: string;
  network_size: number;
  target_per_user: number;
  allocation_percentage: number;
  status: 'INITIATED' | 'RUNNING' | 'COMPLETED' | 'FAILED';
  users_processed: number;
  users_filled: number;
  users_underfilled: number;
  total_allocations: number;
  tier_1_count: number;
  tier_2_count: number;
  tier_3_count: number;
  competitor_exclusions_count: number;
  execution_duration_ms: number;
  error_log?: string | null;
  created_at: string;
  completed_at?: string | null;
  network_size_live?: number;
  weekly_target_calculated?: number;
  sync_metrics?: {
    synced: number;
    pending: number;
    failed: number;
  };
}

export interface CycleUserOutcomeItem {
  id: string;
  cycle_id: string;
  user_id: string;
  target_count: number;
  allocated_count: number;
  tier_1_allocated: number;
  tier_2_allocated: number;
  tier_3_allocated: number;
  is_fully_filled: boolean;
  unfilled_reason?: string | null;
  created_at: string;
  full_name: string;
  phone_number?: string | null;
  business_name?: string | null;
  avatar_id: number;
  primary_offer: string;
  sync_status?: string | null;
  outcome_status: 'Target Met' | 'Below Target' | 'Zero Eligible Matches';
}

export interface GainedContactItem {
  relationship_id: string;
  source: string;
  sync_status: string;
  last_synced_at?: string | null;
  created_at: string;
  tier?: string | null;
  final_score?: number | null;
  match_reason?: string | null;
  matched_interest_slug?: string | null;
  partner_id: string;
  partner_name: string;
  partner_phone?: string | null;
  partner_business?: string | null;
  partner_avatar_id: number;
  partner_primary_offer: string;
  is_reciprocal_verified: boolean;
}

export interface NotificationTemplateItem {
  id: string;
  name: string;
  category: string;
  visual_variant: string;
  sound_variant: string;
  default_title: string;
  default_body: string;
  default_cta: string;
  default_destination: string;
}

export interface AdminNotificationBroadcastPayload {
  title: string;
  body: string;
  category: 'ANNOUNCEMENT' | 'SPOTLIGHT' | 'CONTACT_GAIN' | 'UPDATE' | 'IMPORTANT' | 'CELEBRATION';
  visual_variant: 'DEFAULT' | 'HIGHLIGHT' | 'ALERT' | 'SUCCESS' | 'GOLD';
  sound_variant?: 'DEFAULT' | 'URGENT' | 'CHIME';
  destination: string;
  audience_type: 'ALL' | 'NEW_USERS' | 'INCOMPLETE_SETUP' | 'SPOTLIGHT_USERS' | 'CONTACT_GAIN_USERS' | 'INDIVIDUAL';
  individual_user_id?: string;
  scheduled_at?: string;
  expires_at?: string;
}

export interface ScheduledNotificationItem {
  id: string;
  title: string;
  body: string;
  category: string;
  visual_variant: string;
  sound_variant: string;
  action_url: string;
  audience_type: string;
  scheduled_at: string;
  expires_at?: string | null;
  status: string;
  created_at: string;
  created_by_name?: string | null;
  recipient_count: number;
}

export interface SentNotificationItem {
  id: string;
  title: string;
  body: string;
  category: string;
  visual_variant: string;
  action_url: string;
  audience_type: string;
  status: string;
  created_at: string;
  created_by_name?: string | null;
  recipient_count: number;
  opened_count: number;
}

export interface MediaRecordItem {
  id: string;
  owner_id: string;
  source: string;
  media_type: 'IMAGE' | 'VIDEO';
  mime_type: string;
  file_size: number;
  original_filename?: string | null;
  storage_key: string;
  thumbnail_key?: string | null;
  width?: number | null;
  height?: number | null;
  duration_seconds?: number | null;
  status: 'UPLOADING' | 'UPLOADED' | 'PROCESSING' | 'READY' | 'REJECTED' | 'DELETED' | 'FAILED';
  processing_status: 'PENDING' | 'COMPLETED' | 'FAILED';
  moderation_status: 'PENDING_REVIEW' | 'PASSED' | 'FLAGGED' | 'REJECTED';
  moderation_reason?: string | null;
  created_at: string;
  updated_at: string;
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
   * Media Pipeline: Create Upload Session
   */
  async createMediaUploadSession(payload: {
    mediaType: 'IMAGE' | 'VIDEO';
    mimeType: string;
    fileSize: number;
    originalFilename?: string;
  }): Promise<{
    success: boolean;
    session: {
      mediaId: string;
      storageKey: string;
      uploadUrl: string;
      maxFileSize: number;
      allowedMimeTypes: string[];
    };
  }> {
    return adminFetch('/media/upload-session', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  /**
   * Media Pipeline: Complete Upload
   */
  async completeMediaUpload(
    mediaId: string,
    metadata: { width?: number; height?: number; durationSeconds?: number } = {}
  ): Promise<{ success: boolean; message: string; media: MediaRecordItem }> {
    return adminFetch(`/media/${mediaId}/complete`, {
      method: 'POST',
      body: JSON.stringify(metadata),
    });
  },

  /**
   * Media Pipeline: Get Media Record
   */
  async getMediaRecord(mediaId: string): Promise<{ success: boolean; media: MediaRecordItem }> {
    return adminFetch(`/media/${mediaId}`);
  },

  /**
   * Media Pipeline: Retry Processing
   */
  async retryMediaProcessing(mediaId: string): Promise<{ success: boolean; message: string; media: MediaRecordItem }> {
    return adminFetch(`/media/${mediaId}/retry`, {
      method: 'POST',
    });
  },

  /**
   * Media Pipeline: Soft Delete
   */
  async deleteMediaRecord(mediaId: string): Promise<{ success: boolean; message: string }> {
    return adminFetch(`/media/${mediaId}`, {
      method: 'DELETE',
    });
  },

  /**
   * Notification Operations: Calculate Recipient Estimate
   */
  async getNotificationRecipientEstimate(
    audience_type: string,
    individual_user_id?: string
  ): Promise<{ success: boolean; audience_type: string; estimated_count: number }> {
    const query = new URLSearchParams({ audience_type });
    if (individual_user_id) query.append('individual_user_id', individual_user_id);
    return adminFetch<{ success: boolean; audience_type: string; estimated_count: number }>(
      `/admin/notifications/recipient-estimate?${query.toString()}`
    );
  },

  /**
   * Notification Operations: Reusable Templates
   */
  async getNotificationTemplates(): Promise<{ success: boolean; templates: NotificationTemplateItem[] }> {
    return adminFetch<{ success: boolean; templates: NotificationTemplateItem[] }>('/admin/notifications/templates');
  },

  /**
   * Notification Operations: Send / Schedule Broadcast
   */
  async sendAdminNotification(
    payload: AdminNotificationBroadcastPayload
  ): Promise<{ success: boolean; message: string; recipient_count: number; is_scheduled: boolean }> {
    return adminFetch<{ success: boolean; message: string; recipient_count: number; is_scheduled: boolean }>(
      '/admin/notifications/send',
      {
        method: 'POST',
        body: JSON.stringify(payload),
      }
    );
  },

  /**
   * Notification Operations: Scheduled Queue
   */
  async getScheduledNotifications(): Promise<{ success: boolean; scheduled: ScheduledNotificationItem[] }> {
    return adminFetch<{ success: boolean; scheduled: ScheduledNotificationItem[] }>('/admin/notifications/scheduled');
  },

  /**
   * Notification Operations: Sent History
   */
  async getSentNotifications(limit = 20, offset = 0): Promise<{ success: boolean; sent: SentNotificationItem[] }> {
    return adminFetch<{ success: boolean; sent: SentNotificationItem[] }>(
      `/admin/notifications/sent?limit=${limit}&offset=${offset}`
    );
  },

  /**
   * Notification Operations: Cancel Scheduled Notification
   */
  async cancelScheduledNotification(id: string): Promise<{ success: boolean; message: string }> {
    return adminFetch<{ success: boolean; message: string }>(`/admin/notifications/${id}/cancel`, {
      method: 'POST',
    });
  },

  /**
   * Contact Gain Operations: Current Cycle Status
   */
  async getCurrentContactGainCycle(): Promise<{ success: boolean; current_cycle: ContactGainCycleItem | null; message?: string }> {
    return adminFetch<{ success: boolean; current_cycle: ContactGainCycleItem | null; message?: string }>('/admin/contact-gain/current');
  },

  /**
   * Contact Gain Operations: Historical Cycles
   */
  async getContactGainCycles(limit = 20, offset = 0): Promise<{
    success: boolean;
    cycles: ContactGainCycleItem[];
    total_count: number;
    limit: number;
    offset: number;
  }> {
    return adminFetch(`/admin/contact-gain/cycles?limit=${limit}&offset=${offset}`);
  },

  /**
   * Contact Gain Operations: Cycle User Outcomes
   */
  async getCycleUserOutcomes(
    cycleId: string,
    params: { search?: string; outcome?: string; limit?: number; offset?: number } = {}
  ): Promise<{
    success: boolean;
    user_outcomes: CycleUserOutcomeItem[];
    total_count: number;
    limit: number;
    offset: number;
  }> {
    const query = new URLSearchParams();
    if (params.search) query.append('search', params.search);
    if (params.outcome) query.append('outcome', params.outcome);
    if (params.limit) query.append('limit', params.limit.toString());
    if (params.offset) query.append('offset', params.offset.toString());

    return adminFetch(`/admin/contact-gain/cycles/${cycleId}/users?${query.toString()}`);
  },

  /**
   * Contact Gain Operations: User Inspection Detail
   */
  async getUserContactGainDetail(userId: string): Promise<{
    success: boolean;
    user: { id: string; full_name: string; phone_number?: string; business_name?: string; avatar_id: number };
    capacity: { network_size: number; minimum_target_10_pct: number; maximum_cap_10_pct: number; contacts_gained_total: number };
    gained_contacts: GainedContactItem[];
  }> {
    return adminFetch(`/admin/contact-gain/users/${userId}`);
  },

  /**
   * Contact Gain Operations: Matching Gaps
   */
  async getContactGainGaps(): Promise<{
    success: boolean;
    gaps: { underfilled_users: any[]; underfilled_count: number };
  }> {
    return adminFetch('/admin/contact-gain/gaps');
  },

  /**
   * Contact Gain Operations: Trigger Weekly Matching Cycle
   */
  async triggerWeeklyMatchingCycle(): Promise<{ success: boolean; message: string; result: any }> {
    return adminFetch<{ success: boolean; message: string; result: any }>('/admin/contact-gain/cycles/trigger', {
      method: 'POST',
    });
  },

  /**
   * Contact Gain Operations: Retry Failed Device Sync
   */
  async retryCycleDeviceSync(cycleId: string): Promise<{ success: boolean; message: string; retried_count: number }> {
    return adminFetch<{ success: boolean; message: string; retried_count: number }>(`/admin/contact-gain/cycles/${cycleId}/retry-sync`, {
      method: 'POST',
    });
  },

  /**
   * Spotlight Operations: Answers "WHOSE TURN IS IT?"
   */
  async getCurrentSpotlightTurn(): Promise<{ success: boolean; current_turn: AdminSpotlightTurnItem | null; message?: string }> {
    return adminFetch<{ success: boolean; current_turn: AdminSpotlightTurnItem | null; message?: string }>('/admin/spotlight/current');
  },

  /**
   * Spotlight Operations: Upcoming queue
   */
  async getUpcomingSpotlightQueue(): Promise<{ success: boolean; upcoming: UpcomingSpotlightUser[] }> {
    return adminFetch<{ success: boolean; upcoming: UpcomingSpotlightUser[] }>('/admin/spotlight/upcoming');
  },

  /**
   * Spotlight Operations: Moderation queue submissions
   */
  async getSpotlightSubmissions(status = 'pending_review', limit = 20, offset = 0): Promise<{
    success: boolean;
    submissions: AdminSpotlightTurnItem[];
    total_count: number;
    limit: number;
    offset: number;
  }> {
    return adminFetch(`/admin/spotlight/submissions?status=${status}&limit=${limit}&offset=${offset}`);
  },

  /**
   * Spotlight Operations: History query
   */
  async getSpotlightHistory(params: { search?: string; status?: string; limit?: number; offset?: number } = {}): Promise<{
    success: boolean;
    history: AdminSpotlightTurnItem[];
    total_count: number;
    limit: number;
    offset: number;
  }> {
    const query = new URLSearchParams();
    if (params.search) query.append('search', params.search);
    if (params.status) query.append('status', params.status);
    if (params.limit) query.append('limit', params.limit.toString());
    if (params.offset) query.append('offset', params.offset.toString());

    return adminFetch(`/admin/spotlight/history?${query.toString()}`);
  },

  /**
   * Spotlight Operations: Search eligible users for turn override
   */
  async getEligibleUsersForOverride(search?: string): Promise<{ success: boolean; users: UpcomingSpotlightUser[] }> {
    const query = search ? `?search=${encodeURIComponent(search)}` : '';
    return adminFetch<{ success: boolean; users: UpcomingSpotlightUser[] }>(`/admin/spotlight/eligible-users${query}`);
  },

  /**
   * Spotlight Operations: Approve submission
   */
  async approveSpotlightSubmission(campaignId: string): Promise<{ success: boolean; message: string }> {
    return adminFetch<{ success: boolean; message: string }>(`/admin/spotlight/submissions/${campaignId}/approve`, {
      method: 'POST',
    });
  },

  /**
   * Spotlight Operations: Disapprove submission
   */
  async disapproveSpotlightSubmission(campaignId: string, reason: string, note?: string): Promise<{ success: boolean; message: string }> {
    return adminFetch<{ success: boolean; message: string }>(`/admin/spotlight/submissions/${campaignId}/disapprove`, {
      method: 'POST',
      body: JSON.stringify({ reason, note }),
    });
  },

  /**
   * Spotlight Operations: Stop active Spotlight
   */
  async stopSpotlightCampaign(campaignId: string, reason?: string): Promise<{ success: boolean; message: string }> {
    return adminFetch<{ success: boolean; message: string }>(`/admin/spotlight/submissions/${campaignId}/stop`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
  },

  /**
   * Spotlight Operations: Override turn
   */
  async overrideSpotlightTurn(user_id: string, reason: string): Promise<{ success: boolean; message: string }> {
    return adminFetch<{ success: boolean; message: string }>('/admin/spotlight/override', {
      method: 'POST',
      body: JSON.stringify({ user_id, reason }),
    });
  },

  /**
   * Generates secure setup codes server-side
   */
  async generateSetupCodes(payload: { quantity?: number; expires_in_days?: number; intended_user_id?: string } = {}): Promise<{
    success: boolean;
    message: string;
    batch_id: string;
    codes: Array<{ id: string; code: string; expires_at: string }>;
  }> {
    return adminFetch('/admin/setup-codes', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  /**
   * Fetches real setup codes from PostgreSQL with search, filters, sorting, and pagination
   */
  async getSetupCodes(params: {
    search?: string;
    status?: string;
    assignment?: string;
    sort?: string;
    limit?: number;
    offset?: number;
  } = {}): Promise<{
    success: boolean;
    codes: SetupCodeItem[];
    total_count: number;
    limit: number;
    offset: number;
    sort: string;
  }> {
    const query = new URLSearchParams();
    if (params.search) query.append('search', params.search);
    if (params.status) query.append('status', params.status);
    if (params.assignment) query.append('assignment', params.assignment);
    if (params.sort) query.append('sort', params.sort);
    if (params.limit) query.append('limit', params.limit.toString());
    if (params.offset) query.append('offset', params.offset.toString());

    return adminFetch(`/admin/setup-codes?${query.toString()}`);
  },

  /**
   * Revokes an unused setup code
   */
  async revokeSetupCode(codeId: string, reason?: string): Promise<{ success: boolean; message: string }> {
    return adminFetch<{ success: boolean; message: string }>(`/admin/setup-codes/${codeId}/revoke`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
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
