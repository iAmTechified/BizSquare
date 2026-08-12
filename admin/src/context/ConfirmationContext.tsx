import React, { createContext, useContext, useState, useCallback } from 'react';
import { Hugeicon } from '../components/common/Hugeicon';
import { useToast } from './ToastContext';

export interface ConfirmationOptions {
  title: string;
  description: string;
  consequence?: string;
  confirmLabel?: string;
  cancelLabel?: string;
  isDestructive?: boolean;
  onConfirm: () => Promise<void> | void;
}

interface ConfirmationContextType {
  confirm: (options: ConfirmationOptions) => void;
}

const ConfirmationContext = createContext<ConfirmationContextType | undefined>(undefined);

export const ConfirmationProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { showToast } = useToast();
  const [options, setOptions] = useState<ConfirmationOptions | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);

  const confirm = useCallback((opts: ConfirmationOptions) => {
    setOptions(opts);
    setIsLoading(false);
  }, []);

  const handleClose = () => {
    if (isLoading) return;
    setOptions(null);
  };

  const handleConfirm = async () => {
    if (!options) return;
    setIsLoading(true);
    try {
      await options.onConfirm();
      showToast({
        type: 'success',
        title: 'Action Completed',
        message: `${options.title} executed successfully.`,
      });
      setOptions(null);
    } catch (err: any) {
      console.error('Confirmation action error:', err);
      showToast({
        type: 'error',
        title: 'Action Failed',
        message: err.message || 'Could not complete the requested action.',
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <ConfirmationContext.Provider value={{ confirm }}>
      {children}
      {options && (
        <div className="modal-backdrop" onClick={handleClose} role="dialog" aria-modal="true">
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 480 }}>
            <div className="modal-header">
              <span className="modal-title flex items-center gap-2">
                <Hugeicon
                  name={options.isDestructive ? 'warning' : 'info'}
                  state={options.isDestructive ? 'error' : 'warning'}
                  size={20}
                />
                {options.title}
              </span>
              <button
                className="modal-close"
                onClick={handleClose}
                disabled={isLoading}
                aria-label="Close dialog"
              >
                <Hugeicon name="close" size={14} />
              </button>
            </div>

            <div className="modal-body flex flex-col gap-3">
              <p style={{ fontSize: '0.875rem', color: 'var(--text-primary)', lineHeight: 1.5 }}>
                {options.description}
              </p>

              {options.consequence && (
                <div
                  className={`alert ${options.isDestructive ? 'alert-error' : 'alert-info'}`}
                  style={{ marginTop: 4 }}
                >
                  <Hugeicon
                    name={options.isDestructive ? 'warning' : 'info'}
                    size={16}
                    state={options.isDestructive ? 'error' : 'default'}
                  />
                  <div>
                    <strong>Consequence:</strong> {options.consequence}
                  </div>
                </div>
              )}
            </div>

            <div className="modal-footer">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={handleClose}
                disabled={isLoading}
              >
                {options.cancelLabel || 'Cancel'}
              </button>
              <button
                type="button"
                className={`btn ${options.isDestructive ? 'btn-danger' : 'btn-primary'}`}
                onClick={handleConfirm}
                disabled={isLoading}
              >
                {isLoading ? (
                  <>
                    <Hugeicon name="refresh" className="animate-spin" size={14} />
                    Processing…
                  </>
                ) : (
                  options.confirmLabel || 'Confirm Action'
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </ConfirmationContext.Provider>
  );
};

export const useConfirmation = (): ConfirmationContextType => {
  const context = useContext(ConfirmationContext);
  if (!context) {
    throw new Error('useConfirmation must be used within a ConfirmationProvider');
  }
  return context;
};
