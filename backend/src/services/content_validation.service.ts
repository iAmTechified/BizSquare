import { ContentFormat, ContextType, SignalType } from '../types/interest_engine.types';
import { ContentFormatRegistry } from './content_format_registry';

export interface RawGeneratedItem {
  format: ContentFormat;
  title_prompt: string;
  description?: string;
  context_type: ContextType;
  target_audience?: string;
  options: {
    option_key: string;
    label: string;
    subtext?: string;
    signals: {
      taxonomy_slug: string;
      signal_type: SignalType;
      weight: number;
    }[];
  }[];
}

export class ContentValidationService {
  /**
   * Validates a generated content item
   */
  static validateItem(item: RawGeneratedItem): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    // 1. Format validation
    const formatDef = ContentFormatRegistry.get(item.format);
    if (!formatDef) {
      errors.push(`Unsupported content format: ${item.format}`);
      return { isValid: false, errors };
    }

    // 2. Prompt clarity & length check
    if (!item.title_prompt || item.title_prompt.trim().length < 8) {
      errors.push('Title prompt is too short or missing.');
    }
    if (item.title_prompt && item.title_prompt.length > 300) {
      errors.push('Title prompt exceeds maximum length of 300 characters.');
    }

    // 3. Option count validation
    const optionCheck = formatDef.validate(item.options || []);
    if (!optionCheck.isValid) {
      errors.push(optionCheck.error || 'Invalid options count for format.');
    }

    // 4. Signal mapping validation
    if (item.options) {
      item.options.forEach((opt, idx) => {
        if (!opt.label || opt.label.trim().length === 0) {
          errors.push(`Option ${idx + 1} is missing a label.`);
        }
        if (!opt.signals || opt.signals.length === 0) {
          errors.push(`Option ${idx + 1} (${opt.label || 'unnamed'}) has no taxonomy signal mappings.`);
        } else {
          opt.signals.forEach(sig => {
            if (!sig.taxonomy_slug) {
              errors.push(`Option ${opt.label} has a signal without a taxonomy slug.`);
            }
            if (typeof sig.weight !== 'number') {
              errors.push(`Option ${opt.label} has an invalid signal weight.`);
            }
          });
        }
      });
    }

    return { isValid: errors.length === 0, errors };
  }
}
