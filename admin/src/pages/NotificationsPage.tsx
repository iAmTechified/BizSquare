import React, { useState, useEffect } from 'react';
import { Hugeicon } from '../components/common/Hugeicon';
import { NotificationAdminApi } from '../api/notificationAdminApi';
import type { AdminNotificationPayload, NotificationHistoryItem } from '../api/notificationAdminApi';
import { useToast } from '../context/ToastContext';

type TabType = 'compose' | 'scheduled' | 'sent' | 'history';
type DevicePreviewType = 'ios' | 'android';

const APPROVED_DEEP_LINKS = [
  { label: 'Home Dashboard', value: 'bizsquare://home' },
  { label: 'All Contacts', value: 'bizsquare://contacts' },
  { label: 'Square Contacts', value: 'bizsquare://contacts/square' },
  { label: 'Spotlight Feature', value: 'bizsquare://spotlight' },
  { label: 'Spotlight Turn Submission', value: 'bizsquare://spotlight/turn' },
  { label: 'Spotlight History', value: 'bizsquare://spotlight/history' },
  { label: 'Permission Settings', value: 'bizsquare://settings/permissions' },
  { label: 'User Profile', value: 'bizsquare://profile' },
];

export const NotificationsPage: React.FC = () => {
  const { showToast } = useToast();
  const [activeTab, setActiveTab] = useState<TabType>('compose');
  const [devicePreview, setDevicePreview] = useState<DevicePreviewType>('ios');

  // Form State
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [category, setCategory] = useState<'CONTACT_GAIN' | 'SPOTLIGHT' | 'DAILY_PULSE' | 'SYSTEM'>('SYSTEM');
  const [visualVariant, setVisualVariant] = useState<'ANNOUNCEMENT' | 'SPOTLIGHT' | 'CONTACT_GAIN' | 'UPDATE' | 'IMPORTANT' | 'CELEBRATION'>('ANNOUNCEMENT');
  const [soundVariant, setSoundVariant] = useState<'DEFAULT' | 'URGENT' | 'CHIME' | 'SPOTLIGHT_TURN'>('DEFAULT');
  const [ctaText, setCtaText] = useState('Open App');
  const [deepLink, setDeepLink] = useState('bizsquare://home');
  const [audience, setAudience] = useState('all');
  const [targetUserId, setTargetUserId] = useState('');
  const [scheduledAt, setScheduledAt] = useState('');
  const [expiresInHours, setExpiresInHours] = useState(72);

  // Recipient Counter State
  const [estimatedRecipients, setEstimatedRecipients] = useState<number>(0);
  const [isCounting, setIsCounting] = useState(false);

  // Confirmation Modal State
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [broadcastConfirmed, setBroadcastConfirmed] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // History State
  const [historyItems, setHistoryItems] = useState<NotificationHistoryItem[]>([]);
  const [metrics, setMetrics] = useState({ totalSent: 0, totalDelivered: 0, totalOpened: 0, totalActioned: 0 });
  const [isLoadingHistory, setIsLoadingHistory] = useState(false);

  // Fetch estimated recipient count on audience change
  useEffect(() => {
    let isMounted = true;
    const fetchCount = async () => {
      setIsCounting(true);
      try {
        const count = await NotificationAdminApi.getRecipientCount(audience, targetUserId);
        if (isMounted) setEstimatedRecipients(count);
      } catch (_) {
        if (isMounted) setEstimatedRecipients(0);
      } finally {
        if (isMounted) setIsCounting(false);
      }
    };
    fetchCount();
    return () => { isMounted = false; };
  }, [audience, targetUserId]);

  // Load history data
  const loadHistory = async () => {
    setIsLoadingHistory(true);
    try {
      const data = await NotificationAdminApi.getNotificationHistory();
      setHistoryItems(data.history || []);
      setMetrics(data.metrics || { totalSent: 0, totalDelivered: 0, totalOpened: 0, totalActioned: 0 });
    } catch (_) {
      showToast({ title: 'Failed to load notification history', type: 'error' });
    } finally {
      setIsLoadingHistory(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'history' || activeTab === 'sent' || activeTab === 'scheduled') {
      loadHistory();
    }
  }, [activeTab]);

  // Handle Send Confirmation
  const handleOpenConfirm = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) {
      showToast({ title: 'Please enter a notification title and body.', type: 'warning' });
      return;
    }
    setShowConfirmModal(true);
  };

  const handleConfirmSend = async () => {
    setIsSubmitting(true);
    try {
      const payload: AdminNotificationPayload = {
        title: title.trim(),
        body: body.trim(),
        category,
        visualVariant,
        soundVariant,
        ctaText,
        deepLink,
        audience,
        targetUserId: audience === 'individual' ? targetUserId : undefined,
        scheduledAt: scheduledAt || undefined,
        expiresInHours,
      };

      const res = await NotificationAdminApi.sendNotification(payload);
      showToast({ title: res.message, type: 'success' });
      setShowConfirmModal(false);
      setTitle('');
      setBody('');
      setActiveTab('sent');
    } catch (err: any) {
      showToast({ title: err.message || 'Failed to dispatch notification', type: 'error' });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCancelScheduled = async (id: string) => {
    try {
      const success = await NotificationAdminApi.cancelScheduledNotification(id);
      if (success) {
        showToast({ title: 'Scheduled notification cancelled', type: 'success' });
        loadHistory();
      }
    } catch (_) {
      showToast({ title: 'Failed to cancel scheduled notification', type: 'error' });
    }
  };

  // Sample data preview replacement for personalization
  const renderPreviewText = (text: string) => {
    return text
      .replace(/\{\{firstName\}\}/g, 'Ade')
      .replace(/\{\{newContactCount\}\}/g, '8')
      .replace(/\{\{spotlightDate\}\}/g, 'Sunday')
      .replace(/\{\{contactCount\}\}/g, '24');
  };

  const filteredHistory = historyItems.filter((item) => {
    if (activeTab === 'scheduled') return item.status === 'PENDING';
    if (activeTab === 'sent') return item.status === 'SENT';
    return true;
  });

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
            <Hugeicon name="notifications" size={26} />
            Notification Composer
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Create, personalize, schedule, and broadcast notifications directly to production users.
          </p>
        </div>

        {/* Tab Switcher */}
        <div className="flex bg-slate-100 dark:bg-slate-800/80 p-1 rounded-xl border border-slate-200 dark:border-slate-700/60">
          {(['compose', 'scheduled', 'sent', 'history'] as TabType[]).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 text-xs font-semibold rounded-lg capitalize transition-all ${
                activeTab === tab
                  ? 'bg-white dark:bg-slate-700 text-indigo-600 dark:text-indigo-400 shadow-sm'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      {/* Metrics Header */}
      {(activeTab === 'history' || activeTab === 'sent') && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="p-4 rounded-xl bg-white dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700/60">
            <span className="text-xs text-slate-500 dark:text-slate-400">Total Sent</span>
            <div className="text-2xl font-black text-slate-900 dark:text-white">{metrics.totalSent}</div>
          </div>
          <div className="p-4 rounded-xl bg-white dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700/60">
            <span className="text-xs text-slate-500 dark:text-slate-400">Delivered</span>
            <div className="text-2xl font-black text-emerald-600 dark:text-emerald-400">{metrics.totalDelivered}</div>
          </div>
          <div className="p-4 rounded-xl bg-white dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700/60">
            <span className="text-xs text-slate-500 dark:text-slate-400">Opened</span>
            <div className="text-2xl font-black text-indigo-600 dark:text-indigo-400">{metrics.totalOpened}</div>
          </div>
          <div className="p-4 rounded-xl bg-white dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700/60">
            <span className="text-xs text-slate-500 dark:text-slate-400">Actioned</span>
            <div className="text-2xl font-black text-violet-600 dark:text-violet-400">{metrics.totalActioned}</div>
          </div>
        </div>
      )}

      {/* Main Content Area */}
      {activeTab === 'compose' ? (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
          {/* Left Form: 7 cols */}
          <form onSubmit={handleOpenConfirm} className="lg:col-span-7 space-y-6 bg-white dark:bg-slate-800/60 p-6 rounded-2xl border border-slate-200 dark:border-slate-700/60">
            <h2 className="text-lg font-bold text-slate-900 dark:text-white border-b pb-3 border-slate-100 dark:border-slate-700/40">
              Notification Details
            </h2>

            {/* Audience */}
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
                Audience Segment
              </label>
              <select
                value={audience}
                onChange={(e) => setAudience(e.target.value)}
                className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="all">All Active Users</option>
                <option value="new">New Users (Last 7 Days)</option>
                <option value="active">Active Users (Last 14 Days)</option>
                <option value="inactive">Inactive Users</option>
                <option value="spotlight">Spotlight Turn Users</option>
                <option value="contact_gain">Contact Gain Users</option>
                <option value="incomplete_setup">Incomplete Setup Users</option>
                <option value="individual">Individual User ID</option>
              </select>
            </div>

            {audience === 'individual' && (
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                  Recipient User ID
                </label>
                <input
                  type="text"
                  placeholder="e.g. 550e8400-e29b-41d4-a716-446655440000"
                  value={targetUserId}
                  onChange={(e) => setTargetUserId(e.target.value)}
                  className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            )}

            {/* Estimated Recipient Badge */}
            <div className="flex items-center gap-2 p-3 bg-indigo-50 dark:bg-indigo-950/30 rounded-xl border border-indigo-200 dark:border-indigo-800/40 text-xs text-indigo-700 dark:text-indigo-300">
              <Hugeicon name="users" size={16} />
              <span>
                Estimated Target Audience:{' '}
                <strong>{isCounting ? 'Calculating...' : `${estimatedRecipients} real user(s)`}</strong>
              </span>
            </div>

            {/* Title */}
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                Notification Title
              </label>
              <input
                type="text"
                placeholder="e.g. Hello {{firstName}}, your new contacts are ready!"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                required
              />
            </div>

            {/* Body */}
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                Notification Body
              </label>
              <textarea
                rows={3}
                placeholder="e.g. You have {{newContactCount}} new verified contacts waiting in your Square network."
                value={body}
                onChange={(e) => setBody(e.target.value)}
                className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                required
              />
              <p className="text-[11px] text-slate-400 mt-1">
                Supported variables: <code>{'{{firstName}}'}</code>, <code>{'{{newContactCount}}'}</code>, <code>{'{{spotlightDate}}'}</code>, <code>{'{{contactCount}}'}</code>.
              </p>
            </div>

            {/* Category & Visual Variant */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                  Category
                </label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value as any)}
                  className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="SYSTEM">SYSTEM (Non-disableable)</option>
                  <option value="CONTACT_GAIN">CONTACT_GAIN</option>
                  <option value="SPOTLIGHT">SPOTLIGHT</option>
                  <option value="DAILY_PULSE">DAILY_PULSE</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                  Visual Variant (Section 7)
                </label>
                <select
                  value={visualVariant}
                  onChange={(e) => setVisualVariant(e.target.value as any)}
                  className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="ANNOUNCEMENT">ANNOUNCEMENT</option>
                  <option value="SPOTLIGHT">SPOTLIGHT</option>
                  <option value="CONTACT_GAIN">CONTACT_GAIN</option>
                  <option value="UPDATE">UPDATE</option>
                  <option value="IMPORTANT">IMPORTANT</option>
                  <option value="CELEBRATION">CELEBRATION</option>
                </select>
              </div>
            </div>

            {/* Sound Variant & Deep Link */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                  Sound Mapping
                </label>
                <select
                  value={soundVariant}
                  onChange={(e) => setSoundVariant(e.target.value as any)}
                  className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="DEFAULT">DEFAULT (General chime)</option>
                  <option value="URGENT">URGENT (Action alert)</option>
                  <option value="CHIME">CHIME (Success tone)</option>
                  <option value="SPOTLIGHT_TURN">SPOTLIGHT_TURN (Spotlight Ring)</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                  Approved Deep Link (Section 5)
                </label>
                <select
                  value={deepLink}
                  onChange={(e) => setDeepLink(e.target.value)}
                  className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  {APPROVED_DEEP_LINKS.map((link) => (
                    <option key={link.value} value={link.value}>
                      {link.label} ({link.value})
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {/* CTA & Schedule */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                  Button CTA Text
                </label>
                <input
                  type="text"
                  value={ctaText}
                  onChange={(e) => setCtaText(e.target.value)}
                  placeholder="e.g. Open Spotlight"
                  className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                  Schedule Send (Optional)
                </label>
                <input
                  type="datetime-local"
                  value={scheduledAt}
                  onChange={(e) => setScheduledAt(e.target.value)}
                  className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>

            {/* Expiration */}
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                Expiration (Hours)
              </label>
              <input
                type="number"
                value={expiresInHours}
                onChange={(e) => setExpiresInHours(parseInt(e.target.value, 10) || 72)}
                className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <button
              type="submit"
              className="w-full py-3 px-4 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl text-sm transition-all shadow-lg shadow-indigo-600/20 flex items-center justify-center gap-2"
            >
              <Hugeicon name="spotlight" size={18} />
              Review & Broadcast Notification
            </button>
          </form>

          {/* Right Live Device Preview: 5 cols (Section 6) */}
          <div className="lg:col-span-5 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-slate-900 dark:text-white uppercase tracking-wider">
                Live Device Preview
              </h3>
              <div className="flex bg-slate-100 dark:bg-slate-800 p-1 rounded-lg border border-slate-200 dark:border-slate-700">
                <button
                  onClick={() => setDevicePreview('ios')}
                  className={`px-3 py-1 text-xs font-bold rounded-md transition-all ${
                    devicePreview === 'ios' ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-xs' : 'text-slate-500'
                  }`}
                >
                  iOS
                </button>
                <button
                  onClick={() => setDevicePreview('android')}
                  className={`px-3 py-1 text-xs font-bold rounded-md transition-all ${
                    devicePreview === 'android' ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-xs' : 'text-slate-500'
                  }`}
                >
                  Android
                </button>
              </div>
            </div>

            {/* Device Mock Card */}
            <div className="p-6 bg-slate-900 rounded-3xl border border-slate-800 shadow-2xl space-y-4">
              <div className="flex justify-between items-center text-[10px] text-slate-400 font-mono">
                <span>{devicePreview.toUpperCase()} Lock Screen</span>
                <span>BizSquare Push</span>
              </div>

              {/* Push Card */}
              <div className="p-4 rounded-2xl bg-slate-800/90 border border-slate-700/80 shadow-xl space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-6 h-6 rounded-md bg-indigo-600 flex items-center justify-center text-white font-bold text-[10px]">
                      BS
                    </div>
                    <span className="text-xs font-bold text-white">BizSquare</span>
                  </div>
                  <span className="text-[10px] text-slate-400">now</span>
                </div>

                <div className="space-y-1">
                  <h4 className="text-sm font-bold text-white leading-tight">
                    {renderPreviewText(title || 'Notification Title Preview')}
                  </h4>
                  <p className="text-xs text-slate-300 leading-normal">
                    {renderPreviewText(body || 'Notification body content preview with personalization variable substitution.')}
                  </p>
                </div>

                {/* Variant & Sound Badges */}
                <div className="flex flex-wrap gap-2 pt-2 border-t border-slate-700/60">
                  <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-indigo-500/20 text-indigo-300 border border-indigo-500/30">
                    {visualVariant}
                  </span>
                  <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                    🔊 {soundVariant}
                  </span>
                </div>

                {/* Action CTA */}
                <div className="pt-1">
                  <div className="w-full py-1.5 bg-indigo-600/80 hover:bg-indigo-600 text-white font-bold text-xs rounded-xl text-center">
                    {ctaText || 'Open App'}
                  </div>
                </div>
              </div>

              <div className="text-[11px] text-slate-400 space-y-1 pt-2">
                <div>Deep Link: <code className="text-indigo-400">{deepLink}</code></div>
                <div>Category: <code className="text-indigo-400">{category}</code></div>
              </div>
            </div>
          </div>
        </div>
      ) : (
        /* History / Scheduled / Sent Table */
        <div className="bg-white dark:bg-slate-800/60 rounded-2xl border border-slate-200 dark:border-slate-700/60 overflow-hidden shadow-xs">
          <div className="p-4 border-b border-slate-100 dark:border-slate-700/40 flex justify-between items-center">
            <h3 className="text-sm font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              {activeTab} Notifications ({filteredHistory.length})
            </h3>
            <button
              onClick={loadHistory}
              className="px-3 py-1.5 text-xs font-semibold bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 rounded-lg hover:bg-slate-200 transition-all"
            >
              Refresh
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900/50 text-slate-500 dark:text-slate-400 font-bold uppercase tracking-wider">
                  <th className="p-3">Recipient</th>
                  <th className="p-3">Title & Body</th>
                  <th className="p-3">Category</th>
                  <th className="p-3">Status</th>
                  <th className="p-3">Created</th>
                  {activeTab === 'scheduled' && <th className="p-3">Action</th>}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-700/40">
                {isLoadingHistory ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center text-slate-500">
                      Loading notification history...
                    </td>
                  </tr>
                ) : filteredHistory.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center text-slate-500">
                      No notifications found for this view.
                    </td>
                  </tr>
                ) : (
                  filteredHistory.map((item) => (
                    <tr key={item.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-700/30">
                      <td className="p-3 font-semibold text-slate-900 dark:text-white">
                        {item.recipientName}
                        <div className="text-[10px] text-slate-400 font-normal">{item.recipientBusiness}</div>
                      </td>
                      <td className="p-3">
                        <div className="font-bold text-slate-800 dark:text-slate-200">{item.title}</div>
                        <div className="text-slate-500 dark:text-slate-400 line-clamp-1">{item.body}</div>
                      </td>
                      <td className="p-3">
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-indigo-50 dark:bg-indigo-950 text-indigo-600 dark:text-indigo-400">
                          {item.category}
                        </span>
                      </td>
                      <td className="p-3">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                            item.status === 'SENT'
                              ? 'bg-emerald-50 text-emerald-600 dark:bg-emerald-950 dark:text-emerald-400'
                              : item.status === 'PENDING'
                              ? 'bg-amber-50 text-amber-600 dark:bg-amber-950 dark:text-amber-400'
                              : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400'
                          }`}
                        >
                          {item.status}
                        </span>
                      </td>
                      <td className="p-3 text-slate-500">
                        {new Date(item.createdAt).toLocaleString()}
                      </td>
                      {activeTab === 'scheduled' && (
                        <td className="p-3">
                          <button
                            onClick={() => handleCancelScheduled(item.id)}
                            className="px-2.5 py-1 bg-red-50 text-red-600 hover:bg-red-100 rounded-md text-[11px] font-bold"
                          >
                            Cancel
                          </button>
                        </td>
                      )}
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Send Safety Confirmation Modal (Section 8) */}
      {showConfirmModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-5">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white border-b pb-3 border-slate-100 dark:border-slate-700">
              Confirm Notification Broadcast
            </h3>

            <div className="space-y-3 text-xs">
              <div className="flex justify-between py-1.5 border-b border-slate-100 dark:border-slate-700">
                <span className="text-slate-500">Audience Segment:</span>
                <span className="font-bold text-slate-900 dark:text-white uppercase">{audience}</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-slate-100 dark:border-slate-700">
                <span className="text-slate-500">Estimated Recipients:</span>
                <span className="font-bold text-indigo-600 dark:text-indigo-400">{estimatedRecipients} real users</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-slate-100 dark:border-slate-700">
                <span className="text-slate-500">Title:</span>
                <span className="font-bold text-slate-900 dark:text-white">{title}</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-slate-100 dark:border-slate-700">
                <span className="text-slate-500">Deep Link:</span>
                <span className="font-bold text-indigo-600 dark:text-indigo-400">{deepLink}</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-slate-100 dark:border-slate-700">
                <span className="text-slate-500">Visual & Sound:</span>
                <span className="font-bold text-slate-900 dark:text-white">{visualVariant} · {soundVariant}</span>
              </div>
            </div>

            {/* Broadcast Confirmation Checkbox for large broadcasts */}
            {estimatedRecipients > 100 && (
              <div className="p-3 bg-amber-50 dark:bg-amber-950/40 rounded-xl border border-amber-200 dark:border-amber-800/40 flex items-start gap-2">
                <input
                  type="checkbox"
                  id="broadcastCheck"
                  checked={broadcastConfirmed}
                  onChange={(e) => setBroadcastConfirmed(e.target.checked)}
                  className="mt-0.5"
                />
                <label htmlFor="broadcastCheck" className="text-xs text-amber-800 dark:text-amber-300">
                  I confirm broadcasting this notification to {estimatedRecipients} users in production.
                </label>
              </div>
            )}

            <div className="flex gap-3 pt-2">
              <button
                type="button"
                onClick={() => setShowConfirmModal(false)}
                className="flex-1 py-2.5 bg-slate-100 hover:bg-slate-200 dark:bg-slate-700 dark:hover:bg-slate-600 text-slate-700 dark:text-slate-200 font-bold rounded-xl text-xs"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={isSubmitting || (estimatedRecipients > 100 && !broadcastConfirmed)}
                onClick={handleConfirmSend}
                className="flex-1 py-2.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white font-bold rounded-xl text-xs shadow-md"
              >
                {isSubmitting ? 'Sending...' : 'Confirm & Dispatch'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default NotificationsPage;
