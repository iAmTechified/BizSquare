import { useState, useEffect, useCallback } from 'react';
import {
  fetchTaxonomy,
  createNiche,
  updateNiche,
  deleteNiche,
  createCategory,
  TaxonomyCategory,
  MicroNiche,
} from '../api/taxonomyAdminApi';

// ─── Slug Helpers ─────────────────────────────────────────────────────────────
function toSlug(str: string, prefix: string): string {
  return prefix + str.trim().toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
}

// ─── Add Niche Modal ──────────────────────────────────────────────────────────
interface AddNicheModalProps {
  categories: TaxonomyCategory[];
  onClose: () => void;
  onSave: (id: string, categoryId: string, name: string) => Promise<void>;
}

function AddNicheModal({ categories, onClose, onSave }: AddNicheModalProps) {
  const [name, setName] = useState('');
  const [categoryId, setCategoryId] = useState(categories[0]?.id ?? '');
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState('');

  const slug = name ? toSlug(name, 'mn_') : '';

  const handleSubmit = async () => {
    if (!name.trim() || !categoryId) return;
    setLoading(true);
    setErr('');
    try {
      await onSave(slug, categoryId, name.trim());
      onClose();
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="taxonomy-modal-overlay" onClick={onClose}>
      <div className="taxonomy-modal" onClick={e => e.stopPropagation()}>
        <div className="taxonomy-modal-header">
          <h3>Add New Micro-Niche</h3>
          <button className="taxonomy-modal-close" onClick={onClose}>✕</button>
        </div>
        <div className="taxonomy-modal-body">
          <label>Category</label>
          <select value={categoryId} onChange={e => setCategoryId(e.target.value)}>
            {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
          <label>Name</label>
          <input
            type="text"
            placeholder="e.g. Vintage Clothing"
            value={name}
            onChange={e => setName(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleSubmit()}
          />
          {name && (
            <div className="taxonomy-slug-preview">
              Slug: <code>{slug}</code>
            </div>
          )}
          {err && <div className="taxonomy-error">{err}</div>}
        </div>
        <div className="taxonomy-modal-footer">
          <button className="taxonomy-btn-secondary" onClick={onClose}>Cancel</button>
          <button
            className="taxonomy-btn-primary"
            onClick={handleSubmit}
            disabled={loading || !name.trim()}
          >
            {loading ? 'Saving…' : 'Add Niche'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Add Category Modal ───────────────────────────────────────────────────────
interface AddCategoryModalProps {
  onClose: () => void;
  onSave: (id: string, name: string, icon: string) => Promise<void>;
}

function AddCategoryModal({ onClose, onSave }: AddCategoryModalProps) {
  const [name, setName] = useState('');
  const [icon, setIcon] = useState('store');
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState('');

  const slug = name ? toSlug(name, 'cat_') : '';

  const handleSubmit = async () => {
    if (!name.trim()) return;
    setLoading(true);
    setErr('');
    try {
      await onSave(slug, name.trim(), icon.trim() || 'store');
      onClose();
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="taxonomy-modal-overlay" onClick={onClose}>
      <div className="taxonomy-modal" onClick={e => e.stopPropagation()}>
        <div className="taxonomy-modal-header">
          <h3>Add New Category</h3>
          <button className="taxonomy-modal-close" onClick={onClose}>✕</button>
        </div>
        <div className="taxonomy-modal-body">
          <label>Name</label>
          <input
            type="text"
            placeholder="e.g. Sports & Recreation"
            value={name}
            onChange={e => setName(e.target.value)}
          />
          <label>Icon (Material icon name)</label>
          <input
            type="text"
            placeholder="e.g. sports_soccer"
            value={icon}
            onChange={e => setIcon(e.target.value)}
          />
          {name && (
            <div className="taxonomy-slug-preview">
              Slug: <code>{slug}</code>
            </div>
          )}
          {err && <div className="taxonomy-error">{err}</div>}
        </div>
        <div className="taxonomy-modal-footer">
          <button className="taxonomy-btn-secondary" onClick={onClose}>Cancel</button>
          <button
            className="taxonomy-btn-primary"
            onClick={handleSubmit}
            disabled={loading || !name.trim()}
          >
            {loading ? 'Saving…' : 'Add Category'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Edit Niche Inline ────────────────────────────────────────────────────────
interface NicheRowProps {
  niche: MicroNiche;
  onUpdate: (id: string, payload: { name?: string; is_active?: boolean }) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
}

function NicheRow({ niche, onUpdate, onDelete }: NicheRowProps) {
  const [editing, setEditing] = useState(false);
  const [editName, setEditName] = useState(niche.name);
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!editName.trim()) return;
    setSaving(true);
    try {
      await onUpdate(niche.id, { name: editName.trim() });
      setEditing(false);
    } finally {
      setSaving(false);
    }
  };

  const handleToggleActive = async () => {
    setSaving(true);
    try {
      await onUpdate(niche.id, { is_active: !niche.is_active });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className={`taxonomy-niche-row ${!niche.is_active ? 'taxonomy-niche-inactive' : ''}`}>
      <div className="taxonomy-niche-left">
        <span className={`taxonomy-active-dot ${niche.is_active ? 'active' : 'inactive'}`} />
        {editing ? (
          <input
            className="taxonomy-niche-edit-input"
            value={editName}
            onChange={e => setEditName(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter') handleSave(); if (e.key === 'Escape') setEditing(false); }}
            autoFocus
          />
        ) : (
          <span className="taxonomy-niche-name">{niche.name}</span>
        )}
        <code className="taxonomy-niche-slug">{niche.id}</code>
      </div>
      <div className="taxonomy-niche-actions">
        {editing ? (
          <>
            <button className="taxonomy-btn-save" onClick={handleSave} disabled={saving}>
              {saving ? '…' : 'Save'}
            </button>
            <button className="taxonomy-btn-cancel-edit" onClick={() => { setEditing(false); setEditName(niche.name); }}>
              Cancel
            </button>
          </>
        ) : (
          <>
            <button className="taxonomy-btn-edit" onClick={() => setEditing(true)} title="Rename">
              ✎
            </button>
            <button
              className={`taxonomy-btn-toggle ${niche.is_active ? 'deactivate' : 'activate'}`}
              onClick={handleToggleActive}
              disabled={saving}
              title={niche.is_active ? 'Disable' : 'Enable'}
            >
              {niche.is_active ? '⊘' : '✓'}
            </button>
          </>
        )}
      </div>
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────
export function TaxonomyPage() {
  const [taxonomy, setTaxonomy] = useState<TaxonomyCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [expandedCat, setExpandedCat] = useState<string | null>(null);
  const [showAddNiche, setShowAddNiche] = useState(false);
  const [showAddCat, setShowAddCat] = useState(false);

  const loadTaxonomy = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const data = await fetchTaxonomy();
      setTaxonomy(data);
      if (data.length > 0 && !expandedCat) {
        setExpandedCat(data[0].id);
      }
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadTaxonomy(); }, [loadTaxonomy]);

  const handleCreateNiche = async (id: string, categoryId: string, name: string) => {
    await createNiche({ id, category_id: categoryId, name });
    await loadTaxonomy();
  };

  const handleUpdateNiche = async (id: string, payload: { name?: string; is_active?: boolean }) => {
    const updated = await updateNiche(id, payload);
    setTaxonomy(prev =>
      prev.map(cat => ({
        ...cat,
        micro_niches: cat.micro_niches.map(n => n.id === id ? { ...n, ...updated } : n),
      }))
    );
  };

  const handleDeleteNiche = async (id: string) => {
    await deleteNiche(id);
    setTaxonomy(prev =>
      prev.map(cat => ({
        ...cat,
        micro_niches: cat.micro_niches.filter(n => n.id !== id),
      }))
    );
  };

  const handleCreateCategory = async (id: string, name: string, icon: string) => {
    await createCategory({ id, name, icon });
    await loadTaxonomy();
  };

  const q = search.trim().toLowerCase();
  const filteredTaxonomy = q
    ? taxonomy.map(cat => ({
        ...cat,
        micro_niches: cat.micro_niches.filter(
          n => n.name.toLowerCase().includes(q) || n.id.toLowerCase().includes(q)
        ),
      })).filter(cat => cat.micro_niches.length > 0 || cat.name.toLowerCase().includes(q))
    : taxonomy;

  const totalNiches = taxonomy.reduce((acc, c) => acc + c.micro_niches.length, 0);
  const activeNiches = taxonomy.reduce((acc, c) => acc + c.micro_niches.filter(n => n.is_active).length, 0);

  return (
    <div className="taxonomy-page">
      {/* Header */}
      <div className="taxonomy-page-header">
        <div className="taxonomy-header-left">
          <h1 className="taxonomy-title">Taxonomy Manager</h1>
          <p className="taxonomy-subtitle">Manage the business categories and micro-niches used for matching.</p>
        </div>
        <div className="taxonomy-header-actions">
          <button className="taxonomy-btn-secondary" onClick={() => setShowAddCat(true)}>+ Category</button>
          <button className="taxonomy-btn-primary" onClick={() => setShowAddNiche(true)}>+ Add Niche</button>
        </div>
      </div>

      {/* Stats Bar */}
      <div className="taxonomy-stats-bar">
        <div className="taxonomy-stat">
          <span className="taxonomy-stat-value">{taxonomy.length}</span>
          <span className="taxonomy-stat-label">Categories</span>
        </div>
        <div className="taxonomy-stat">
          <span className="taxonomy-stat-value">{totalNiches}</span>
          <span className="taxonomy-stat-label">Total Niches</span>
        </div>
        <div className="taxonomy-stat">
          <span className="taxonomy-stat-value taxonomy-stat-green">{activeNiches}</span>
          <span className="taxonomy-stat-label">Active</span>
        </div>
        <div className="taxonomy-stat">
          <span className="taxonomy-stat-value taxonomy-stat-red">{totalNiches - activeNiches}</span>
          <span className="taxonomy-stat-label">Disabled</span>
        </div>
      </div>

      {/* Search */}
      <div className="taxonomy-search-bar">
        <input
          type="text"
          placeholder="Search niches or categories…"
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="taxonomy-search-input"
        />
        {search && (
          <button className="taxonomy-search-clear" onClick={() => setSearch('')}>✕</button>
        )}
      </div>

      {/* Content */}
      {loading && (
        <div className="taxonomy-loading">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="taxonomy-skeleton" />
          ))}
        </div>
      )}

      {error && (
        <div className="taxonomy-error-state">
          <span>⚠ {error}</span>
          <button className="taxonomy-btn-secondary" onClick={loadTaxonomy}>Retry</button>
        </div>
      )}

      {!loading && !error && (
        <div className="taxonomy-categories-list">
          {filteredTaxonomy.map(cat => (
            <div key={cat.id} className="taxonomy-category-card">
              <button
                className="taxonomy-category-header"
                onClick={() => setExpandedCat(prev => prev === cat.id ? null : cat.id)}
              >
                <div className="taxonomy-cat-info">
                  <span className="taxonomy-cat-icon">{cat.icon}</span>
                  <div>
                    <span className="taxonomy-cat-name">{cat.name}</span>
                    <code className="taxonomy-cat-slug">{cat.id}</code>
                  </div>
                </div>
                <div className="taxonomy-cat-meta">
                  <span className="taxonomy-niche-count">
                    {cat.micro_niches.filter(n => n.is_active).length}/{cat.micro_niches.length} active
                  </span>
                  <span className={`taxonomy-chevron ${expandedCat === cat.id ? 'open' : ''}`}>›</span>
                </div>
              </button>

              {expandedCat === cat.id && (
                <div className="taxonomy-niches-list">
                  {cat.micro_niches.length === 0 ? (
                    <p className="taxonomy-empty-niches">No niches in this category yet.</p>
                  ) : (
                    cat.micro_niches.map(niche => (
                      <NicheRow
                        key={niche.id}
                        niche={niche}
                        onUpdate={handleUpdateNiche}
                        onDelete={handleDeleteNiche}
                      />
                    ))
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Modals */}
      {showAddNiche && (
        <AddNicheModal
          categories={taxonomy}
          onClose={() => setShowAddNiche(false)}
          onSave={handleCreateNiche}
        />
      )}
      {showAddCat && (
        <AddCategoryModal
          onClose={() => setShowAddCat(false)}
          onSave={handleCreateCategory}
        />
      )}
    </div>
  );
}
