const API_BASE = 'http://localhost:8080/api/v1/admin/content-engine';

export interface OverviewMetrics {
  totalContent: number;
  activeContent: number;
  reviewPending: number;
  pausedContent: number;
  archivedContent: number;
  formatDistribution: { format: string; count: number }[];
  contextDistribution: { context_type: string; count: number }[];
}

export interface TaxonomyItem {
  id: string;
  slug: string;
  name: string;
  parent_id?: string | null;
  description?: string;
  context_type: string;
  icon: string;
  sort_order: number;
  is_active: boolean;
  aliases: string[];
  content_count: number;
  active_content_count: number;
  children?: TaxonomyItem[];
}

export interface ContentOptionItem {
  id: string;
  option_key: string;
  label: string;
  subtext?: string;
  media_url?: string;
}

export interface ContentBankItem {
  id: string;
  format: string;
  status: string;
  title_prompt: string;
  description?: string;
  media_url?: string;
  context_type: string;
  target_audience: string;
  difficulty: string;
  version: number;
  created_at: string;
  taxonomies?: { id: string; name: string; slug: string; is_primary: boolean }[];
  options: ContentOptionItem[];
  performance?: {
    impressions_count: number;
    interactions_count: number;
    skips_count: number;
    completions_count: number;
    avg_dwell_ms: number;
  };
}

export interface BankHealthItem {
  id: string;
  slug: string;
  name: string;
  icon: string;
  active_count: number;
  total_count: number;
  health_status: 'Healthy' | 'Medium' | 'Low' | 'Critical';
  recommendation?: string;
}

export const interestAdminApi = {
  async getOverview(): Promise<OverviewMetrics> {
    const res = await fetch(`${API_BASE}/overview`);
    if (!res.ok) throw new Error('Failed to fetch overview metrics');
    return res.json();
  },

  async getTaxonomies(): Promise<{ list: TaxonomyItem[]; tree: TaxonomyItem[] }> {
    const res = await fetch(`${API_BASE}/taxonomies`);
    if (!res.ok) throw new Error('Failed to fetch taxonomies');
    return res.json();
  },

  async upsertTaxonomy(data: Partial<TaxonomyItem>): Promise<{ node: TaxonomyItem }> {
    const res = await fetch(`${API_BASE}/taxonomies`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to save taxonomy node');
    return res.json();
  },

  async linkRelationship(sourceId: string, targetId: string, relationshipType = 'related', weight = 0.75): Promise<void> {
    const res = await fetch(`${API_BASE}/taxonomies/relationship`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sourceId, targetId, relationshipType, weight }),
    });
    if (!res.ok) throw new Error('Failed to link relationship');
  },

  async getContent(params: {
    taxonomyId?: string;
    format?: string;
    status?: string;
    search?: string;
    limit?: number;
    offset?: number;
  }): Promise<{ items: ContentBankItem[]; total: number }> {
    const query = new URLSearchParams();
    if (params.taxonomyId) query.append('taxonomyId', params.taxonomyId);
    if (params.format) query.append('format', params.format);
    if (params.status) query.append('status', params.status);
    if (params.search) query.append('search', params.search);
    if (params.limit) query.append('limit', String(params.limit));
    if (params.offset) query.append('offset', String(params.offset));

    const res = await fetch(`${API_BASE}/content?${query.toString()}`);
    if (!res.ok) throw new Error('Failed to fetch content items');
    return res.json();
  },

  async generateBatch(data: {
    taxonomyId: string;
    formats: string[];
    quantity: number;
    contextType?: string;
    targetAudience?: string;
  }): Promise<{ batchId: string; generatedCount: number; reviewCount: number; rejectedCount: number }> {
    const res = await fetch(`${API_BASE}/content/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to execute AI generation');
    return res.json();
  },

  async getBatches(): Promise<{ batches: any[] }> {
    const res = await fetch(`${API_BASE}/content/batches`);
    if (!res.ok) throw new Error('Failed to fetch generation history');
    return res.json();
  },

  async updateStatus(id: string, status: string, notes?: string): Promise<void> {
    const res = await fetch(`${API_BASE}/content/${id}/status`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status, notes }),
    });
    if (!res.ok) throw new Error('Failed to update content status');
  },

  async bulkReview(contentIds: string[], action: 'APPROVE' | 'REJECT' | 'PAUSE'): Promise<{ affected: number }> {
    const res = await fetch(`${API_BASE}/content/bulk-review`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ contentIds, action }),
    });
    if (!res.ok) throw new Error('Failed to perform bulk review');
    return res.json();
  },

  async editContent(id: string, data: Partial<ContentBankItem>): Promise<void> {
    const res = await fetch(`${API_BASE}/content/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to edit content item');
  },

  async getBankHealth(): Promise<{ taxonomies: BankHealthItem[] }> {
    const res = await fetch(`${API_BASE}/health-coverage`);
    if (!res.ok) throw new Error('Failed to fetch bank health coverage');
    return res.json();
  },

  async getAnalytics(): Promise<{
    totalSessionsStarted: number;
    totalSessionsCompleted: number;
    completionRatePct: number;
    totalInteractions: number;
    formatPerformance: { format: string; interactionRatePct: number; avgDwellMs: number }[];
  }> {
    const res = await fetch(`${API_BASE}/analytics`);
    if (!res.ok) throw new Error('Failed to fetch analytics');
    return res.json();
  },
};
