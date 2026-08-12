import { pool } from '../db/pool';

export class ContentAnalyticsService {
  /**
   * High-level Content Bank Overview metrics
   */
  static async getOverviewMetrics(): Promise<{
    totalContent: number;
    activeContent: number;
    reviewPending: number;
    pausedContent: number;
    archivedContent: number;
    formatDistribution: { format: string; count: number }[];
    contextDistribution: { context_type: string; count: number }[];
  }> {
    const statusQuery = `
      SELECT status, COUNT(*) as count 
      FROM content_items 
      GROUP BY status
    `;
    const { rows: statusRows } = await pool.query(statusQuery);

    const formatQuery = `
      SELECT format, COUNT(*) as count 
      FROM content_items 
      GROUP BY format
    `;
    const { rows: formatRows } = await pool.query(formatQuery);

    const contextQuery = `
      SELECT context_type, COUNT(*) as count 
      FROM content_items 
      GROUP BY context_type
    `;
    const { rows: contextRows } = await pool.query(contextQuery);

    let totalContent = 0;
    let activeContent = 0;
    let reviewPending = 0;
    let pausedContent = 0;
    let archivedContent = 0;

    statusRows.forEach(r => {
      const count = parseInt(r.count, 10);
      totalContent += count;
      if (r.status === 'ACTIVE' || r.status === 'APPROVED') activeContent += count;
      if (r.status === 'REVIEW' || r.status === 'DRAFT') reviewPending += count;
      if (r.status === 'PAUSED') pausedContent += count;
      if (r.status === 'ARCHIVED' || r.status === 'REJECTED') archivedContent += count;
    });

    return {
      totalContent,
      activeContent,
      reviewPending,
      pausedContent,
      archivedContent,
      formatDistribution: formatRows.map(r => ({ format: r.format, count: parseInt(r.count, 10) })),
      contextDistribution: contextRows.map(r => ({ context_type: r.context_type, count: parseInt(r.count, 10) })),
    };
  }

  /**
   * Taxonomy coverage health analysis (Healthy, Medium, Low, Critical)
   */
  static async getBankHealthCoverage(): Promise<{
    taxonomies: {
      id: string;
      slug: string;
      name: string;
      icon: string;
      active_count: number;
      total_count: number;
      health_status: 'Healthy' | 'Medium' | 'Low' | 'Critical';
      recommendation?: string | undefined;
    }[];
  }> {
    const query = `
      SELECT 
        t.id, t.slug, t.name, t.icon,
        COUNT(ci.id) as total_count,
        COUNT(CASE WHEN ci.status = 'ACTIVE' THEN 1 END) as active_count
      FROM interest_taxonomies t
      LEFT JOIN content_taxonomy_links ctl ON ctl.taxonomy_id = t.id
      LEFT JOIN content_items ci ON ci.id = ctl.content_id
      WHERE t.is_active = TRUE
      GROUP BY t.id, t.slug, t.name, t.icon
      ORDER BY active_count ASC, total_count ASC
    `;
    const { rows } = await pool.query(query);

    const taxonomies = rows.map(r => {
      const active = parseInt(r.active_count, 10);
      const total = parseInt(r.total_count, 10);

      let health_status: 'Healthy' | 'Medium' | 'Low' | 'Critical' = 'Healthy';
      let recommendation: string | undefined = undefined;

      if (active === 0) {
        health_status = 'Critical';
        recommendation = 'Zero active content. Generate at least 15 items.';
      } else if (active < 5) {
        health_status = 'Low';
        recommendation = 'Low content coverage. Generate 10-20 items across formats.';
      } else if (active < 15) {
        health_status = 'Medium';
        recommendation = 'Moderate coverage. Add scenarios and compare cards.';
      } else {
        health_status = 'Healthy';
      }

      return {
        id: String(r.id),
        slug: String(r.slug),
        name: String(r.name),
        icon: String(r.icon),
        active_count: active,
        total_count: total,
        health_status,
        recommendation,
      };
    });

    return { taxonomies };
  }

  /**
   * Wall interaction analytics
   */
  static async getWallAnalytics(): Promise<{
    totalSessionsStarted: number;
    totalSessionsCompleted: number;
    completionRatePct: number;
    totalInteractions: number;
    formatPerformance: { format: string; interactionRatePct: number; avgDwellMs: number }[];
  }> {
    const sessionQuery = `
      SELECT 
        COUNT(*) as total_started,
        COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as total_completed
      FROM wall_sessions
    `;
    const { rows: sessionRows } = await pool.query(sessionQuery);

    const formatPerfQuery = `
      SELECT 
        ci.format,
        SUM(cp.impressions_count) as total_imp,
        SUM(cp.interactions_count) as total_act,
        AVG(cp.avg_dwell_ms) as avg_dwell
      FROM content_items ci
      JOIN content_performance cp ON cp.content_id = ci.id
      GROUP BY ci.format
    `;
    const { rows: formatRows } = await pool.query(formatPerfQuery);

    const totalStarted = parseInt(sessionRows[0].total_started || '0', 10);
    const totalCompleted = parseInt(sessionRows[0].total_completed || '0', 10);
    const completionRatePct = totalStarted > 0 ? Math.round((totalCompleted / totalStarted) * 100) : 100;

    const formatPerformance = formatRows.map(r => {
      const imp = parseInt(r.total_imp || '0', 10);
      const act = parseInt(r.total_act || '0', 10);
      const dwell = Math.round(parseFloat(r.avg_dwell || '0'));
      return {
        format: r.format,
        interactionRatePct: imp > 0 ? Math.round((act / imp) * 100) : 0,
        avgDwellMs: dwell,
      };
    });

    return {
      totalSessionsStarted: totalStarted,
      totalSessionsCompleted: totalCompleted,
      completionRatePct,
      totalInteractions: formatRows.reduce((acc, r) => acc + parseInt(r.total_act || '0', 10), 0),
      formatPerformance,
    };
  }
}
