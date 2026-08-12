import { getToken } from './adminApi';

const BASE = 'http://localhost:8080/api/v1';

async function fetchWithAuth(path: string, opts: RequestInit = {}): Promise<Response> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(opts.headers as Record<string, string>),
  };

  const token = getToken();
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  return fetch(`${BASE}${path}`, { ...opts, headers });
}

export type RecipientCountResponse = {
  success: boolean;
  audience: string;
  recipientCount: number;
};

export type AdminNotificationPayload = {
  title: string;
  body: string;
  category: 'CONTACT_GAIN' | 'SPOTLIGHT' | 'DAILY_PULSE' | 'SYSTEM';
  visualVariant: 'ANNOUNCEMENT' | 'SPOTLIGHT' | 'CONTACT_GAIN' | 'UPDATE' | 'IMPORTANT' | 'CELEBRATION';
  soundVariant: 'DEFAULT' | 'URGENT' | 'CHIME' | 'SPOTLIGHT_TURN';
  ctaText: string;
  deepLink: string;
  audience: string;
  targetUserId?: string;
  scheduledAt?: string;
  expiresInHours?: number;
};

export type NotificationHistoryItem = {
  id: string;
  source: string;
  eventType: string;
  category: string;
  priority: string;
  title: string;
  body: string;
  deepLink: string;
  status: string;
  scheduledAt?: string;
  expiresAt?: string;
  createdAt: string;
  recipientName: string;
  recipientBusiness: string;
};

export type NotificationHistoryResponse = {
  success: boolean;
  metrics: {
    totalSent: number;
    totalDelivered: number;
    totalOpened: number;
    totalActioned: number;
  };
  history: NotificationHistoryItem[];
};

export const NotificationAdminApi = {
  /**
   * Fetches real estimated recipient count from SQL
   */
  getRecipientCount: async (audience: string, targetUserId?: string): Promise<number> => {
    let url = `/admin/notifications/recipients/count?audience=${audience}`;
    if (targetUserId) url += `&targetUserId=${targetUserId}`;

    const res = await fetchWithAuth(url);
    if (!res.ok) return 0;
    const data: RecipientCountResponse = await res.json();
    return data.recipientCount || 0;
  },

  /**
   * Dispatches admin notification broadcast to production notification pipeline
   */
  sendNotification: async (payload: AdminNotificationPayload): Promise<{ success: boolean; dispatchedCount: number; message: string }> => {
    const res = await fetchWithAuth('/admin/notifications/send', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    const data = await res.json();
    if (!res.ok || !data.success) {
      throw new Error(data.error || 'Failed to dispatch notification');
    }

    return {
      success: true,
      dispatchedCount: data.data?.dispatchedCount || 0,
      message: data.data?.message || 'Notification broadcast completed.',
    };
  },

  /**
   * Fetches real admin notification history and performance metrics
   */
  getNotificationHistory: async (): Promise<NotificationHistoryResponse> => {
    const res = await fetchWithAuth('/admin/notifications/history');
    if (!res.ok) {
      throw new Error('Failed to fetch notification history');
    }
    return res.json();
  },

  /**
   * Cancels a pending scheduled notification
   */
  cancelScheduledNotification: async (id: string): Promise<boolean> => {
    const res = await fetchWithAuth(`/admin/notifications/scheduled/${id}`, {
      method: 'DELETE',
    });
    return res.ok;
  },
};
