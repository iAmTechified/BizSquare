import React, { useState } from 'react';
import { adminAuthApi } from '../../api/adminAuthApi';
import { Hugeicon } from '../common/Hugeicon';
import { useToast } from '../../context/ToastContext';

interface GenerateSetupCodeModalProps {
  onClose: () => void;
  onSuccess: () => void;
}

export const GenerateSetupCodeModal: React.FC<GenerateSetupCodeModalProps> = ({
  onClose,
  onSuccess,
}) => {
  const { showToast } = useToast();
  const [quantity, setQuantity] = useState<number>(1);
  const [expiresInDays, setExpiresInDays] = useState<number>(30);
  const [intendedUserId, setIntendedUserId] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Success state holding generated codes for instant copying
  const [generatedCodes, setGeneratedCodes] = useState<Array<{ id: string; code: string; expires_at: string }> | null>(null);
  const [copiedIndex, setCopiedIndex] = useState<number | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const res = await adminAuthApi.generateSetupCodes({
        quantity,
        expires_in_days: expiresInDays,
        intended_user_id: intendedUserId.trim() || undefined,
      });

      showToast({
        type: 'success',
        title: 'Setup Codes Generated',
        message: res.message || `Generated ${res.codes.length} setup code(s).`,
      });

      setGeneratedCodes(res.codes);
      onSuccess();
    } catch (err: any) {
      console.error('Setup code generation error:', err);
      setError(err.message || 'Failed to generate setup codes server-side.');
    } finally {
      setLoading(false);
    }
  };

  const handleCopyCode = (codeStr: string, idx: number) => {
    navigator.clipboard.writeText(codeStr);
    setCopiedIndex(idx);
    showToast({ type: 'info', title: 'Code Copied', message: `Copied ${codeStr} to clipboard.` });
    setTimeout(() => setCopiedIndex(null), 2000);
  };

  const handleCopyAll = () => {
    if (!generatedCodes) return;
    const allCodesStr = generatedCodes.map((c) => c.code).join('\n');
    navigator.clipboard.writeText(allCodesStr);
    showToast({ type: 'info', title: 'All Codes Copied', message: `Copied ${generatedCodes.length} setup codes.` });
  };

  return (
    <div className="modal-backdrop" onClick={onClose} role="dialog" aria-modal="true">
      <div className="modal fade-up" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 500 }}>
        <div className="modal-header">
          <span className="modal-title flex items-center gap-2">
            <Hugeicon name="lock" size={18} state="active" />
            {generatedCodes ? 'Setup Codes Generated' : 'Generate Setup Code'}
          </span>
          <button type="button" className="modal-close" onClick={onClose} aria-label="Close dialog">
            <Hugeicon name="close" size={14} />
          </button>
        </div>

        {/* SUCCESS REVEAL VIEW */}
        {generatedCodes ? (
          <div className="modal-body flex flex-col gap-4">
            <div className="alert alert-success">
              <Hugeicon name="check" state="success" size={16} />
              <span>
                Successfully generated {generatedCodes.length} cryptographically secure setup code{generatedCodes.length > 1 ? 's' : ''}.
              </span>
            </div>

            <div className="flex flex-col gap-2 max-h-60 overflow-y-auto">
              {generatedCodes.map((c, i) => (
                <div
                  key={c.id || i}
                  style={{
                    background: 'var(--bg-elevated)',
                    border: '1px solid var(--brand-blue)',
                    borderRadius: 'var(--radius-md)',
                    padding: '0.85rem 1rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                  }}
                >
                  <div>
                    <span
                      style={{
                        fontFamily: 'monospace',
                        fontSize: '1.25rem',
                        fontWeight: 800,
                        letterSpacing: '1px',
                        color: 'var(--brand-blue)',
                      }}
                    >
                      {c.code}
                    </span>
                    <div className="text-xs text-tertiary">
                      Expires: {new Date(c.expires_at).toLocaleDateString('en-GB')}
                    </div>
                  </div>

                  <button
                    type="button"
                    className="btn btn-sm btn-secondary"
                    onClick={() => handleCopyCode(c.code, i)}
                  >
                    <Hugeicon name="audit" size={12} />
                    {copiedIndex === i ? 'Copied!' : 'Copy'}
                  </button>
                </div>
              ))}
            </div>

            <div className="text-xs text-tertiary">
              Share these setup codes with user(s) to allow profile creation during mobile onboarding.
            </div>

            <div className="modal-footer">
              {generatedCodes.length > 1 && (
                <button type="button" className="btn btn-secondary" onClick={handleCopyAll}>
                  Copy All Codes
                </button>
              )}
              <button type="button" className="btn btn-primary" onClick={onClose}>
                Done
              </button>
            </div>
          </div>
        ) : (
          /* FORM VIEW */
          <form onSubmit={handleSubmit}>
            <div className="modal-body flex flex-col gap-4">
              {/* Quantity */}
              <div className="form-group">
                <label className="form-label">Quantity of Codes to Generate</label>
                <select
                  className="form-control font-bold"
                  value={quantity}
                  onChange={(e) => setQuantity(parseInt(e.target.value, 10))}
                  disabled={loading}
                >
                  <option value={1}>1 Code</option>
                  <option value={5}>5 Codes (Bulk)</option>
                  <option value={10}>10 Codes (Bulk)</option>
                  <option value={20}>20 Codes (Batch)</option>
                  <option value={50}>50 Codes (Max Batch)</option>
                </select>
                <span className="text-xs text-tertiary">
                  Server cryptographically generates non-predictable setup codes.
                </span>
              </div>

              {/* Expiration Duration */}
              <div className="form-group">
                <label className="form-label">Expiration Duration</label>
                <select
                  className="form-control"
                  value={expiresInDays}
                  onChange={(e) => setExpiresInDays(parseInt(e.target.value, 10))}
                  disabled={loading}
                >
                  <option value={7}>7 Days</option>
                  <option value={14}>14 Days</option>
                  <option value={30}>30 Days (Recommended Standard)</option>
                  <option value={90}>90 Days</option>
                  <option value={365}>365 Days (1 Year)</option>
                </select>
              </div>

              {/* Optional Intended User ID */}
              <div className="form-group">
                <label className="form-label">Optional Intended User UUID</label>
                <input
                  type="text"
                  className="form-control font-mono"
                  placeholder="e.g. 550e8400-e29b-41d4-a716-446655440000 (Leave blank for generic)"
                  value={intendedUserId}
                  onChange={(e) => setIntendedUserId(e.target.value)}
                  disabled={loading}
                />
                <span className="text-xs text-tertiary">
                  If set, only this specific user account can consume the setup code.
                </span>
              </div>

              {error && (
                <div className="alert alert-error">
                  <Hugeicon name="error" state="error" size={16} />
                  <span>{error}</span>
                </div>
              )}
            </div>

            <div className="modal-footer">
              <button type="button" className="btn btn-secondary" onClick={onClose} disabled={loading}>
                Cancel
              </button>
              <button type="submit" className="btn btn-primary" disabled={loading}>
                {loading ? (
                  <>
                    <Hugeicon name="refresh" className="animate-spin" size={14} />
                    Generating Server-Side…
                  </>
                ) : (
                  `Generate ${quantity} Code${quantity > 1 ? 's' : ''}`
                )}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};
