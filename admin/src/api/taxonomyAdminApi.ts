const BASE = 'https://bizsquare-backend.onrender.com/api/v1';

let _token: string | null = localStorage.getItem('admin_token');

const getToken = () => _token;

async function apiFetch<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(opts.headers as Record<string, string>),
  };
  if (_token) headers['Authorization'] = `Bearer ${_token}`;
  const res = await fetch(`${BASE}${path}`, { ...opts, headers });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || `HTTP ${res.status}`);
  }
  return res.json();
}

// ─── Types ─────────────────────────────────────────────────────────────────

export interface MicroNiche {
  id: string;
  category_id: string;
  name: string;
  is_active: boolean;
}

export interface TaxonomyCategory {
  id: string;
  name: string;
  icon: string;
  sort_order: number;
  micro_niches: MicroNiche[];
}

// ─── API ───────────────────────────────────────────────────────────────────

export async function fetchTaxonomy(): Promise<TaxonomyCategory[]> {
  return apiFetch<TaxonomyCategory[]>('/admin/taxonomy');
}

export async function createNiche(payload: { id: string; category_id: string; name: string }): Promise<MicroNiche> {
  return apiFetch<MicroNiche>('/admin/taxonomy/niches', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function updateNiche(id: string, payload: { name?: string; is_active?: boolean }): Promise<MicroNiche> {
  return apiFetch<MicroNiche>(`/admin/taxonomy/niches/${encodeURIComponent(id)}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}

export async function deleteNiche(id: string): Promise<void> {
  return apiFetch<void>(`/admin/taxonomy/niches/${encodeURIComponent(id)}`, {
    method: 'DELETE',
  });
}

export async function createCategory(payload: { id: string; name: string; icon?: string; sort_order?: number }): Promise<TaxonomyCategory> {
  return apiFetch<TaxonomyCategory>('/admin/taxonomy/categories', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}
