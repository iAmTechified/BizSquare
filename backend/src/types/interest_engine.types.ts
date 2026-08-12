export type ContentFormat =
  | 'THIS_OR_THAT'
  | 'PICK_ONE'
  | 'WOULD_YOU'
  | 'REACTION_CARD'
  | 'SCENARIO'
  | 'COMPARE'
  | 'QUICK_OPINION'
  | 'INTENT_CHOICE';

export type ContentStatus =
  | 'DRAFT'
  | 'GENERATING'
  | 'REVIEW'
  | 'APPROVED'
  | 'ACTIVE'
  | 'PAUSED'
  | 'ARCHIVED'
  | 'REJECTED';

export type ContextType =
  | 'general'
  | 'business'
  | 'personal'
  | 'lifestyle'
  | 'consumer'
  | 'emerging'
  | 'mixed';

export type SignalType =
  | 'positive'
  | 'weak_positive'
  | 'negative'
  | 'neutral'
  | 'intent'
  | 'context';

export type InterestLifecycleState =
  | 'EMERGING'
  | 'ACTIVE'
  | 'ONGOING'
  | 'DORMANT'
  | 'SUPPRESSED';

export type WallSessionStatus = 'STARTED' | 'COMPLETED' | 'ABANDONED';

export type ContentPoolType = 'PERSONALIZED' | 'RELATED' | 'EXPLORATION' | 'BROAD';

export interface InterestTaxonomyNode {
  id: string;
  slug: string;
  name: string;
  parent_id?: string | null;
  description?: string;
  context_type: ContextType;
  icon: string;
  sort_order: number;
  is_active: boolean;
  aliases: string[];
  content_count: number;
  active_content_count: number;
  children?: InterestTaxonomyNode[];
}

export interface TaxonomyRelationship {
  id: string;
  source_id: string;
  target_id: string;
  target_name?: string;
  target_slug?: string;
  relationship_type: 'related' | 'adjacent' | 'prerequisite' | 'subcategory';
  weight: number;
}

export interface ContentOption {
  id: string;
  content_id: string;
  option_key: string;
  label: string;
  subtext?: string;
  media_url?: string;
  order_index: number;
  signals?: ContentSignalMapping[];
}

export interface ContentSignalMapping {
  id?: string;
  content_id: string;
  option_id?: string;
  taxonomy_id: string;
  taxonomy_slug?: string;
  taxonomy_name?: string;
  signal_type: SignalType;
  weight: number;
  context: ContextType;
}

export interface ContentItem {
  id: string;
  format: ContentFormat;
  status: ContentStatus;
  title_prompt: string;
  description?: string;
  media_url?: string;
  media_type: 'none' | 'image' | 'icon' | 'animation';
  context_type: ContextType;
  target_audience: string;
  difficulty: 'simple' | 'normal' | 'advanced';
  version: number;
  batch_id?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
  published_at?: string;
  taxonomies?: { id: string; name: string; slug: string; is_primary: boolean }[];
  options: ContentOption[];
  performance?: ContentPerformance;
}

export interface ContentPerformance {
  content_id: string;
  impressions_count: number;
  interactions_count: number;
  skips_count: number;
  completions_count: number;
  avg_dwell_ms: number;
  positive_signals_generated: number;
  last_served_at?: string;
}

export interface WallSessionItemPayload {
  content_id: string;
  format: ContentFormat;
  title_prompt: string;
  description?: string | undefined;
  media_url?: string | undefined;
  media_type: string;
  context_type: ContextType;
  pool_type: ContentPoolType;
  options: {
    option_key: string;
    label: string;
    subtext?: string | undefined;
    media_url?: string | undefined;
  }[];
  order_index: number;
}

export interface WallSessionPayload {
  session_id: string;
  date: string;
  item_count: number;
  items: WallSessionItemPayload[];
  target_mix: {
    personalized: number;
    related: number;
    exploration: number;
    broad: number;
  };
}

export interface UserCurrentDemandItem {
  taxonomy_id: string;
  slug: string;
  name: string;
  context_type: ContextType;
  state: InterestLifecycleState;
  strength: number;
  confidence: number;
  recency_score: number;
  frequency_count: number;
  last_positive_at?: string;
  is_baseline: boolean;
}

export interface UserCurrentDemandOutput {
  user_id: string;
  calculated_at: string;
  demand_tier_high: UserCurrentDemandItem[];
  demand_tier_medium: UserCurrentDemandItem[];
  demand_tier_emerging: UserCurrentDemandItem[];
  background_interests: UserCurrentDemandItem[];
  dormant_interests: UserCurrentDemandItem[];
}
