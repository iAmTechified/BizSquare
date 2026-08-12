import 'package:flutter_test/flutter_test.dart';
import 'package:bizsquare/core/models/wall_content_model.dart';
import 'package:bizsquare/core/models/interest_taxonomy_model.dart';
import 'package:bizsquare/core/models/interest_demand_model.dart';

void main() {
  group('1. Wall Content & 8 Multi-Format Model Tests', () {
    test('Correctly parses THIS_OR_THAT format session item', () {
      final json = {
        'content_id': 'content_tot_1',
        'format': 'THIS_OR_THAT',
        'title_prompt': 'Which would you rather upgrade right now?',
        'description': 'Smartphone vs Laptop preference',
        'context_type': 'general',
        'pool_type': 'PERSONALIZED',
        'order_index': 1,
        'options': [
          {'option_key': 'opt_a', 'label': 'Flagship Smartphone', 'subtext': 'Fast camera'},
          {'option_key': 'opt_b', 'label': 'Workstation Laptop', 'subtext': 'High RAM'},
        ],
      };

      final item = WallSessionItemModel.fromJson(json);
      expect(item.contentId, 'content_tot_1');
      expect(item.format, 'THIS_OR_THAT');
      expect(item.options.length, 2);
      expect(item.options[0].optionKey, 'opt_a');
      expect(item.options[1].optionKey, 'opt_b');
    });

    test('Correctly parses PICK_ONE format session item', () {
      final json = {
        'content_id': 'content_po_1',
        'format': 'PICK_ONE',
        'title_prompt': 'Select your primary focus area',
        'order_index': 2,
        'options': [
          {'option_key': 'opt_1', 'label': 'Logistics & Dispatch'},
          {'option_key': 'opt_2', 'label': 'Branding & Design'},
          {'option_key': 'opt_3', 'label': 'Targeted Advertising'},
        ],
      };

      final item = WallSessionItemModel.fromJson(json);
      expect(item.format, 'PICK_ONE');
      expect(item.options.length, 3);
    });

    test('Correctly parses WOULD_YOU format session item', () {
      final json = {
        'content_id': 'content_wy_1',
        'format': 'WOULD_YOU',
        'title_prompt': 'Would you invest in audio equipment?',
        'order_index': 3,
        'options': [
          {'option_key': 'yes', 'label': 'Definitely Yes 🔥'},
          {'option_key': 'maybe', 'label': 'Maybe / Curious 👀'},
          {'option_key': 'no', 'label': 'Not for Me'},
        ],
      };

      final item = WallSessionItemModel.fromJson(json);
      expect(item.format, 'WOULD_YOU');
      expect(item.options.length, 3);
      expect(item.options[0].optionKey, 'yes');
    });

    test('Correctly parses REACTION_CARD format session item', () {
      final json = {
        'content_id': 'content_rc_1',
        'format': 'REACTION_CARD',
        'title_prompt': 'Mobile 4K Video Rig for Product Shoots',
        'context_type': 'emerging',
        'order_index': 4,
        'options': [
          {'option_key': 'react_love', 'label': '❤️ Interested'},
          {'option_key': 'react_curious', 'label': '👀 Curious'},
          {'option_key': 'react_skip', 'label': '⏭️ Skip'},
        ],
      };

      final item = WallSessionItemModel.fromJson(json);
      expect(item.format, 'REACTION_CARD');
      expect(item.options.length, 3);
    });

    test('Correctly parses SCENARIO format session item', () {
      final json = {
        'content_id': 'content_scen_1',
        'format': 'SCENARIO',
        'title_prompt': '₦100,000 grant: where does it go?',
        'context_type': 'business',
        'order_index': 5,
        'options': [
          {'option_key': 'scen_a', 'label': 'Acquire Tools'},
          {'option_key': 'scen_b', 'label': 'Hire Dispatch'},
        ],
      };

      final item = WallSessionItemModel.fromJson(json);
      expect(item.format, 'SCENARIO');
      expect(item.options.length, 2);
    });

    test('Correctly parses INTENT_CHOICE format session item', () {
      final json = {
        'content_id': 'content_ic_1',
        'format': 'INTENT_CHOICE',
        'title_prompt': 'If a verified clean solar solution was available:',
        'order_index': 6,
        'options': [
          {'option_key': 'act_now', 'label': 'Get Quote Now ⚡'},
          {'option_key': 'act_wait', 'label': 'Save for Later'},
        ],
      };

      final item = WallSessionItemModel.fromJson(json);
      expect(item.format, 'INTENT_CHOICE');
      expect(item.options.length, 2);
    });
  });

  group('2. Interest Taxonomy Model Tests', () {
    test('Parses hierarchical taxonomy node and children', () {
      final json = {
        'id': 'tax_tech_1',
        'slug': 'tech',
        'name': 'Technology',
        'context_type': 'general',
        'icon': 'devices',
        'sort_order': 1,
        'is_active': true,
        'aliases': ['tech', 'electronics', 'gadgets'],
        'content_count': 15,
        'active_content_count': 12,
        'children': [
          {
            'id': 'tax_phone_1',
            'slug': 'tech_smartphones',
            'name': 'Smartphones',
            'context_type': 'consumer',
            'icon': 'smartphone',
            'sort_order': 1,
            'is_active': true,
            'aliases': ['mobile', 'phones'],
            'content_count': 8,
            'active_content_count': 6,
            'children': [],
          },
        ],
      };

      final tax = InterestTaxonomyModel.fromJson(json);
      expect(tax.name, 'Technology');
      expect(tax.children.length, 1);
      expect(tax.children[0].name, 'Smartphones');
      expect(tax.aliases.contains('gadgets'), isTrue);
    });
  });

  group('3. Current Demand Output Model Tests', () {
    test('Parses tiered demand output with high, medium, and emerging buckets', () {
      final json = {
        'user_id': 'user_123',
        'calculated_at': '2026-08-09T14:00:00Z',
        'demand_tier_high': [
          {
            'taxonomy_id': 'tax_1',
            'slug': 'tech_smartphones',
            'name': 'Smartphones',
            'context_type': 'consumer',
            'state': 'ONGOING',
            'strength': 0.85,
            'confidence': 0.90,
            'recency_score': 1.0,
            'frequency_count': 5,
            'is_baseline': true,
          }
        ],
        'demand_tier_medium': [],
        'demand_tier_emerging': [
          {
            'taxonomy_id': 'tax_2',
            'slug': 'creative_photography',
            'name': 'Photography',
            'context_type': 'emerging',
            'state': 'EMERGING',
            'strength': 0.35,
            'confidence': 0.20,
            'recency_score': 1.0,
            'frequency_count': 1,
            'is_baseline': false,
          }
        ],
        'background_interests': [],
        'dormant_interests': [],
      };

      final demand = UserCurrentDemandModel.fromJson(json);
      expect(demand.demandTierHigh.length, 1);
      expect(demand.demandTierHigh[0].state, 'ONGOING');
      expect(demand.demandTierHigh[0].strength, 0.85);
      expect(demand.demandTierEmerging.length, 1);
      expect(demand.demandTierEmerging[0].slug, 'creative_photography');
    });
  });
}
