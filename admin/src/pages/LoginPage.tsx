import React, { useState } from 'react';
import { useAdminAuth } from '../context/AdminAuthContext';
import { Hugeicon } from '../components/common/Hugeicon';

export const LoginPage: React.FC = () => {
  const { login, isLoading, error } = useAdminAuth();
  const [phoneNumber, setPhoneNumber] = useState('');
  const [accessCode, setAccessCode] = useState('');
  const [showCode, setShowCode] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLocalError(null);

    if (!phoneNumber.trim()) {
      setLocalError('Please enter your admin phone number.');
      return;
    }

    try {
      await login(phoneNumber.trim(), accessCode.trim());
    } catch (err: any) {
      setLocalError(err.message || 'Administrative authentication failed.');
    }
  };

  const displayError = localError || error;

  return (
    <div className="login-page">
      <div className="login-card">
        {/* Brand Header */}
        <div className="login-logo">
          <div className="login-logo-icon">
            <img src="/logo.png" alt="BizSquare Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          </div>
          <div>
            <div className="login-logo-text">BizSquare</div>
            <div className="text-xs text-tertiary font-bold" style={{ letterSpacing: '0.06em', textTransform: 'uppercase' }}>
              Akawo Platform · Admin
            </div>
          </div>
        </div>

        <h1 className="login-title">Admin SignIn</h1>
        <p className="login-subtitle">
          Enter your authorized administrative phone number to access the control panel.
        </p>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div className="form-group">
            <label className="form-label">Phone Number</label>
            <input
              type="text"
              className="form-control font-mono"
              placeholder="+2348012345678"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              required
              autoFocus
              disabled={isLoading}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Access Code / Password (Optional)</label>
            <div style={{ position: 'relative' }}>
              <input
                type={showCode ? 'text' : 'password'}
                className="form-control"
                placeholder="Enter admin access code"
                value={accessCode}
                onChange={(e) => setAccessCode(e.target.value)}
                disabled={isLoading}
                style={{ paddingRight: '2.5rem' }}
              />
              <button
                type="button"
                onClick={() => setShowCode((v) => !v)}
                style={{
                  position: 'absolute',
                  right: '0.75rem',
                  top: '50%',
                  transform: 'translateY(-50%)',
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  padding: 0,
                }}
              >
                <Hugeicon name={showCode ? 'close' : 'userProfile'} size={15} variant="muted" />
              </button>
            </div>
          </div>

          {displayError && (
            <div className="alert alert-error">
              <Hugeicon name="error" state="error" size={16} />
              <span>{displayError}</span>
            </div>
          )}

          <button type="submit" className="btn btn-primary" disabled={isLoading} style={{ marginTop: '0.5rem' }}>
            {isLoading ? (
              <>
                <Hugeicon name="refresh" className="animate-spin" size={16} />
                Authenticating…
              </>
            ) : (
              <>
                <Hugeicon name="lock" size={16} />
                Sign In to Admin Shell
              </>
            )}
          </button>
        </form>

        <div
          style={{
            marginTop: '1.5rem',
            padding: '0.75rem',
            borderRadius: 'var(--radius-sm)',
            background: 'var(--bg-elevated)',
            fontSize: '0.75rem',
            color: 'var(--text-tertiary)',
            textAlign: 'center',
          }}
        >
          🔒 Restricted access area. Every administrative sign-in is audited.
        </div>
      </div>
    </div>
  );
};
