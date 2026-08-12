import React from 'react';
import { GlobalErrorState } from '../components/common/GlobalErrorState';
import { useAdminAuth } from '../context/AdminAuthContext';

interface AccessDeniedPageProps {
  requiredPermission?: string;
  onGoHome?: () => void;
}

export const AccessDeniedPage: React.FC<AccessDeniedPageProps> = ({
  requiredPermission,
  onGoHome,
}) => {
  const { logout, adminUser } = useAdminAuth();

  return (
    <GlobalErrorState
      type="authorization"
      title="Access Denied (403)"
      message={
        requiredPermission
          ? `Your account (${adminUser?.full_name || 'Admin'}) lacks the required '${requiredPermission}' permission.`
          : 'You do not have administrative privileges to access this area of BizSquare.'
      }
      actionLabel="Sign In as Different User"
      onAction={logout}
      onRetry={onGoHome}
    />
  );
};
