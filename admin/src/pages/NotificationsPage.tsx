import React, { useEffect, useState, useCallback } from 'react';
import {
  adminAuthApi,
  AdminNotificationBroadcastPayload,
  NotificationTemplateItem,
  ScheduledNotificationItem,
  SentNotificationItem,
} from '../api/adminAuthApi';
import { useAdminAuth } from '../context/AdminAuthContext';
import { useToast } from '../context/ToastContext';
import { useConfirmation } from '../context/ConfirmationContext';
import { GlobalLoadingState } from '../components/common/GlobalLoadingState';
import { GlobalEmptyState } from '../components/common/GlobalEmptyState';
import { Hugeicon } from '../components/common/Hugeicon';
import { NotificationConfirmationModal } from '../components/notifications/NotificationConfirmationModal';

const APPROVED_DESTINATIONS = [
  { label: 'Home Page', value: 'bizsquare://home' },
  { label: 'Square Contacts', value: 'bizsquare://contacts/square' },
  { label: 'Spotlight Showcase', value: 'bizsquare://spotlight' },
  { label: 'Spotlight History', value: 'bizsquare://spotlight/history' },
  { label: 'User Profile', value: 'bizsquare://profile' },
  { label: 'Permission Setup', value: 'bizsquare://permissions' },
];

const ALLOWED_VARIABLES = ['{{firstName}}', '{{newContactCount}}', '{{spotlightDate}}', '{{contactCount}}'];

export const NotificationsPage: React.FC = () => {
  const { hasPermission } = useAdminAuth();
  const { showToast } = useToast();
  const { confirm } = useConfirmation();

  const canSend = hasPermission('notifications.send');

  const [activeTab, setActiveTab] = useState<'compose' | 'scheduled' | 'sent' | 'history'>('compose');

  // Form State
  const [title, setTitle] = useState<string>('');
  const [body, setBody] = useState<string>('');
  const [category, setCategory] = useState<'ANNOUNCEMENT' | 'SPOTLIGHT' | 'CONTACT_GAIN' | 'UPDATE' | 'IMPORTANT' | 'CELEBRATION'>('ANNOUNCEMENT');
  const [visualVariant, setVisualVariant] = useState<'DEFAULT' | 'HIGHLIGHT' | 'ALERT' | 'SUCCESS' | 'GOLD'>('DEFAULT');
  const [soundVariant, setSoundVariant] = useState<'DEFAULT' | 'URGENT' | 'CHIME'>('DEFAULT');
  const [destination, setDestination] = useState<string>('bizsquare://home');
  const [audienceType, setAudienceType] = useState<'ALL' | 'NEW_USERS' | 'INCOMPLETE_SETUP' | 'SPOTLIGHT_USERS' | 'CONTACT_GAIN_USERS' | 'INDIVIDUAL'>('ALL');
  const [individualUserId, setIndividualUserId] = useState<string>('');
  const [isScheduled, setIsScheduled] = useState<boolean>(false);
  const [scheduledAt, setScheduledAt] = useState<string>('');

  // Data & Estimate State
  const [templates, setTemplates] = useState<NotificationTemplateItem[]>([]);
  const [scheduled, setScheduled] = useState<ScheduledNotificationItem[]>([]);
  const [sent, setSent] = useState<SentNotificationItem[]>([]);
  const [estimatedRecipients, setEstimatedRecipients] = useState<number>(0);

  const [loading, setLoading] = useState<boolean>(true);
  const [submitting, setSubmitting] = useState<boolean>(false);
  const [showConfirmModal, setShowConfirmModal] = useState<boolean>(false);
  const [validationError, setValidationError] = useState<string | null>(null);

  // Fetch initial templates & backend estimate
  const loadInitialData = useCallback(async () => {
    setLoading(true);
    try {
      const [resTemplates, resEstimate, resScheduled, resSent] = await Promise.all([
        adminAuthApi.getNotificationTemplates().catch(() => ({ success: true, templates: [] })),
        adminAuthApi.getNotificationRecipientEstimate(audienceType, individualUserId).catch(() => ({ success: true, audience_type: 'ALL', estimated_count: 0 })),
        adminAuthApi.getScheduledNotifications().catch(() => ({ success: true, scheduled: [] })),
        adminAuthApi.getSentNotifications(20, 0).catch(() => ({ success: true, sent: [] })),
      ]);

      setTemplates(resTemplates.templates || []);
      setEstimatedRecipients(resEstimate.estimated_count || 0);
      setScheduled(resScheduled.scheduled || []);
      setSent(resSent.sent || []);
    } catch (err: any) {
      console.error('Failed to load notification composer data:', err);
    } finally {
      setLoading(false);
    }
  }, [audienceType, individualUserId]);

  useEffect(() => {
    loadInitialData();
  }, [loadInitialData]);

  // Recalculate recipient estimate whenever audience selection changes
  useEffect(() => {
    adminAuthApi
      .getNotificationRecipientEstimate(audienceType, individualUserId)
      .then((res) => setEstimatedRecipients(res.estimated_count || 0))
      .catch(() => setEstimatedRecipients(0));
  }, [audienceType, individualUserId]);

  // Apply template defaults
  const handleSelectTemplate = (t: NotificationTemplateItem) => {
    setTitle(t.default_title);
    setBody(t.default_body);
    setCategory(t.category as any);
    setVisualVariant(t.visual_variant as any);
    setSoundVariant(t.sound_variant as any);
    setDestination(t.default_destination);
    setValidationError(null);
    showToast({
      type: 'info',
      title: 'Template Loaded',
      message: `Loaded template: "${t.name}".`,
    });
  };

  // Live variable validation
  const validateForm = (): boolean => {
    setValidationError(null);

    if (!title.trim()) {
      setValidationError('Notification title is required.');
      return false;
    }
    if (!body.trim()) {
      setValidationError('Notification body text is required.');
      return false;
    }

    const fullText = `${title} ${body}`;
    const variableMatches = fullText.match(/\{\{[^}]+\}\}/g) || [];
    for (const match of variableMatches) {
      if (!ALLOWED_VARIABLES.includes(match)) {
        setValidationError(`Unsupported variable "${match}". Allowed variables are: ${ALLOWED_VARIABLES.join(', ')}`);
        return false;
      }
    }

    if (isScheduled && !scheduledAt) {
      setValidationError('Please select a valid future date and time for scheduled send.');
      return false;
    }

    return true;
  };

  const handleOpenConfirm = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;
    setShowConfirmModal(true);
  };

  const handleExecuteSend = async () => {
    setSubmitting(true);
    try {
      const payload: AdminNotificationBroadcastPayload = {
        title: title.trim(),
        body: body.trim(),
        category,
        visual_variant: visualVariant,
        sound_variant: soundVariant,
        destination,
        audience_type: audienceType,
        individual_user_id: audienceType === 'INDIVIDUAL' ? individualUserId : undefined,
        scheduled_at: isScheduled ? new Date(scheduledAt).toISOString() : undefined,
      };

      const res = await adminAuthApi.sendAdminNotification(payload);

      showToast({
        type: 'success',
        title: res.is_scheduled ? 'Broadcast Scheduled' : 'Broadcast Sent',
        message: res.message,
      });

      setShowConfirmModal(false);
      // Reset form
      setTitle('');
      setBody('');
      setIsScheduled(false);
      setScheduledAt('');
      loadInitialData();
    } catch (err: any) {
      console.error('Send broadcast error:', err);
      showToast({
        type: 'error',
        title: 'Broadcast Execution Error',
        message: err.message || 'Failed to send broadcast notification.',
      });
    } finally {
      setSubmitting(false);
    }
  };

  const handleCancelScheduled = (item: ScheduledNotificationItem) => {
    confirm({
      title: `Cancel Scheduled Broadcast: "${item.title}"`,
      description: 'Are you sure you want to cancel this scheduled notification?',
      consequence: 'It will be removed from the pending queue and will not be delivered to recipients.',
      isDestructive: true,
      confirmLabel: 'Yes, Cancel Broadcast',
      onConfirm: async () => {
        const res = await adminAuthApi.cancelScheduledNotification(item.id);
        showToast({ type: 'success', title: 'Broadcast Cancelled', message: res.message });
        loadInitialData();
      },
    });
  };

  // Preview variable substitution with sample data
  const renderPreviewText = (text: string) => {
    return text
      .replace(/\{\{firstName\}\}/g, 'Alex')
      .replace(/\{\{newContactCount\}\}/g, '12')
      .replace(/\{\{spotlightDate\}\}/g, 'Friday')
      .replace(/\{\{contactCount\}\}/g, '184');
  };

  if (loading && templates.length === 0 && scheduled.length === 0 && sent.length === 0) {
    return <GlobalLoadingState type="page" message="Loading unified Notification Composer & Templates…" />;
  }

  return (
    <div className="flex flex-col gap-6 fade-up">
      {/* Confirmation Modal */}
      {showConfirmModal && (
        <NotificationConfirmationModal
          payload={{
            title,
            body,
            category,
            visual_variant: visualVariant,
            sound_variant: soundVariant,
            destination,
            audience_type: audienceType,
            individual_user_id: individualUserId,
            scheduled_at: isScheduled ? scheduledAt : undefined,
          }}
          estimatedRecipients={estimatedRecipients}
          submitting={submitting}
          onClose={() => setShowConfirmModal(false)}
          onConfirm={handleExecuteSend}
        />
      )}

      {/* Page Header */}
      <div className="page-header">
        <div className="page-header-left">
          <h1 className="page-title">Notification Composer & Broadcasts</h1>
          <p className="page-subtitle">Compose, schedule, and track network notification broadcasts.</p>
        </div>

        <button type="button" className="btn btn-secondary" onClick={loadInitialData}>
          <Hugeicon name="refresh" className={loading ? 'animate-spin' : ''} size={14} />
          Refresh
        </button>
      </div>

      {/* TABS */}
      <div className="tab-list">
        <button
          type="button"
          className={`tab-btn ${activeTab === 'compose' ? 'active' : ''}`}
          onClick={() => setActiveTab('compose')}
        >
          <Hugeicon name="send" size={14} />
          Compose
        </button>
        <button
          type="button"
          className={`tab-btn ${activeTab === 'scheduled' ? 'active' : ''}`}
          onClick={() => setActiveTab('scheduled')}
        >
          <Hugeicon name="schedule" size={14} />
          Scheduled ({scheduled.length})
        </button>
        <button
          type="button"
          className={`tab-btn ${activeTab === 'sent' ? 'active' : ''}`}
          onClick={() => setActiveTab('sent')}
        >
          <Hugeicon name="audit" size={14} />
          Sent History ({sent.length})
        </button>
      </div>

      {/* SECTION 1: COMPOSE */}
      {activeTab === 'compose' && (
        <div className="grid-2 gap-6 fade-up">
          {/* Form Side */}
          <form onSubmit={handleOpenConfirm} className="card flex flex-col gap-4">
            <div className="card-header flex justify-between items-center">
              <span className="card-title">
                <Hugeicon name="send" size={16} state="active" />
                Notification Composer
              </span>
              <span className="badge badge-blue">
                Estimated Recipients: {estimatedRecipients}
              </span>
            </div>

            {/* Approved Templates */}
            {templates.length > 0 && (
              <div className="form-group">
                <label className="form-label text-xs text-secondary font-bold uppercase mb-1">Load Approved Template</label>
                <div className="flex flex-wrap gap-2">
                  {templates.map((t) => (
                    <button
                      key={t.id}
                      type="button"
                      className="btn btn-xs btn-secondary"
                      onClick={() => handleSelectTemplate(t)}
                    >
                      <Hugeicon name="file" size={12} />
                      {t.name}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Title */}
            <div className="form-group">
              <label className="form-label">Notification Title</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. BizSquare Weekly Network Pulse"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                maxLength={100}
                required
              />
              <div className="flex justify-between text-xs text-tertiary mt-1">
                <span>Supports variables: {ALLOWED_VARIABLES.join(', ')}</span>
                <span>{title.length}/100</span>
              </div>
            </div>

            {/* Body */}
            <div className="form-group">
              <label className="form-label">Body Content</label>
              <textarea
                className="form-control"
                placeholder="Hi {{firstName}}, check out your new business connections and status updates this week!"
                value={body}
                onChange={(e) => setBody(e.target.value)}
                rows={4}
                required
              />
              <div className="text-xs text-tertiary mt-1">
                Variable validation enabled. Unknown variables will block send.
              </div>
            </div>

            {/* Category & Visual Variant */}
            <div className="grid-2 gap-4">
              <div className="form-group">
                <label className="form-label">Category</label>
                <select
                  className="form-control"
                  value={category}
                  onChange={(e) => setCategory(e.target.value as any)}
                >
                  <option value="ANNOUNCEMENT">ANNOUNCEMENT</option>
                  <option value="SPOTLIGHT">SPOTLIGHT</option>
                  <option value="CONTACT_GAIN">CONTACT_GAIN</option>
                  <option value="UPDATE">UPDATE</option>
                  <option value="IMPORTANT">IMPORTANT</option>
                  <option value="CELEBRATION">CELEBRATION</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Visual Variant</label>
                <select
                  className="form-control"
                  value={visualVariant}
                  onChange={(e) => setVisualVariant(e.target.value as any)}
                >
                  <option value="DEFAULT">DEFAULT (Standard)</option>
                  <option value="HIGHLIGHT">HIGHLIGHT (Brand Blue)</option>
                  <option value="ALERT">ALERT (Warning Red)</option>
                  <option value="SUCCESS">SUCCESS (Green Accent)</option>
                  <option value="GOLD">GOLD (Spotlight Feature)</option>
                </select>
              </div>
            </div>

            {/* Destination & Audience */}
            <div className="grid-2 gap-4">
              <div className="form-group">
                <label className="form-label">Approved Deep Link Destination</label>
                <select
                  className="form-control"
                  value={destination}
                  onChange={(e) => setDestination(e.target.value)}
                >
                  {APPROVED_DESTINATIONS.map((d) => (
                    <option key={d.value} value={d.value}>
                      {d.label} ({d.value})
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Target Audience</label>
                <select
                  className="form-control"
                  value={audienceType}
                  onChange={(e) => setAudienceType(e.target.value as any)}
                >
                  <option value="ALL">All Active Users</option>
                  <option value="NEW_USERS">New Users (Last 7 Days)</option>
                  <option value="INCOMPLETE_SETUP">Incomplete Setup Users</option>
                  <option value="SPOTLIGHT_USERS">Spotlight Participants</option>
                  <option value="CONTACT_GAIN_USERS">Contact Gain Users</option>
                  <option value="INDIVIDUAL">Individual User</option>
                </select>
              </div>
            </div>

            {/* Individual User Search if applicable */}
            {audienceType === 'INDIVIDUAL' && (
              <div className="form-group">
                <label className="form-label">Target User ID</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="Enter User UUID..."
                  value={individualUserId}
                  onChange={(e) => setIndividualUserId(e.target.value)}
                  required
                />
              </div>
            )}

            {/* Scheduling Toggle */}
            <div
              style={{
                background: 'var(--bg-elevated)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-sm)',
                padding: '0.75rem',
              }}
              className="flex flex-col gap-2"
            >
              <label className="flex items-center gap-2 cursor-pointer font-bold text-sm">
                <input
                  type="checkbox"
                  checked={isScheduled}
                  onChange={(e) => setIsScheduled(e.target.checked)}
                />
                Schedule Broadcast for Future Delivery
              </label>

              {isScheduled && (
                <div className="form-group mt-2">
                  <label className="form-label text-xs">Scheduled Date & Time</label>
                  <input
                    type="datetime-local"
                    className="form-control"
                    value={scheduledAt}
                    onChange={(e) => setScheduledAt(e.target.value)}
                    required={isScheduled}
                  />
                </div>
              )}
            </div>

            {validationError && (
              <div className="alert alert-error">
                <Hugeicon name="error" state="error" size={16} />
                <span>{validationError}</span>
              </div>
            )}

            {canSend && (
              <button type="submit" className="btn btn-primary mt-2">
                <Hugeicon name="send" size={14} />
                {isScheduled ? 'Review & Schedule Broadcast' : 'Review & Send Broadcast'}
              </button>
            )}
          </form>

          {/* Real-time Device Preview Side */}
          <div className="flex flex-col gap-4">
            <div className="card">
              <div className="card-header">
                <span className="card-title">
                  <Hugeicon name="mobile" size={16} state="active" />
                  Live Mobile Notification Preview
                </span>
                <span className="badge badge-gray text-xs">PREVIEW</span>
              </div>
              <div className="card-body flex justify-center p-6" style={{ background: '#0a0d14' }}>
                {/* Mobile Notification Card Mockup */}
                <div
                  style={{
                    width: '100%',
                    maxWidth: 340,
                    background: 'rgba(22, 27, 38, 0.95)',
                    border: '1px solid rgba(255, 255, 255, 0.12)',
                    borderRadius: 16,
                    padding: 14,
                    boxShadow: '0 12px 32px rgba(0,0,0,0.6)',
                  }}
                  className="flex flex-col gap-2"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div
                        style={{
                          width: 22,
                          height: 22,
                          borderRadius: 6,
                          background: 'linear-gradient(135deg, var(--brand-pink), var(--brand-blue))',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          color: '#fff',
                          fontWeight: 800,
                          fontSize: 10,
                        }}
                      >
                        B
                      </div>
                      <span className="text-xs font-bold text-primary">BIZSQUARE</span>
                    </div>

                    <span className="text-xs text-tertiary">now</span>
                  </div>

                  <div>
                    <div className="font-bold text-sm text-primary mb-0.5">
                      {title ? renderPreviewText(title) : 'Notification Title Preview'}
                    </div>
                    <p className="text-xs text-secondary line-clamp-3">
                      {body ? renderPreviewText(body) : 'Your notification content will be rendered here with live personalized variables.'}
                    </p>
                  </div>

                  <div className="flex justify-between items-center pt-2 mt-1" style={{ borderTop: '1px solid rgba(255,255,255,0.08)' }}>
                    <span className="badge badge-blue text-xs">{category}</span>
                    <span className="text-xs text-tertiary font-mono">{destination}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* SECTION 2: SCHEDULED */}
      {activeTab === 'scheduled' && (
        <div className="card fade-up">
          <div className="card-header flex justify-between items-center">
            <span className="card-title">
              <Hugeicon name="schedule" size={16} state="active" />
              Pending Scheduled Broadcasts
              <span className="badge badge-yellow">{scheduled.length}</span>
            </span>
          </div>

          {scheduled.length === 0 ? (
            <GlobalEmptyState
              icon="schedule"
              title="No Scheduled Notifications"
              description="There are currently no broadcast notifications pending delivery in the scheduled queue."
            />
          ) : (
            <div className="table-wrap">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Title</th>
                    <th>Category</th>
                    <th>Audience</th>
                    <th>Destination</th>
                    <th>Scheduled For</th>
                    <th>Created By</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {scheduled.map((item) => (
                    <tr key={item.id}>
                      <td className="font-bold text-sm">{item.title}</td>
                      <td>
                        <span className="badge badge-blue">{item.category}</span>
                      </td>
                      <td className="text-xs text-secondary">{item.audience_type}</td>
                      <td className="font-mono text-xs text-tertiary">{item.action_url}</td>
                      <td className="text-xs text-primary font-bold">
                        {new Date(item.scheduled_at).toLocaleString('en-GB')}
                      </td>
                      <td className="text-xs text-secondary">{item.created_by_name || 'System Admin'}</td>
                      <td>
                        <button
                          type="button"
                          className="btn btn-xs btn-danger"
                          onClick={() => handleCancelScheduled(item)}
                        >
                          Cancel
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* SECTION 3: SENT HISTORY */}
      {activeTab === 'sent' && (
        <div className="card fade-up">
          <div className="card-header flex justify-between items-center">
            <span className="card-title">
              <Hugeicon name="audit" size={16} state="active" />
              Sent Broadcast History
            </span>
          </div>

          {sent.length === 0 ? (
            <GlobalEmptyState
              icon="audit"
              title="No Sent Broadcast History"
              description="No broadcast notifications have been processed yet."
            />
          ) : (
            <div className="table-wrap">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Title</th>
                    <th>Category</th>
                    <th>Audience</th>
                    <th>Recipients</th>
                    <th>Opened</th>
                    <th>Destination</th>
                    <th>Sent At</th>
                  </tr>
                </thead>
                <tbody>
                  {sent.map((item) => (
                    <tr key={item.id}>
                      <td className="font-bold text-sm">{item.title}</td>
                      <td>
                        <span className="badge badge-green">{item.category}</span>
                      </td>
                      <td className="text-xs text-secondary">{item.audience_type}</td>
                      <td className="font-mono text-sm font-bold">{item.recipient_count}</td>
                      <td className="font-mono text-sm" style={{ color: 'var(--brand-blue)' }}>
                        {item.opened_count}
                      </td>
                      <td className="font-mono text-xs text-tertiary">{item.action_url}</td>
                      <td className="text-xs text-tertiary">
                        {new Date(item.created_at).toLocaleString('en-GB', {
                          day: 'numeric',
                          month: 'short',
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
