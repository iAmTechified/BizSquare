import { ContentFormat, SignalType } from '../types/interest_engine.types';

export interface FormatDefinition {
  format: ContentFormat;
  displayName: string;
  description: string;
  minOptions: number;
  maxOptions: number;
  defaultSignalWeights: Record<string, { signalType: SignalType; weight: number }>;
  validate(options: { option_key: string; label: string }[]): { isValid: boolean; error?: string };
}

export class ContentFormatRegistry {
  private static formats: Map<ContentFormat, FormatDefinition> = new Map();

  static initialize() {
    // 1. THIS_OR_THAT
    this.register({
      format: 'THIS_OR_THAT',
      displayName: 'This or That',
      description: 'Two contrasting choices to discover directional preference.',
      minOptions: 2,
      maxOptions: 2,
      defaultSignalWeights: {
        opt_a: { signalType: 'positive', weight: 1.0 },
        opt_b: { signalType: 'positive', weight: 1.0 },
      },
      validate(options) {
        if (options.length !== 2) return { isValid: false, error: 'THIS_OR_THAT must have exactly 2 options.' };
        return { isValid: true };
      },
    });

    // 2. PICK_ONE
    this.register({
      format: 'PICK_ONE',
      displayName: 'Pick One',
      description: 'Select one option from 2 to 5 structured choices.',
      minOptions: 2,
      maxOptions: 5,
      defaultSignalWeights: {},
      validate(options) {
        if (options.length < 2 || options.length > 5) {
          return { isValid: false, error: 'PICK_ONE must have between 2 and 5 options.' };
        }
        return { isValid: true };
      },
    });

    // 3. WOULD_YOU
    this.register({
      format: 'WOULD_YOU',
      displayName: 'Would You?',
      description: 'Yes / Maybe / No reaction to test curiosity or acceptance.',
      minOptions: 2,
      maxOptions: 3,
      defaultSignalWeights: {
        yes: { signalType: 'positive', weight: 1.0 },
        maybe: { signalType: 'weak_positive', weight: 0.5 },
        no: { signalType: 'negative', weight: -0.5 },
      },
      validate(options) {
        if (options.length < 2 || options.length > 3) {
          return { isValid: false, error: 'WOULD_YOU must have 2 or 3 options (e.g. Yes, Maybe, No).' };
        }
        return { isValid: true };
      },
    });

    // 4. REACTION_CARD
    this.register({
      format: 'REACTION_CARD',
      displayName: 'Reaction Card',
      description: 'Content-focused card with quick emotional/curiosity reactions.',
      minOptions: 2,
      maxOptions: 4,
      defaultSignalWeights: {
        react_love: { signalType: 'positive', weight: 1.0 },
        react_curious: { signalType: 'weak_positive', weight: 0.5 },
        react_skip: { signalType: 'neutral', weight: 0.0 },
      },
      validate(options) {
        if (options.length < 2) return { isValid: false, error: 'REACTION_CARD requires at least 2 reaction buttons.' };
        return { isValid: true };
      },
    });

    // 5. SCENARIO
    this.register({
      format: 'SCENARIO',
      displayName: 'Scenario',
      description: 'Situational dilemma discovering context, priorities, and urgency.',
      minOptions: 2,
      maxOptions: 4,
      defaultSignalWeights: {},
      validate(options) {
        if (options.length < 2 || options.length > 4) {
          return { isValid: false, error: 'SCENARIO requires 2 to 4 actionable choices.' };
        }
        return { isValid: true };
      },
    });

    // 6. COMPARE
    this.register({
      format: 'COMPARE',
      displayName: 'Compare',
      description: 'Direct comparison between two concepts, products, or services.',
      minOptions: 2,
      maxOptions: 2,
      defaultSignalWeights: {
        opt_a: { signalType: 'positive', weight: 1.0 },
        opt_b: { signalType: 'positive', weight: 1.0 },
      },
      validate(options) {
        if (options.length !== 2) return { isValid: false, error: 'COMPARE requires exactly 2 alternatives.' };
        return { isValid: true };
      },
    });

    // 7. QUICK_OPINION
    this.register({
      format: 'QUICK_OPINION',
      displayName: 'Quick Opinion',
      description: 'Rapid assessment of value (Definitely / Maybe / Not for me).',
      minOptions: 2,
      maxOptions: 3,
      defaultSignalWeights: {
        opt_def: { signalType: 'positive', weight: 1.0 },
        opt_maybe: { signalType: 'weak_positive', weight: 0.4 },
        opt_no: { signalType: 'negative', weight: -0.4 },
      },
      validate(options) {
        if (options.length < 2 || options.length > 3) {
          return { isValid: false, error: 'QUICK_OPINION requires 2 or 3 opinion options.' };
        }
        return { isValid: true };
      },
    });

    // 8. INTENT_CHOICE
    this.register({
      format: 'INTENT_CHOICE',
      displayName: 'Intent / Choice',
      description: 'Actionable choice detecting commercial readiness or timing.',
      minOptions: 2,
      maxOptions: 4,
      defaultSignalWeights: {
        act_now: { signalType: 'intent', weight: 1.5 },
        act_wait: { signalType: 'weak_positive', weight: 0.5 },
        act_alt: { signalType: 'neutral', weight: 0.2 },
      },
      validate(options) {
        if (options.length < 2 || options.length > 4) {
          return { isValid: false, error: 'INTENT_CHOICE requires 2 to 4 intent options.' };
        }
        return { isValid: true };
      },
    });
  }

  static register(def: FormatDefinition) {
    this.formats.set(def.format, def);
  }

  static get(format: ContentFormat): FormatDefinition | undefined {
    if (this.formats.size === 0) this.initialize();
    return this.formats.get(format);
  }

  static getAll(): FormatDefinition[] {
    if (this.formats.size === 0) this.initialize();
    return Array.from(this.formats.values());
  }
}
