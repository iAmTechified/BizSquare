export type NotificationSource = 'BACKEND' | 'ADMIN' | 'LOCAL';
export type NotificationCategory = 'CONTACT_GAIN' | 'SPOTLIGHT' | 'DAILY_PULSE' | 'SYSTEM';
export type NotificationPriority = 'ACTION_REQUIRED' | 'IMPORTANT' | 'INFORMATIONAL';
export type VisualVariant = 'DEFAULT' | 'HIGHLIGHT' | 'ALERT' | 'SUCCESS';
export type SoundVariant = 'DEFAULT' | 'URGENT' | 'CHIME';

export interface NotificationEventDefinition {
  eventType: string;
  category: NotificationCategory;
  priority: NotificationPriority;
  visualVariant: VisualVariant;
  soundVariant: SoundVariant;
  defaultDeepLink: string;
  render: (params: Record<string, any>) => { title: string; body: string; deepLink: string };
}

export const NotificationEventRegistry: Record<string, NotificationEventDefinition> = {
  'contact_gain.completed': {
    eventType: 'contact_gain.completed',
    category: 'CONTACT_GAIN',
    priority: 'IMPORTANT',
    visualVariant: 'SUCCESS',
    soundVariant: 'CHIME',
    defaultDeepLink: 'bizsquare://contacts/square',
    render: (p) => {
      const count = p.contactCount ?? 0;
      const noun = count === 1 ? 'contact' : 'contacts';
      return {
        title: 'Your new contacts are ready',
        body: `You received ${count} new Square ${noun} from this week's matching cycle.`,
        deepLink: 'bizsquare://contacts/square',
      };
    },
  },

  'contact_gain.sync_completed': {
    eventType: 'contact_gain.sync_completed',
    category: 'CONTACT_GAIN',
    priority: 'INFORMATIONAL',
    visualVariant: 'DEFAULT',
    soundVariant: 'DEFAULT',
    defaultDeepLink: 'bizsquare://contacts/square',
    render: (p) => {
      const count = p.syncedCount ?? 0;
      return {
        title: 'Contact sync complete',
        body: `Successfully synced ${count} contacts with your phone address book.`,
        deepLink: 'bizsquare://contacts/square',
      };
    },
  },

  'contact_gain.sync_failed': {
    eventType: 'contact_gain.sync_failed',
    category: 'CONTACT_GAIN',
    priority: 'ACTION_REQUIRED',
    visualVariant: 'ALERT',
    soundVariant: 'URGENT',
    defaultDeepLink: 'bizsquare://settings/permissions',
    render: (p) => {
      const reason = p.reason || 'Address book permission disabled';
      return {
        title: 'Contact sync needs attention',
        body: `Sync failed: ${reason}. Tap to fix sync settings.`,
        deepLink: 'bizsquare://settings/permissions',
      };
    },
  },

  'spotlight.turn_started': {
    eventType: 'spotlight.turn_started',
    category: 'SPOTLIGHT',
    priority: 'ACTION_REQUIRED',
    visualVariant: 'HIGHLIGHT',
    soundVariant: 'URGENT',
    defaultDeepLink: 'bizsquare://spotlight/turn',
    render: (p) => {
      const endDate = p.cycleEndDate || 'Sunday';
      return {
        title: "It's your Spotlight turn",
        body: `Your business is featured in this cycle's network Spotlight. Submit before ${endDate}.`,
        deepLink: 'bizsquare://spotlight/turn',
      };
    },
  },

  'spotlight.participation_received': {
    eventType: 'spotlight.participation_received',
    category: 'SPOTLIGHT',
    priority: 'INFORMATIONAL',
    visualVariant: 'DEFAULT',
    soundVariant: 'DEFAULT',
    defaultDeepLink: 'bizsquare://spotlight',
    render: (p) => {
      const partnerName = p.partnerName || 'A network member';
      return {
        title: 'New Spotlight partner',
        body: `${partnerName} shared your Spotlight post with their network.`,
        deepLink: 'bizsquare://spotlight',
      };
    },
  },

  'spotlight.participation_submitted': {
    eventType: 'spotlight.participation_submitted',
    category: 'SPOTLIGHT',
    priority: 'INFORMATIONAL',
    visualVariant: 'DEFAULT',
    soundVariant: 'DEFAULT',
    defaultDeepLink: 'bizsquare://spotlight/history',
    render: () => ({
      title: 'Spotlight post submitted',
      body: 'Your business offer has been submitted for admin review.',
      deepLink: 'bizsquare://spotlight/history',
    }),
  },

  'spotlight.participation_verified': {
    eventType: 'spotlight.participation_verified',
    category: 'SPOTLIGHT',
    priority: 'IMPORTANT',
    visualVariant: 'SUCCESS',
    soundVariant: 'CHIME',
    defaultDeepLink: 'bizsquare://spotlight',
    render: (p) => {
      const count = p.participantCount ?? 0;
      return {
        title: 'Your Spotlight is live',
        body: `Your business offer is now live and visible to ${count} network partners.`,
        deepLink: 'bizsquare://spotlight',
      };
    },
  },

  'spotlight.turn_expiring': {
    eventType: 'spotlight.turn_expiring',
    category: 'SPOTLIGHT',
    priority: 'ACTION_REQUIRED',
    visualVariant: 'ALERT',
    soundVariant: 'URGENT',
    defaultDeepLink: 'bizsquare://spotlight/turn',
    render: (p) => {
      const hoursLeft = p.hoursLeft ?? 12;
      return {
        title: 'Spotlight turn expiring soon',
        body: `Only ${hoursLeft} hours remaining to submit your offer for this cycle.`,
        deepLink: 'bizsquare://spotlight/turn',
      };
    },
  },

  'spotlight.cycle_completed': {
    eventType: 'spotlight.cycle_completed',
    category: 'SPOTLIGHT',
    priority: 'INFORMATIONAL',
    visualVariant: 'DEFAULT',
    soundVariant: 'DEFAULT',
    defaultDeepLink: 'bizsquare://spotlight/history',
    render: (p) => {
      const totalShared = p.totalShared ?? 0;
      return {
        title: 'Spotlight cycle completed',
        body: `This cycle completed with ${totalShared} total network partner shares.`,
        deepLink: 'bizsquare://spotlight/history',
      };
    },
  },

  'permission.contact_access_revoked': {
    eventType: 'permission.contact_access_revoked',
    category: 'SYSTEM',
    priority: 'ACTION_REQUIRED',
    visualVariant: 'ALERT',
    soundVariant: 'URGENT',
    defaultDeepLink: 'bizsquare://settings/permissions',
    render: () => ({
      title: 'Contact permission disabled',
      body: 'Turn on contact access to receive your weekly network batches.',
      deepLink: 'bizsquare://settings/permissions',
    }),
  },

  'account.security_event': {
    eventType: 'account.security_event',
    category: 'SYSTEM',
    priority: 'ACTION_REQUIRED',
    visualVariant: 'ALERT',
    soundVariant: 'URGENT',
    defaultDeepLink: 'bizsquare://settings/permissions',
    render: (p) => {
      const device = p.device || 'new device';
      return {
        title: 'Security Alert',
        body: `New login detected from ${device}. If this wasn't you, review your account security.`,
        deepLink: 'bizsquare://settings/permissions',
      };
    },
  },
};
