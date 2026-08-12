import React, { useState, useEffect } from 'react';
import { interestAdminApi } from '../api/interestAdminApi';
import type { 
  OverviewMetrics, 
  TaxonomyItem, 
  ContentBankItem, 
  BankHealthItem 
} from '../api/interestAdminApi';
import { 
  Sparkles, 
  Layers, 
  Database, 
  CheckCircle2, 
  Activity, 
  RefreshCw, 
  Flame
} from 'lucide-react';

export const ContentEngineDashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'overview' | 'taxonomy' | 'bank' | 'generator' | 'review' | 'health'>('overview');
  const [error, setError] = useState<string | null>(null);

  // Data states
  const [overview, setOverview] = useState<OverviewMetrics | null>(null);
  const [taxonomies, setTaxonomies] = useState<TaxonomyItem[]>([]);
  const [contentItems, setContentItems] = useState<ContentBankItem[]>([]);
  const [healthItems, setHealthItems] = useState<BankHealthItem[]>([]);
  const [reviewItems, setReviewItems] = useState<ContentBankItem[]>([]);

  // Filters
  const [filterFormat, setFilterFormat] = useState<string>('');
  const [filterStatus, setFilterStatus] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Generation form
  const [genTaxonomyId, setGenTaxonomyId] = useState<string>('');
  const [genQuantity, setGenQuantity] = useState<number>(10);
  const [genContext, setGenContext] = useState<string>('mixed');
  const [generating, setGenerating] = useState<boolean>(false);
  const [genSuccess, setGenSuccess] = useState<string | null>(null);

  const loadData = async () => {
    setError(null);
    try {
      if (activeTab === 'overview') {
        const data = await interestAdminApi.getOverview();
        setOverview(data);
      } else if (activeTab === 'taxonomy') {
        const data = await interestAdminApi.getTaxonomies();
        setTaxonomies(data.list);
      } else if (activeTab === 'bank') {
        const data = await interestAdminApi.getContent({
          format: filterFormat || undefined,
          status: filterStatus || undefined,
          search: searchQuery || undefined,
          limit: 50,
        });
        setContentItems(data.items);
      } else if (activeTab === 'review') {
        const data = await interestAdminApi.getContent({ status: 'REVIEW', limit: 50 });
        setReviewItems(data.items);
      } else if (activeTab === 'health') {
        const data = await interestAdminApi.getBankHealth();
        setHealthItems(data.taxonomies);
      }
    } catch (err: any) {
      setError(err.message || 'Failed to load data');
    }
  };

  useEffect(() => {
    loadData();
  }, [activeTab, filterFormat, filterStatus]);

  const handleGenerate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!genTaxonomyId) {
      setError('Please select a taxonomy node.');
      return;
    }
    setGenerating(true);
    setGenSuccess(null);
    try {
      const res = await interestAdminApi.generateBatch({
        taxonomyId: genTaxonomyId,
        formats: ['THIS_OR_THAT', 'PICK_ONE', 'WOULD_YOU', 'REACTION_CARD', 'SCENARIO'],
        quantity: genQuantity,
        contextType: genContext,
      });
      setGenSuccess(`Batch generated! ${res.reviewCount} items created for review (${res.rejectedCount} duplicates filtered).`);
      loadData();
    } catch (err: any) {
      setError(err.message || 'Generation failed');
    } finally {
      setGenerating(false);
    }
  };

  const handleStatusUpdate = async (id: string, status: string) => {
    try {
      await interestAdminApi.updateStatus(id, status);
      loadData();
    } catch (err: any) {
      setError(err.message || 'Status update failed');
    }
  };

  const handleBulkApprove = async () => {
    if (reviewItems.length === 0) return;
    try {
      const ids = reviewItems.map(r => r.id);
      await interestAdminApi.bulkReview(ids, 'APPROVE');
      loadData();
    } catch (err: any) {
      setError(err.message || 'Bulk approve failed');
    }
  };

  return (
    <div style={{ marginTop: '2rem' }}>
      {/* Sub-Navigation Tabs */}
      <div style={{
        display: 'flex',
        gap: '0.5rem',
        borderBottom: '1px solid var(--border-color)',
        paddingBottom: '0.75rem',
        marginBottom: '1.5rem',
        overflowX: 'auto'
      }}>
        {[
          { key: 'overview', label: 'Overview & Metrics', icon: <Activity size={18} /> },
          { key: 'taxonomy', label: 'Taxonomy Manager', icon: <Layers size={18} /> },
          { key: 'bank', label: 'Content Bank', icon: <Database size={18} /> },
          { key: 'generator', label: 'AI Generator', icon: <Sparkles size={18} /> },
          { key: 'review', label: `Review Queue (${reviewItems.length})`, icon: <CheckCircle2 size={18} /> },
          { key: 'health', label: 'Bank Health & Coverage', icon: <Flame size={18} /> },
        ].map(tab => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key as any)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              padding: '0.6rem 1.1rem',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontWeight: 600,
              fontSize: '13px',
              background: activeTab === tab.key ? '#0058FF' : 'var(--card-background)',
              color: activeTab === tab.key ? '#FFFFFF' : 'var(--text-secondary)',
              boxShadow: activeTab === tab.key ? '0 4px 12px rgba(0, 88, 255, 0.25)' : 'none',
              transition: 'all 0.2s ease'
            }}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      {error && (
        <div style={{
          padding: '0.8rem 1.2rem',
          background: 'rgba(239, 68, 68, 0.15)',
          border: '1px solid rgba(239, 68, 68, 0.3)',
          color: '#EF4444',
          borderRadius: '8px',
          marginBottom: '1rem',
          fontSize: '13px'
        }}>
          {error}
        </div>
      )}

      {/* TAB 1: OVERVIEW */}
      {activeTab === 'overview' && overview && (
        <div>
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: '1rem',
            marginBottom: '1.5rem'
          }}>
            <div style={{ background: 'var(--card-background)', padding: '1.2rem', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)', fontWeight: 600 }}>TOTAL CONTENT ITEMS</div>
              <div style={{ fontSize: '28px', fontWeight: 800, color: 'var(--text-primary)', marginTop: '4px' }}>{overview.totalContent}</div>
            </div>
            <div style={{ background: 'var(--card-background)', padding: '1.2rem', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
              <div style={{ fontSize: '12px', color: '#10B981', fontWeight: 600 }}>ACTIVE IN BANK</div>
              <div style={{ fontSize: '28px', fontWeight: 800, color: '#10B981', marginTop: '4px' }}>{overview.activeContent}</div>
            </div>
            <div style={{ background: 'var(--card-background)', padding: '1.2rem', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
              <div style={{ fontSize: '12px', color: '#F59E0B', fontWeight: 600 }}>PENDING REVIEW</div>
              <div style={{ fontSize: '28px', fontWeight: 800, color: '#F59E0B', marginTop: '4px' }}>{overview.reviewPending}</div>
            </div>
            <div style={{ background: 'var(--card-background)', padding: '1.2rem', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
              <div style={{ fontSize: '12px', color: '#64748B', fontWeight: 600 }}>PAUSED / ARCHIVED</div>
              <div style={{ fontSize: '28px', fontWeight: 800, color: '#64748B', marginTop: '4px' }}>{overview.pausedContent + overview.archivedContent}</div>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
            <div style={{ background: 'var(--card-background)', padding: '1.5rem', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
              <h3 style={{ fontSize: '15px', fontWeight: 700, marginBottom: '1rem' }}>Multi-Format Distribution</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
                {overview.formatDistribution.map(f => (
                  <div key={f.format} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                    <span style={{ fontWeight: 600 }}>{f.format}</span>
                    <span style={{ color: '#0058FF', fontWeight: 700 }}>{f.count} items</span>
                  </div>
                ))}
              </div>
            </div>

            <div style={{ background: 'var(--card-background)', padding: '1.5rem', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
              <h3 style={{ fontSize: '15px', fontWeight: 700, marginBottom: '1rem' }}>Context Types</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
                {overview.contextDistribution.map(c => (
                  <div key={c.context_type} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                    <span style={{ textTransform: 'capitalize', fontWeight: 600 }}>{c.context_type}</span>
                    <span style={{ color: '#5AFF00', fontWeight: 700 }}>{c.count} items</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: TAXONOMY MANAGER */}
      {activeTab === 'taxonomy' && (
        <div style={{ background: 'var(--card-background)', padding: '1.5rem', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <h3 style={{ fontSize: '16px', fontWeight: 700 }}>Hierarchical Interest Taxonomies</h3>
            <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{taxonomies.length} Total Nodes</span>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid var(--border-color)', textAlign: 'left', color: 'var(--text-secondary)' }}>
                  <th style={{ padding: '0.8rem' }}>Name</th>
                  <th style={{ padding: '0.8rem' }}>Slug</th>
                  <th style={{ padding: '0.8rem' }}>Context</th>
                  <th style={{ padding: '0.8rem' }}>Active Content</th>
                  <th style={{ padding: '0.8rem' }}>Aliases</th>
                </tr>
              </thead>
              <tbody>
                {taxonomies.map(t => (
                  <tr key={t.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                    <td style={{ padding: '0.8rem', fontWeight: 600 }}>{t.name}</td>
                    <td style={{ padding: '0.8rem', color: '#0058FF' }}><code>{t.slug}</code></td>
                    <td style={{ padding: '0.8rem', textTransform: 'capitalize' }}>{t.context_type}</td>
                    <td style={{ padding: '0.8rem' }}>
                      <span style={{
                        padding: '2px 8px',
                        borderRadius: '12px',
                        background: t.active_content_count > 0 ? 'rgba(16, 185, 129, 0.15)' : 'rgba(239, 68, 68, 0.15)',
                        color: t.active_content_count > 0 ? '#10B981' : '#EF4444',
                        fontWeight: 700,
                        fontSize: '11px'
                      }}>
                        {t.active_content_count} active
                      </span>
                    </td>
                    <td style={{ padding: '0.8rem', color: 'var(--text-secondary)' }}>{t.aliases?.join(', ') || '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 3: CONTENT BANK */}
      {activeTab === 'bank' && (
        <div>
          {/* Filters Bar */}
          <div style={{
            display: 'flex',
            gap: '1rem',
            marginBottom: '1rem',
            flexWrap: 'wrap',
            background: 'var(--card-background)',
            padding: '1rem',
            borderRadius: '10px',
            border: '1px solid var(--border-color)'
          }}>
            <input
              type="text"
              placeholder="Search prompts..."
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              style={{
                padding: '0.5rem 0.8rem',
                borderRadius: '6px',
                border: '1px solid var(--border-color)',
                background: 'var(--background-color)',
                color: 'var(--text-primary)',
                flex: 1,
                minWidth: '180px'
              }}
            />
            <select
              value={filterFormat}
              onChange={e => setFilterFormat(e.target.value)}
              style={{ padding: '0.5rem 0.8rem', borderRadius: '6px', border: '1px solid var(--border-color)', background: 'var(--background-color)', color: 'var(--text-primary)' }}
            >
              <option value="">All Formats</option>
              <option value="THIS_OR_THAT">This or That</option>
              <option value="PICK_ONE">Pick One</option>
              <option value="WOULD_YOU">Would You?</option>
              <option value="REACTION_CARD">Reaction Card</option>
              <option value="SCENARIO">Scenario</option>
              <option value="COMPARE">Compare</option>
              <option value="QUICK_OPINION">Quick Opinion</option>
              <option value="INTENT_CHOICE">Intent Choice</option>
            </select>
            <select
              value={filterStatus}
              onChange={e => setFilterStatus(e.target.value)}
              style={{ padding: '0.5rem 0.8rem', borderRadius: '6px', border: '1px solid var(--border-color)', background: 'var(--background-color)', color: 'var(--text-primary)' }}
            >
              <option value="">All Statuses</option>
              <option value="ACTIVE">ACTIVE</option>
              <option value="REVIEW">REVIEW</option>
              <option value="PAUSED">PAUSED</option>
              <option value="ARCHIVED">ARCHIVED</option>
            </select>
            <button
              onClick={loadData}
              style={{ padding: '0.5rem 1rem', borderRadius: '6px', background: '#0058FF', color: 'white', border: 'none', cursor: 'pointer', fontWeight: 600 }}
            >
              Apply Filter
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {contentItems.map(item => (
              <div
                key={item.id}
                style={{
                  background: 'var(--card-background)',
                  padding: '1.2rem',
                  borderRadius: '12px',
                  border: '1px solid var(--border-color)',
                  display: 'flex',
                  justifyContent: 'space-between',
                  gap: '1rem'
                }}
              >
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', marginBottom: '0.4rem' }}>
                    <span style={{ fontSize: '11px', fontWeight: 800, padding: '2px 8px', borderRadius: '4px', background: '#0058FF', color: 'white' }}>
                      {item.format}
                    </span>
                    <span style={{ fontSize: '11px', fontWeight: 700, padding: '2px 8px', borderRadius: '4px', background: item.status === 'ACTIVE' ? '#10B981' : '#F59E0B', color: 'white' }}>
                      {item.status}
                    </span>
                    <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{item.context_type}</span>
                  </div>

                  <h4 style={{ fontSize: '15px', fontWeight: 700, margin: '0.3rem 0' }}>{item.title_prompt}</h4>
                  {item.description && <p style={{ fontSize: '12px', color: 'var(--text-secondary)', margin: '0.2rem 0' }}>{item.description}</p>}

                  <div style={{ display: 'flex', gap: '0.5rem', marginTop: '0.6rem', flexWrap: 'wrap' }}>
                    {item.options.map(opt => (
                      <span key={opt.id} style={{ fontSize: '12px', padding: '4px 10px', borderRadius: '6px', background: 'var(--background-color)', border: '1px solid var(--border-color)' }}>
                        {opt.label}
                      </span>
                    ))}
                  </div>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem', justifyContent: 'center' }}>
                  {item.status === 'ACTIVE' ? (
                    <button
                      onClick={() => handleStatusUpdate(item.id, 'PAUSED')}
                      style={{ padding: '0.4rem 0.8rem', borderRadius: '6px', border: '1px solid var(--border-color)', background: 'transparent', color: 'var(--text-primary)', cursor: 'pointer', fontSize: '12px' }}
                    >
                      Pause
                    </button>
                  ) : (
                    <button
                      onClick={() => handleStatusUpdate(item.id, 'ACTIVE')}
                      style={{ padding: '0.4rem 0.8rem', borderRadius: '6px', border: 'none', background: '#10B981', color: 'white', cursor: 'pointer', fontSize: '12px', fontWeight: 700 }}
                    >
                      Activate
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB 4: AI GENERATOR */}
      {activeTab === 'generator' && (
        <div style={{ background: 'var(--card-background)', padding: '1.8rem', borderRadius: '12px', border: '1px solid var(--border-color)', maxWidth: '650px' }}>
          <h3 style={{ fontSize: '18px', fontWeight: 800, marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Sparkles size={20} color="#0058FF" /> AI Content Batch Generator
          </h3>
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>
            Produce structured multi-format interaction instruments that cleanly populate the content bank with automated signal mappings.
          </p>

          <form onSubmit={handleGenerate} style={{ display: 'flex', flexDirection: 'column', gap: '1.2rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 700, marginBottom: '0.4rem' }}>Target Taxonomy Node *</label>
              <select
                value={genTaxonomyId}
                onChange={e => setGenTaxonomyId(e.target.value)}
                required
                style={{ width: '100%', padding: '0.7rem', borderRadius: '8px', border: '1px solid var(--border-color)', background: 'var(--background-color)', color: 'var(--text-primary)' }}
              >
                <option value="">Select an interest taxonomy...</option>
                {taxonomies.map(t => (
                  <option key={t.id} value={t.id}>{t.name} ({t.slug})</option>
                ))}
              </select>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 700, marginBottom: '0.4rem' }}>Batch Quantity ({genQuantity} items)</label>
              <input
                type="range"
                min="5"
                max="30"
                step="5"
                value={genQuantity}
                onChange={e => setGenQuantity(parseInt(e.target.value, 10))}
                style={{ width: '100%' }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 700, marginBottom: '0.4rem' }}>Context Orientation</label>
              <select
                value={genContext}
                onChange={e => setGenContext(e.target.value)}
                style={{ width: '100%', padding: '0.7rem', borderRadius: '8px', border: '1px solid var(--border-color)', background: 'var(--background-color)', color: 'var(--text-primary)' }}
              >
                <option value="mixed">Mixed (Business & Consumer)</option>
                <option value="business">Business & Commercial</option>
                <option value="personal">Personal & Consumer</option>
                <option value="lifestyle">Lifestyle & Wellness</option>
              </select>
            </div>

            <button
              type="submit"
              disabled={generating}
              style={{
                padding: '0.8rem',
                borderRadius: '8px',
                border: 'none',
                background: '#0058FF',
                color: 'white',
                fontWeight: 800,
                cursor: generating ? 'not-allowed' : 'pointer',
                fontSize: '14px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '0.5rem'
              }}
            >
              {generating ? <RefreshCw size={18} className="spin" /> : <Sparkles size={18} />}
              {generating ? 'Generating Batch...' : `Generate ${genQuantity} Interaction Items ⚡`}
            </button>
          </form>

          {genSuccess && (
            <div style={{ marginTop: '1.2rem', padding: '1rem', background: 'rgba(16, 185, 129, 0.15)', color: '#10B981', borderRadius: '8px', fontSize: '13px', fontWeight: 600 }}>
              {genSuccess}
            </div>
          )}
        </div>
      )}

      {/* TAB 5: REVIEW QUEUE */}
      {activeTab === 'review' && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <div>
              <h3 style={{ fontSize: '16px', fontWeight: 700 }}>Pending Review Queue ({reviewItems.length})</h3>
              <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Moderate generated cards before activating them into the live bank.</p>
            </div>
            {reviewItems.length > 0 && (
              <button
                onClick={handleBulkApprove}
                style={{ padding: '0.5rem 1.2rem', borderRadius: '6px', background: '#10B981', color: 'white', border: 'none', cursor: 'pointer', fontWeight: 700 }}
              >
                Bulk Approve All ({reviewItems.length}) ✓
              </button>
            )}
          </div>

          {reviewItems.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '3rem', background: 'var(--card-background)', borderRadius: '12px' }}>
              <CheckCircle2 size={40} color="#10B981" style={{ margin: '0 auto 1rem' }} />
              <h4>Review Queue Clean!</h4>
              <p style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>All generated items have been approved or moderated.</p>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {reviewItems.map(item => (
                <div
                  key={item.id}
                  style={{
                    background: 'var(--card-background)',
                    padding: '1.2rem',
                    borderRadius: '12px',
                    border: '1px solid var(--border-color)',
                    display: 'flex',
                    justifyContent: 'space-between',
                    gap: '1rem'
                  }}
                >
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', marginBottom: '0.4rem' }}>
                      <span style={{ fontSize: '11px', fontWeight: 800, padding: '2px 8px', borderRadius: '4px', background: '#0058FF', color: 'white' }}>
                        {item.format}
                      </span>
                      <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{item.context_type}</span>
                    </div>

                    <h4 style={{ fontSize: '15px', fontWeight: 700, margin: '0.3rem 0' }}>{item.title_prompt}</h4>
                    {item.description && <p style={{ fontSize: '12px', color: 'var(--text-secondary)', margin: '0.2rem 0' }}>{item.description}</p>}

                    <div style={{ display: 'flex', gap: '0.5rem', marginTop: '0.6rem', flexWrap: 'wrap' }}>
                      {item.options.map(opt => (
                        <span key={opt.id} style={{ fontSize: '12px', padding: '4px 10px', borderRadius: '6px', background: 'var(--background-color)', border: '1px solid var(--border-color)' }}>
                          {opt.label}
                        </span>
                      ))}
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '0.6rem', alignItems: 'center' }}>
                    <button
                      onClick={() => handleStatusUpdate(item.id, 'ACTIVE')}
                      style={{ padding: '0.5rem 1rem', borderRadius: '6px', background: '#10B981', color: 'white', border: 'none', cursor: 'pointer', fontWeight: 700, fontSize: '12px' }}
                    >
                      Approve ✓
                    </button>
                    <button
                      onClick={() => handleStatusUpdate(item.id, 'REJECTED')}
                      style={{ padding: '0.5rem 1rem', borderRadius: '6px', background: '#EF4444', color: 'white', border: 'none', cursor: 'pointer', fontWeight: 700, fontSize: '12px' }}
                    >
                      Reject ✕
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* TAB 6: BANK HEALTH */}
      {activeTab === 'health' && (
        <div style={{ background: 'var(--card-background)', padding: '1.5rem', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 800, marginBottom: '0.5rem' }}>Content Bank Health & Coverage Heatmap</h3>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>Identifies coverage shortages across taxonomies to recommend targeted AI generation.</p>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1rem' }}>
            {healthItems.map(item => (
              <div
                key={item.id}
                style={{
                  padding: '1.2rem',
                  borderRadius: '10px',
                  border: '1px solid var(--border-color)',
                  background: 'var(--background-color)',
                  borderLeft: `4px solid ${
                    item.health_status === 'Healthy' ? '#10B981' :
                    item.health_status === 'Medium' ? '#0058FF' :
                    item.health_status === 'Low' ? '#F59E0B' : '#EF4444'
                  }`
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontWeight: 700, fontSize: '14px' }}>{item.name}</span>
                  <span style={{
                    fontSize: '11px',
                    fontWeight: 800,
                    padding: '2px 6px',
                    borderRadius: '4px',
                    background: item.health_status === 'Healthy' ? 'rgba(16, 185, 129, 0.2)' : 'rgba(239, 68, 68, 0.2)',
                    color: item.health_status === 'Healthy' ? '#10B981' : '#EF4444'
                  }}>
                    {item.health_status}
                  </span>
                </div>
                <div style={{ fontSize: '13px', marginTop: '0.4rem', color: 'var(--text-secondary)' }}>
                  Active Items: <strong>{item.active_count}</strong>
                </div>
                {item.recommendation && (
                  <div style={{ marginTop: '0.6rem', fontSize: '11.5px', color: '#F59E0B' }}>
                    💡 {item.recommendation}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
